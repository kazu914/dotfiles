use std::env;
use std::process;
use tab_move::{
    env_nonempty, move_tab, plugin_context, resolve_workspace_id, socket_path, tab_list,
};

fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let direction = Direction::parse(env::args().nth(1).as_deref().unwrap_or("right"))?;
    let context = plugin_context()?;
    let socket_path = socket_path()?;
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

fn request_insert_index(current_index: usize, target_index: usize) -> usize {
    if target_index < current_index {
        target_index
    } else {
        target_index + 1
    }
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

#[cfg(test)]
mod tests {
    use super::{request_insert_index, Direction};
    use std::env;
    use tab_move::plugin_context;

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
