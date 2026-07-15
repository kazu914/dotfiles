#[cfg(not(unix))]
compile_error!("tab-actions requires Unix domain sockets");

use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::env;
use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use std::path::{Path, PathBuf};
use std::process;
use std::time::{SystemTime, UNIX_EPOCH};

const WORKSPACE_PICKER_STATE_FILE: &str = "workspace-picker.json";

pub fn env_nonempty(name: &str) -> Option<String> {
    match env::var(name) {
        Ok(value) if !value.is_empty() => Some(value),
        _ => None,
    }
}

pub fn plugin_context() -> Result<PluginContext, String> {
    match env_nonempty("HERDR_PLUGIN_CONTEXT_JSON") {
        Some(raw) => serde_json::from_str(&raw)
            .map_err(|error| format!("failed to parse HERDR_PLUGIN_CONTEXT_JSON: {error}")),
        None => Ok(PluginContext::default()),
    }
}

pub fn socket_path() -> Result<String, String> {
    env_nonempty("HERDR_SOCKET_PATH").ok_or_else(|| "HERDR_SOCKET_PATH is missing".to_string())
}

pub fn plugin_state_dir() -> Result<PathBuf, String> {
    env_nonempty("HERDR_PLUGIN_STATE_DIR")
        .map(PathBuf::from)
        .ok_or_else(|| "HERDR_PLUGIN_STATE_DIR is missing".to_string())
}

pub fn load_workspace_picker_state() -> Result<Option<WorkspacePickerState>, String> {
    load_workspace_picker_state_from(&workspace_picker_state_path()?)
}

pub fn save_workspace_picker_state(state: &WorkspacePickerState) -> Result<(), String> {
    save_workspace_picker_state_at(&workspace_picker_state_path()?, state)
}

pub fn clear_workspace_picker_state() -> Result<(), String> {
    clear_workspace_picker_state_at(&workspace_picker_state_path()?)
}

pub fn load_workspace_picker_bindings() -> Result<WorkspacePickerBindings, String> {
    load_workspace_picker_bindings_from(&tab_actions_config_path()?)
}

