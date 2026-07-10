#[cfg(not(unix))]
compile_error!("tab-actions requires Unix domain sockets");

use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use std::env;
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use std::process;
use std::time::{SystemTime, UNIX_EPOCH};

fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let direction = Direction::parse(env::args().nth(1).as_deref().unwrap_or("right"))?;
    let context = plugin_context()?;
    let socket_path = env_nonempty("HERDR_SOCKET_PATH")
        .ok_or_else(|| "HERDR_SOCKET_PATH is missing".to_string())?;
    let tab_id = env_nonempty("HERDR_TAB_ID")
        .or_else(|| context.tab_id.clone())
        .ok_or_else(|| "HERDR_TAB_ID is missing".to_string())?;
    let workspace_id = resolve_workspace_id(&socket_path, &tab_id, &context)?;

    let tabs = tab_list(&socket_path, &workspace_id)?;
    let current_index = tabs
        .iter()
        .position(|tab| tab.tab_id == tab_id)
        .ok_or_else(|| format!("current tab {tab_id} was not found in workspace {workspace_id}"))?;

    let target_index = current_index as isize + direction.offset();
    if target_index < 0 || target_index >= tabs.len() as isize {
        println!(
            "tab move skipped: already at the {} edge",
            direction.as_str()
        );
        return Ok(());
    }

    let target_index = target_index as usize;
    let moved_tabs = move_tab(
        &socket_path,
        &tab_id,
        request_insert_index(current_index, target_index),
    )?;
    let final_index = moved_tabs
        .iter()
        .position(|tab| tab.tab_id == tab_id)
        .ok_or_else(|| format!("tab.move finished without returning tab {tab_id}"))?;

    if final_index != target_index {
        return Err(format!(
            "tab.move finished at index {final_index}, expected {target_index}"
        ));
    }

    println!(
        "moved current tab {} to index {}",
        direction.as_str(),
        target_index
    );

    Ok(())
}

fn plugin_context() -> Result<PluginContext, String> {
    match env_nonempty("HERDR_PLUGIN_CONTEXT_JSON") {
        Some(raw) => serde_json::from_str(&raw)
            .map_err(|error| format!("failed to parse HERDR_PLUGIN_CONTEXT_JSON: {error}")),
        None => Ok(PluginContext::default()),
    }
}

fn env_nonempty(name: &str) -> Option<String> {
    match env::var(name) {
        Ok(value) if !value.is_empty() => Some(value),
        _ => None,
    }
}

fn resolve_workspace_id(
    socket_path: &str,
    tab_id: &str,
    context: &PluginContext,
) -> Result<String, String> {
    if let Some(workspace_id) = env_nonempty("HERDR_WORKSPACE_ID") {
        return Ok(workspace_id);
    }

    if let Some(workspace_id) = context.workspace_id.clone() {
        return Ok(workspace_id);
    }

    let result: TabGetResult = call_socket(
        socket_path,
        "tab.get",
        &TabTarget {
            tab_id: tab_id.to_string(),
        },
    )?;
    result
        .tab
        .workspace_id
        .ok_or_else(|| format!("workspace_id could not be resolved for tab {tab_id}"))
}

fn tab_list(socket_path: &str, workspace_id: &str) -> Result<Vec<TabInfo>, String> {
    let result: TabListResult = call_socket(
        socket_path,
        "tab.list",
        &TabListParams {
            workspace_id: Some(workspace_id.to_string()),
        },
    )?;
    Ok(result.tabs)
}

fn move_tab(socket_path: &str, tab_id: &str, insert_index: usize) -> Result<Vec<TabInfo>, String> {
    let result: TabMoveResult = call_socket(
        socket_path,
        "tab.move",
        &TabMoveParams {
            tab_id: tab_id.to_string(),
            insert_index,
        },
    )?;
    Ok(result.tabs)
}

fn request_insert_index(current_index: usize, target_index: usize) -> usize {
    if target_index < current_index {
        target_index
    } else {
        target_index + 1
    }
}

