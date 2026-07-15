use std::collections::BTreeMap;
use std::env;
use std::thread;
use std::time::Duration;
use tab_move::{
    pane_swap, plugin_pane_focus, plugin_pane_open_split, save_workspace_picker_state,
    WorkspacePickerState,
};

const ENTRYPOINT_ID: &str = "workspace-picker";
const ORIGIN_PANE_ID_ENV: &str = "TAB_ACTIONS_ORIGIN_PANE_ID";
const ORIGIN_TAB_ID_ENV: &str = "TAB_ACTIONS_ORIGIN_TAB_ID";
const ORIGIN_WORKSPACE_ID_ENV: &str = "TAB_ACTIONS_ORIGIN_WORKSPACE_ID";

fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let args = ReopenArgs::parse(env::args().skip(1))?;
    let reopen_env = reopen_env(&args);
    let mut last_error = None;

    for _ in 0..20 {
        thread::sleep(Duration::from_millis(100));
        match plugin_pane_open_split(
            &args.socket_path,
            &args.plugin_id,
            ENTRYPOINT_ID,
            &args.target_pane_id,
            reopen_env.clone(),
            false,
        ) {
            Ok(opened) => {
                let picker_pane_id = opened.pane.pane_id.clone();
                let _ = pane_swap(&args.socket_path, &picker_pane_id, &args.target_pane_id);
                let _ = plugin_pane_focus(&args.socket_path, &picker_pane_id);
                save_workspace_picker_state(&WorkspacePickerState {
                    pane_id: opened.pane.pane_id,
                    workspace_id: opened.pane.workspace_id,
                    tab_id: opened.pane.tab_id,
                })?;
                return Ok(());
            }
            Err(error) => {
                last_error = Some(error);
            }
        }
    }

    Err(last_error.unwrap_or_else(|| "workspace picker reopen helper timed out".to_string()))
}

fn reopen_env(args: &ReopenArgs) -> BTreeMap<String, String> {
    let mut env = BTreeMap::new();
    env.insert(ORIGIN_PANE_ID_ENV.to_string(), args.origin_pane_id.clone());
    env.insert(ORIGIN_TAB_ID_ENV.to_string(), args.origin_tab_id.clone());
    env.insert(
        ORIGIN_WORKSPACE_ID_ENV.to_string(),
        args.origin_workspace_id.clone(),
    );
    env
}

struct ReopenArgs {
    socket_path: String,
    plugin_id: String,
    target_pane_id: String,
    origin_pane_id: String,
    origin_tab_id: String,
    origin_workspace_id: String,
}

impl ReopenArgs {
    fn parse<I>(mut args: I) -> Result<Self, String>
    where
        I: Iterator<Item = String>,
    {
        let mut socket_path = None;
        let mut plugin_id = None;
        let mut target_pane_id = None;
        let mut origin_pane_id = None;
        let mut origin_tab_id = None;
        let mut origin_workspace_id = None;

        while let Some(flag) = args.next() {
            let value = args
                .next()
                .ok_or_else(|| format!("missing value for {flag}"))?;
            match flag.as_str() {
                "--socket-path" => socket_path = Some(value),
                "--plugin-id" => plugin_id = Some(value),
                "--target-pane-id" => target_pane_id = Some(value),
                "--origin-pane-id" => origin_pane_id = Some(value),
                "--origin-tab-id" => origin_tab_id = Some(value),
                "--origin-workspace-id" => origin_workspace_id = Some(value),
                _ => return Err(format!("unknown argument: {flag}")),
            }
        }

        Ok(Self {
            socket_path: socket_path.ok_or_else(|| "--socket-path is required".to_string())?,
            plugin_id: plugin_id.ok_or_else(|| "--plugin-id is required".to_string())?,
            target_pane_id: target_pane_id
                .ok_or_else(|| "--target-pane-id is required".to_string())?,
            origin_pane_id: origin_pane_id
                .ok_or_else(|| "--origin-pane-id is required".to_string())?,
            origin_tab_id: origin_tab_id
                .ok_or_else(|| "--origin-tab-id is required".to_string())?,
            origin_workspace_id: origin_workspace_id
                .ok_or_else(|| "--origin-workspace-id is required".to_string())?,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::ReopenArgs;

    #[test]
    fn parse_reopen_args_requires_all_fields() {
        let args = vec![
            "--socket-path".to_string(),
            "/tmp/herdr.sock".to_string(),
            "--plugin-id".to_string(),
            "kazu914.tab-actions".to_string(),
            "--target-pane-id".to_string(),
            "pane-1".to_string(),
            "--origin-pane-id".to_string(),
            "pane-0".to_string(),
            "--origin-tab-id".to_string(),
            "w1:t1".to_string(),
            "--origin-workspace-id".to_string(),
            "w1".to_string(),
        ];

        let parsed = ReopenArgs::parse(args.into_iter()).expect("args should parse");

        assert_eq!(parsed.socket_path, "/tmp/herdr.sock");
        assert_eq!(parsed.plugin_id, "kazu914.tab-actions");
        assert_eq!(parsed.target_pane_id, "pane-1");
        assert_eq!(parsed.origin_pane_id, "pane-0");
        assert_eq!(parsed.origin_tab_id, "w1:t1");
        assert_eq!(parsed.origin_workspace_id, "w1");
    }
}