pub fn resolve_workspace_id(
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

pub fn resolve_current_pane_id(
    context: &PluginContext,
    snapshot: &SessionSnapshot,
) -> Result<String, String> {
    env_nonempty("HERDR_PANE_ID")
        .or_else(|| context.pane_id.clone())
        .or_else(|| snapshot.focused_pane_id.clone())
        .ok_or_else(|| "current pane_id could not be resolved".to_string())
}

pub fn resolve_current_tab_id(
    context: &PluginContext,
    snapshot: &SessionSnapshot,
) -> Result<String, String> {
    env_nonempty("HERDR_TAB_ID")
        .or_else(|| context.tab_id.clone())
        .or_else(|| snapshot.focused_tab_id.clone())
        .ok_or_else(|| "current tab_id could not be resolved".to_string())
}

pub fn resolve_current_workspace_id(
    context: &PluginContext,
    snapshot: &SessionSnapshot,
) -> Result<String, String> {
    env_nonempty("HERDR_WORKSPACE_ID")
        .or_else(|| context.workspace_id.clone())
        .or_else(|| snapshot.focused_workspace_id.clone())
        .ok_or_else(|| "current workspace_id could not be resolved".to_string())
}

pub fn tab_list(socket_path: &str, workspace_id: &str) -> Result<Vec<TabInfo>, String> {
    let result: TabListResult = call_socket(
        socket_path,
        "tab.list",
        &TabListParams {
            workspace_id: Some(workspace_id.to_string()),
        },
    )?;
    Ok(result.tabs)
}

pub fn move_tab(
    socket_path: &str,
    tab_id: &str,
    insert_index: usize,
) -> Result<Vec<TabInfo>, String> {
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

pub fn workspace_list(socket_path: &str) -> Result<Vec<WorkspaceInfo>, String> {
    let result: WorkspaceListResult = call_socket(socket_path, "workspace.list", &EmptyParams {})?;
    Ok(result.workspaces)
}

pub fn workspace_focus(socket_path: &str, workspace_id: &str) -> Result<WorkspaceInfo, String> {
    let result: WorkspaceInfoResult = call_socket(
        socket_path,
        "workspace.focus",
        &WorkspaceTarget {
            workspace_id: workspace_id.to_string(),
        },
    )?;
    Ok(result.workspace)
}

pub fn workspace_close(
    socket_path: &str,
    workspace_id: &str,
) -> Result<WorkspaceClosedResult, String> {
    call_socket(
        socket_path,
        "workspace.close",
        &WorkspaceTarget {
            workspace_id: workspace_id.to_string(),
        },
    )
}

pub fn session_snapshot(socket_path: &str) -> Result<SessionSnapshot, String> {
    let result: SessionSnapshotResult =
        call_socket(socket_path, "session.snapshot", &EmptyParams {})?;
    Ok(result.snapshot)
}

pub fn pane_read(
    socket_path: &str,
    pane_id: &str,
    source: PaneReadSource,
    lines: usize,
) -> Result<PaneReadResult, String> {
    let result: PaneReadEnvelope = call_socket(
        socket_path,
        "pane.read",
        &PaneReadParams {
            pane_id: pane_id.to_string(),
            source: source.as_str().to_string(),
            format: "text".to_string(),
            lines,
        },
    )?;
    Ok(result.read)
}

pub fn plugin_pane_open_split(
    socket_path: &str,
    plugin_id: &str,
    entrypoint: &str,
    target_pane_id: &str,
    env: BTreeMap<String, String>,
    focus: bool,
) -> Result<PluginPaneInfo, String> {
    let result: PluginPaneOpenedResult = call_socket(
        socket_path,
        "plugin.pane.open",
        &PluginPaneOpenParams {
            plugin_id: plugin_id.to_string(),
            entrypoint: entrypoint.to_string(),
            placement: Some("split".to_string()),
            target_pane_id: Some(target_pane_id.to_string()),
            direction: Some("right".to_string()),
            focus,
            env,
        },
    )?;
    Ok(result.plugin_pane)
}

pub fn plugin_pane_focus(socket_path: &str, pane_id: &str) -> Result<PluginPaneInfo, String> {
    let result: PluginPaneFocusedResult = call_socket(
        socket_path,
        "plugin.pane.focus",
        &PaneTarget {
            pane_id: pane_id.to_string(),
        },
    )?;
    Ok(result.plugin_pane)
}

pub fn plugin_pane_close(socket_path: &str, pane_id: &str) -> Result<(), String> {
    let _: PluginPaneClosedResult = call_socket(
        socket_path,
        "plugin.pane.close",
        &PaneTarget {
            pane_id: pane_id.to_string(),
        },
    )?;
    Ok(())
}

pub fn pane_swap(
    socket_path: &str,
    source_pane_id: &str,
    target_pane_id: &str,
) -> Result<PaneSwapResult, String> {
    let result: PaneSwapEnvelope = call_socket(
        socket_path,
        "pane.swap",
        &PaneSwapParams {
            source_pane_id: Some(source_pane_id.to_string()),
            target_pane_id: Some(target_pane_id.to_string()),
            pane_id: None,
            direction: None,
        },
    )?;
    Ok(result.swap)
}

pub fn pane_move_to_tab_split(
    socket_path: &str,
    pane_id: &str,
    tab_id: &str,
    target_pane_id: &str,
    split: SplitDirection,
    focus: bool,
) -> Result<PaneMoveResult, String> {
    let result: PaneMoveEnvelope = call_socket(
        socket_path,
        "pane.move",
        &PaneMoveParams {
            pane_id: pane_id.to_string(),
            focus,
            destination: PaneMoveDestination::Tab {
                tab_id: tab_id.to_string(),
                target_pane_id: Some(target_pane_id.to_string()),
                split,
                ratio: None,
            },
        },
    )?;
    Ok(result.move_result)
}

fn call_socket<P, R>(socket_path: &str, method: &str, params: &P) -> Result<R, String>
where
    P: Serialize,
    R: DeserializeOwned,
{
    let request_id = format!("tab-actions-{}-{}", process::id(), unique_suffix());
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

fn workspace_picker_state_path() -> Result<PathBuf, String> {
    Ok(workspace_picker_state_path_for(&plugin_state_dir()?))
}

fn herdr_config_path() -> Result<PathBuf, String> {
    if let Some(path) = env_nonempty("HERDR_CONFIG_PATH") {
        return Ok(PathBuf::from(path));
    }

    let home = env_nonempty("HOME").ok_or_else(|| "HOME is missing".to_string())?;
    Ok(PathBuf::from(home).join(".config/herdr/config.toml"))
}

fn tab_actions_config_path() -> Result<PathBuf, String> {
    if let Some(plugin_id) = env_nonempty("HERDR_PLUGIN_ID") {
        let herdr_config_path = herdr_config_path()?;
        let parent = herdr_config_path.parent().ok_or_else(|| {
            format!(
                "failed to resolve config directory for {}",
                herdr_config_path.display()
            )
        })?;
        return Ok(parent
            .join("plugins")
            .join("config")
            .join(plugin_id)
            .join("config.toml"));
    }

    let herdr_config_path = herdr_config_path()?;
    let parent = herdr_config_path.parent().ok_or_else(|| {
        format!(
            "failed to resolve config directory for {}",
            herdr_config_path.display()
        )
    })?;
    Ok(parent.join("tab-actions.toml"))
}

fn workspace_picker_state_path_for(dir: &Path) -> PathBuf {
    dir.join(WORKSPACE_PICKER_STATE_FILE)
}

fn load_workspace_picker_bindings_from(path: &Path) -> Result<WorkspacePickerBindings, String> {
    let raw = match fs::read_to_string(path) {
        Ok(raw) => raw,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
            return Ok(WorkspacePickerBindings::default());
        }
        Err(error) => {
            return Err(format!(
                "failed to read tab-actions config {}: {error}",
                path.display()
            ));
        }
    };

    let config: TabActionsConfigFile = toml::from_str(&raw).map_err(|error| {
        format!(
            "failed to parse tab-actions config {}: {error}",
            path.display()
        )
    })?;
    let default = WorkspacePickerBindings::default();
    let picker = config.workspace_picker.as_ref();

    Ok(WorkspacePickerBindings {
        move_up: picker
            .and_then(|picker| picker.move_up.clone())
            .filter(|value| !value.is_empty())
            .unwrap_or(default.move_up),
        move_down: picker
            .and_then(|picker| picker.move_down.clone())
            .filter(|value| !value.is_empty())
            .unwrap_or(default.move_down),
        delete_workspace: picker
            .and_then(|picker| picker.delete_workspace.clone())
            .filter(|value| !value.is_empty())
            .unwrap_or(default.delete_workspace),
    })
}

fn load_workspace_picker_state_from(path: &Path) -> Result<Option<WorkspacePickerState>, String> {
    let raw = match fs::read_to_string(path) {
        Ok(raw) => raw,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(error) => {
            return Err(format!(
                "failed to read workspace picker state {}: {error}",
                path.display()
            ));
        }
    };

    serde_json::from_str(&raw).map(Some).map_err(|error| {
        format!(
            "failed to parse workspace picker state {}: {error}",
            path.display()
        )
    })
}

fn save_workspace_picker_state_at(path: &Path, state: &WorkspacePickerState) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|error| {
            format!(
                "failed to create workspace picker state directory {}: {error}",
                parent.display()
            )
        })?;
    }

    let mut payload = serde_json::to_vec_pretty(state)
        .map_err(|error| format!("failed to encode workspace picker state: {error}"))?;
    payload.push(b'\n');
    fs::write(path, payload).map_err(|error| {
        format!(
            "failed to write workspace picker state {}: {error}",
            path.display()
        )
    })
}