fn call_socket<P, R>(socket_path: &str, method: &str, params: &P) -> Result<R, String>
where
    P: Serialize,
    R: DeserializeOwned,
{
    let request_id = format!("tab-move-{}-{}", process::id(), unique_suffix());
    let request = SocketRequest {
        id: &request_id,
        method,
        params,
    };

    let mut socket = UnixStream::connect(socket_path)
        .map_err(|error| format!("failed to connect to Herdr socket: {error}"))?;
    let mut payload = serde_json::to_vec(&request)
        .map_err(|error| format!("failed to encode request: {error}"))?;
    payload.push(b'\n');
    socket
        .write_all(&payload)
        .and_then(|_| socket.flush())
        .map_err(|error| format!("failed to send request to Herdr socket: {error}"))?;

    let mut raw_response = String::new();
    let mut reader = BufReader::new(socket);
    reader
        .read_line(&mut raw_response)
        .map_err(|error| format!("failed to read response from Herdr socket: {error}"))?;

    if raw_response.is_empty() {
        return Err("empty response from Herdr socket".to_string());
    }

    let response: SocketResponse<R> = serde_json::from_str(&raw_response)
        .map_err(|error| format!("failed to decode Herdr response: {error}"))?;

    if response.id != request_id {
        return Err("unexpected response id from Herdr socket".to_string());
    }

    if let Some(error) = response.error {
        return Err(format!(
            "{method} failed: {}: {}",
            error.code, error.message
        ));
    }

    response
        .result
        .ok_or_else(|| format!("unexpected {method} response"))
}

fn unique_suffix() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_nanos())
        .unwrap_or_default()
}

#[derive(Clone, Copy)]
enum Direction {
    Left,
    Right,
}

impl Direction {
    fn parse(raw: &str) -> Result<Self, String> {
        match raw {
            "left" => Ok(Self::Left),
            "right" => Ok(Self::Right),
            _ => Err(format!("unsupported direction: {raw}")),
        }
    }

    fn as_str(self) -> &'static str {
        match self {
            Self::Left => "left",
            Self::Right => "right",
        }
    }

    fn offset(self) -> isize {
        match self {
            Self::Left => -1,
            Self::Right => 1,
        }
    }
}

#[derive(Default, Deserialize)]
struct PluginContext {
    workspace_id: Option<String>,
    tab_id: Option<String>,
}

#[derive(Serialize)]
struct SocketRequest<'a, P> {
    id: &'a str,
    method: &'a str,
    params: &'a P,
}

#[derive(Deserialize)]
struct SocketResponse<R> {
    id: String,
    result: Option<R>,
    error: Option<SocketError>,
}

#[derive(Deserialize)]
struct SocketError {
    code: String,
    message: String,
}

#[derive(Deserialize)]
struct TabInfo {
    tab_id: String,
    #[allow(dead_code)]
    workspace_id: Option<String>,
}

#[derive(Deserialize)]
struct TabGetResult {
    tab: TabInfo,
}

#[derive(Deserialize)]
struct TabListResult {
    tabs: Vec<TabInfo>,
}

#[derive(Deserialize)]
struct TabMoveResult {
    tabs: Vec<TabInfo>,
}

#[derive(Serialize)]
struct TabTarget {
    tab_id: String,
}

#[derive(Serialize)]
struct TabListParams {
    workspace_id: Option<String>,
}

#[derive(Serialize)]
struct TabMoveParams {
    tab_id: String,
    insert_index: usize,
}

#[cfg(test)]
mod tests {
    use super::{plugin_context, request_insert_index, Direction};
    use std::env;

    #[test]
    fn request_insert_index_moves_left_without_shift() {
        assert_eq!(request_insert_index(3, 2), 2);
    }

    #[test]
    fn request_insert_index_moves_right_with_shift() {
        assert_eq!(request_insert_index(1, 2), 3);
    }

    #[test]
    fn direction_parse_rejects_unknown_values() {
        assert!(Direction::parse("up").is_err());
    }

    #[test]
    fn plugin_context_reads_runtime_json() {
        env::set_var(
            "HERDR_PLUGIN_CONTEXT_JSON",
            r#"{"workspace_id":"w1","tab_id":"w1:t1","ignored":"ok"}"#,
        );
        let context = plugin_context().expect("context should parse");
        assert_eq!(context.workspace_id.as_deref(), Some("w1"));
        assert_eq!(context.tab_id.as_deref(), Some("w1:t1"));
        env::remove_var("HERDR_PLUGIN_CONTEXT_JSON");
    }
}
