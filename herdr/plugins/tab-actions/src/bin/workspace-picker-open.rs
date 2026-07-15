use std::collections::BTreeMap;
use tab_move::{
    clear_workspace_picker_state, env_nonempty, load_workspace_picker_state, pane_swap,
    plugin_context, plugin_pane_close, plugin_pane_focus, plugin_pane_open_split,
    resolve_current_pane_id, resolve_current_tab_id, resolve_current_workspace_id,
    session_snapshot, socket_path, PluginPaneInfo, SessionSnapshot, WorkspacePickerState,
};

const ENTRYPOINT_ID: &str = "workspace-picker";
const ORIGIN_PANE_ID_ENV: &str = "TAB_ACTIONS_ORIGIN_PANE_ID";
const ORIGIN_TAB_ID_ENV: &str = "TAB_ACTIONS_ORIGIN_TAB_ID";
const ORIGIN_WORKSPACE_ID_ENV: &str = "TAB_ACTIONS_ORIGIN_WORKSPACE_ID";

#[derive(Debug, PartialEq, Eq)]
enum PickerLaunchDecision<'a> {
    Open,
    ToggleClose(&'a str),
    Reopen(&'a str),
    ClearStale,
}

fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let socket_path = socket_path()?;
    let plugin_id =
        env_nonempty("HERDR_PLUGIN_ID").ok_or_else(|| "HERDR_PLUGIN_ID is missing".to_string())?;
    let context = plugin_context()?;
    let snapshot = session_snapshot(&socket_path)?;
    let origin_pane_id = resolve_current_pane_id(&context, &snapshot)?;
    let origin_tab_id = resolve_current_tab_id(&context, &snapshot)?;
    let origin_workspace_id = resolve_current_workspace_id(&context, &snapshot)?;
    let existing_picker_state = recover_workspace_picker_state()?;

    match decide_picker_launch(
        &snapshot,
        existing_picker_state.as_ref(),
        &origin_workspace_id,
    ) {
        PickerLaunchDecision::ToggleClose(pane_id) => {
            plugin_pane_close(&socket_path, pane_id)?;
            clear_workspace_picker_state()?;
            return Ok(());
        }
        PickerLaunchDecision::Reopen(pane_id) => {
            plugin_pane_close(&socket_path, pane_id)?;
            clear_workspace_picker_state()?;
        }
        PickerLaunchDecision::ClearStale => {
            clear_workspace_picker_state()?;
        }
        PickerLaunchDecision::Open => {}
    }

    let mut env = BTreeMap::new();
    env.insert(ORIGIN_PANE_ID_ENV.to_string(), origin_pane_id.clone());
    env.insert(ORIGIN_TAB_ID_ENV.to_string(), origin_tab_id);
    env.insert(ORIGIN_WORKSPACE_ID_ENV.to_string(), origin_workspace_id);

    let opened = plugin_pane_open_split(
        &socket_path,
        &plugin_id,
        ENTRYPOINT_ID,
        &origin_pane_id,
        env,
        false,
    )?;
    let picker_pane_id = opened.pane.pane_id.clone();

    if let Err(error) = pane_swap(&socket_path, &picker_pane_id, &origin_pane_id) {
        let _ = clear_workspace_picker_state();
        let _ = plugin_pane_close(&socket_path, &picker_pane_id);
        return Err(format!(
            "failed to place workspace picker on the left side: {error}"
        ));
    }

    if let Err(error) = plugin_pane_focus(&socket_path, &picker_pane_id) {
        let _ = clear_workspace_picker_state();
        let _ = plugin_pane_close(&socket_path, &picker_pane_id);
        return Err(format!("failed to focus workspace picker pane: {error}"));
    }

    persist_picker_state(&opened).map_err(|error| {
        let _ = clear_workspace_picker_state();
        let _ = plugin_pane_close(&socket_path, &picker_pane_id);
        error
    })?;

    Ok(())
}