fn clear_workspace_picker_state_at(path: &Path) -> Result<(), String> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(error) => Err(format!(
            "failed to remove workspace picker state {}: {error}",
            path.display()
        )),
    }
}

#[derive(Default, Deserialize)]
pub struct PluginContext {
    pub workspace_id: Option<String>,
    pub tab_id: Option<String>,
    pub pane_id: Option<String>,
}

#[derive(Clone, Debug, Deserialize, PartialEq, Eq, Serialize)]
pub struct WorkspacePickerState {
    pub pane_id: String,
    pub workspace_id: String,
    pub tab_id: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WorkspacePickerBindings {
    pub move_up: String,
    pub move_down: String,
    pub delete_workspace: String,
}

impl Default for WorkspacePickerBindings {
    fn default() -> Self {
        Self {
            move_up: "k".to_string(),
            move_down: "j".to_string(),
            delete_workspace: "ctrl+d".to_string(),
        }
    }
}

#[derive(Clone, Debug, Deserialize)]
pub struct TabInfo {
    pub tab_id: String,
    pub workspace_id: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
pub struct WorkspaceInfo {
    pub workspace_id: String,
    pub number: usize,
    pub label: String,
    pub focused: bool,
    pub pane_count: usize,
    pub tab_count: usize,
    pub active_tab_id: String,
    #[serde(default = "unknown_agent_status")]
    pub agent_status: String,
}

#[derive(Clone, Debug, Deserialize)]
pub struct WorkspaceClosedResult {
    pub workspace_id: String,
    pub workspace: Option<WorkspaceInfo>,
}

#[derive(Clone, Debug, Deserialize)]
pub struct SessionSnapshot {
    pub focused_pane_id: Option<String>,
    pub focused_tab_id: Option<String>,
    pub focused_workspace_id: Option<String>,
    pub workspaces: Vec<WorkspaceInfo>,
    pub layouts: Vec<LayoutInfo>,
    pub panes: Vec<PaneInfo>,
}

#[derive(Clone, Debug, Deserialize)]
pub struct LayoutInfo {
    pub workspace_id: String,
    pub tab_id: String,
    pub focused_pane_id: String,
}

#[derive(Clone, Debug, Deserialize)]
pub struct PaneInfo {
    pub pane_id: String,
    pub workspace_id: String,
    pub tab_id: String,
    pub cwd: Option<String>,
    pub foreground_cwd: Option<String>,
    pub agent: Option<String>,
    pub agent_status: String,
}

#[derive(Clone, Debug, Deserialize)]
pub struct PluginPaneInfo {
    pub plugin_id: String,
    pub entrypoint: String,
    pub pane: PaneInfo,
}

#[derive(Clone, Debug, Deserialize)]
pub struct PaneMoveResult {
    pub pane: PaneInfo,
    pub previous_workspace_id: String,
    pub previous_tab_id: String,
    pub previous_pane_id: String,
    pub focused_pane_id: String,
}

#[derive(Clone, Debug, Deserialize)]
pub struct PaneSwapResult {
    pub changed: bool,
    pub source_pane_id: String,
    pub target_pane_id: Option<String>,
    pub focused_pane_id: String,
    pub reason: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
pub struct PaneReadResult {
    pub pane_id: String,
    pub workspace_id: String,
    pub tab_id: String,
    pub text: String,
    pub truncated: bool,
}

#[derive(Clone, Copy, Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum SplitDirection {
    Right,
    Down,
}

#[derive(Clone, Copy, Debug)]
pub enum PaneReadSource {
    Visible,
    Recent,
    RecentUnwrapped,
}

impl PaneReadSource {
    fn as_str(self) -> &'static str {
        match self {
            Self::Visible => "visible",
            Self::Recent => "recent",
            Self::RecentUnwrapped => "recent_unwrapped",
        }
    }
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

#[derive(Deserialize)]
struct WorkspaceListResult {
    workspaces: Vec<WorkspaceInfo>,
}

#[derive(Deserialize)]
struct WorkspaceInfoResult {
    workspace: WorkspaceInfo,
}

#[derive(Deserialize)]
struct SessionSnapshotResult {
    snapshot: SessionSnapshot,
}

#[derive(Deserialize)]
struct PaneReadEnvelope {
    read: PaneReadResult,
}

#[derive(Deserialize)]
struct PluginPaneOpenedResult {
    plugin_pane: PluginPaneInfo,
}

#[derive(Deserialize)]
struct PluginPaneFocusedResult {
    plugin_pane: PluginPaneInfo,
}

#[derive(Deserialize)]
struct PluginPaneClosedResult {}

#[derive(Deserialize)]
struct PaneSwapEnvelope {
    swap: PaneSwapResult,
}

#[derive(Deserialize)]
struct PaneMoveEnvelope {
    move_result: PaneMoveResult,
}

#[derive(Serialize)]
struct EmptyParams {}

#[derive(Serialize)]
struct TabTarget {
    tab_id: String,
}

#[derive(Serialize)]
struct WorkspaceTarget {
    workspace_id: String,
}

#[derive(Serialize)]
struct PaneTarget {
    pane_id: String,
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

#[derive(Serialize)]
struct PaneReadParams {
    pane_id: String,
    source: String,
    format: String,
    lines: usize,
}

#[derive(Serialize)]
struct PluginPaneOpenParams {
    plugin_id: String,
    entrypoint: String,
    placement: Option<String>,
    target_pane_id: Option<String>,
    direction: Option<String>,
    focus: bool,
    env: BTreeMap<String, String>,
}

#[derive(Serialize)]
struct PaneSwapParams {
    source_pane_id: Option<String>,
    target_pane_id: Option<String>,
    pane_id: Option<String>,
    direction: Option<String>,
}

#[derive(Serialize)]
struct PaneMoveParams {
    pane_id: String,
    focus: bool,
    destination: PaneMoveDestination,
}

#[derive(Default, Deserialize)]
struct TabActionsConfigFile {
    workspace_picker: Option<WorkspacePickerConfig>,
}

#[derive(Default, Deserialize)]
struct WorkspacePickerConfig {
    move_up: Option<String>,
    move_down: Option<String>,
    delete_workspace: Option<String>,
}

#[derive(Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum PaneMoveDestination {
    Tab {
        tab_id: String,
        target_pane_id: Option<String>,
        split: SplitDirection,
        ratio: Option<f32>,
    },
}

fn unknown_agent_status() -> String {
    "unknown".to_string()
}

#[cfg(test)]
mod tests {
    use super::{
        clear_workspace_picker_state_at, load_workspace_picker_bindings_from,
        load_workspace_picker_state_from, save_workspace_picker_state_at,
        workspace_picker_state_path_for, WorkspacePickerBindings, WorkspacePickerState,
    };
    use std::fs;