fn persist_picker_state(opened: &PluginPaneInfo) -> Result<(), String> {
    tab_move::save_workspace_picker_state(&WorkspacePickerState {
        pane_id: opened.pane.pane_id.clone(),
        workspace_id: opened.pane.workspace_id.clone(),
        tab_id: opened.pane.tab_id.clone(),
    })
}

fn recover_workspace_picker_state() -> Result<Option<WorkspacePickerState>, String> {
    match load_workspace_picker_state() {
        Ok(state) => Ok(state),
        Err(error) => {
            clear_workspace_picker_state().map_err(|clear_error| {
                format!(
                    "failed to clear invalid workspace picker state after load error ({error}): {clear_error}"
                )
            })?;
            Ok(None)
        }
    }
}

fn decide_picker_launch<'a>(
    snapshot: &SessionSnapshot,
    state: Option<&'a WorkspacePickerState>,
    current_workspace_id: &str,
) -> PickerLaunchDecision<'a> {
    let Some(state) = state else {
        return PickerLaunchDecision::Open;
    };

    if !snapshot
        .panes
        .iter()
        .any(|pane| pane.pane_id == state.pane_id)
    {
        return PickerLaunchDecision::ClearStale;
    }

    if state.workspace_id == current_workspace_id {
        PickerLaunchDecision::ToggleClose(&state.pane_id)
    } else {
        PickerLaunchDecision::Reopen(&state.pane_id)
    }
}

#[cfg(test)]
mod tests {
    use super::{decide_picker_launch, PickerLaunchDecision};
    use tab_move::{PaneInfo, SessionSnapshot, WorkspaceInfo, WorkspacePickerState};

    #[test]
    fn same_workspace_picker_toggles_closed() {
        let state = WorkspacePickerState {
            pane_id: "picker".into(),
            workspace_id: "w1".into(),
            tab_id: "w1:t1".into(),
        };

        assert_eq!(
            decide_picker_launch(&snapshot_with_picker("picker", "w1"), Some(&state), "w1"),
            PickerLaunchDecision::ToggleClose("picker")
        );
    }

    #[test]
    fn foreign_workspace_picker_is_reopened_locally() {
        let state = WorkspacePickerState {
            pane_id: "picker".into(),
            workspace_id: "w2".into(),
            tab_id: "w2:t1".into(),
        };

        assert_eq!(
            decide_picker_launch(&snapshot_with_picker("picker", "w2"), Some(&state), "w1"),
            PickerLaunchDecision::Reopen("picker")
        );
    }

    #[test]
    fn missing_picker_state_is_cleared_before_opening() {
        let state = WorkspacePickerState {
            pane_id: "picker".into(),
            workspace_id: "w1".into(),
            tab_id: "w1:t1".into(),
        };

        assert_eq!(
            decide_picker_launch(&empty_snapshot(), Some(&state), "w1"),
            PickerLaunchDecision::ClearStale
        );
    }

    fn snapshot_with_picker(pane_id: &str, workspace_id: &str) -> SessionSnapshot {
        SessionSnapshot {
            focused_pane_id: Some(pane_id.into()),
            focused_tab_id: Some(format!("{workspace_id}:t1")),
            focused_workspace_id: Some(workspace_id.into()),
            workspaces: vec![WorkspaceInfo {
                workspace_id: workspace_id.into(),
                number: 1,
                label: "one".into(),
                focused: true,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: format!("{workspace_id}:t1"),
                agent_status: "unknown".into(),
            }],
            layouts: vec![],
            panes: vec![PaneInfo {
                pane_id: pane_id.into(),
                workspace_id: workspace_id.into(),
                tab_id: format!("{workspace_id}:t1"),
                cwd: None,
                foreground_cwd: None,
                agent: None,
                agent_status: "unknown".into(),
            }],
        }
    }

    fn empty_snapshot() -> SessionSnapshot {
        SessionSnapshot {
            focused_pane_id: None,
            focused_tab_id: None,
            focused_workspace_id: None,
            workspaces: vec![],
            layouts: vec![],
            panes: vec![],
        }
    }
}