    #[test]
    fn workspace_picker_state_round_trips() {
        let dir =
            std::env::temp_dir().join(format!("tab-actions-state-{}", super::unique_suffix()));
        let path = workspace_picker_state_path_for(&dir);
        let state = WorkspacePickerState {
            pane_id: "picker".into(),
            workspace_id: "w1".into(),
            tab_id: "w1:t1".into(),
        };

        save_workspace_picker_state_at(&path, &state).expect("state should save");
        let loaded = load_workspace_picker_state_from(&path).expect("state should load");

        assert_eq!(loaded, Some(state));

        clear_workspace_picker_state_at(&path).expect("state should clear");
        assert_eq!(
            load_workspace_picker_state_from(&path).expect("cleared state should load"),
            None
        );

        let _ = fs::remove_dir_all(dir);
    }

    #[test]
    fn workspace_picker_bindings_follow_tab_actions_config() {
        let dir =
            std::env::temp_dir().join(format!("tab-actions-config-{}", super::unique_suffix()));
        let path = dir.join("tab-actions.toml");
        fs::create_dir_all(&dir).expect("config dir should create");
        fs::write(
            &path,
            r#"
[workspace_picker]
move_up = "ctrl+k"
move_down = "ctrl+j"
delete_workspace = "ctrl+d"
"#,
        )
        .expect("config should write");

        let bindings = load_workspace_picker_bindings_from(&path).expect("bindings should load");

        assert_eq!(
            bindings,
            WorkspacePickerBindings {
                move_up: "ctrl+k".into(),
                move_down: "ctrl+j".into(),
                delete_workspace: "ctrl+d".into(),
            }
        );

        let _ = fs::remove_dir_all(dir);
    }
}
