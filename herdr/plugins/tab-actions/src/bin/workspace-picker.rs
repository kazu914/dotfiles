use crossterm::cursor::{Hide, MoveTo, Show};
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use crossterm::style::{Attribute, Color, Print, ResetColor, SetAttribute, SetForegroundColor};
use crossterm::terminal::{
    self, disable_raw_mode, enable_raw_mode, Clear, ClearType, EnterAlternateScreen,
    LeaveAlternateScreen,
};
use crossterm::{execute, queue};
use std::collections::BTreeMap;
use std::io::{stdout, Stdout, Write};
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};
use tab_move::{
    env_nonempty, load_workspace_picker_bindings, pane_move_to_tab_split, pane_swap,
    plugin_context, plugin_pane_focus, resolve_current_pane_id, resolve_current_tab_id,
    resolve_current_workspace_id, save_workspace_picker_state, session_snapshot, socket_path,
    workspace_close, workspace_focus, PaneInfo, PluginContext, SessionSnapshot, SplitDirection,
    WorkspaceInfo, WorkspacePickerBindings, WorkspacePickerState,
};

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
    let socket_path = socket_path()?;
    let context = plugin_context()?;
    let mut snapshot = session_snapshot(&socket_path)?;
    if snapshot.workspaces.is_empty() {
        return Ok(());
    }

    let origin = OriginState::from_env(&context, &snapshot)?;
    let picker_pane_id = resolve_current_pane_id(&context, &snapshot)?;
    let mut app = PickerApp::new(
        snapshot.workspaces.clone(),
        picker_pane_id,
        origin,
        &snapshot,
        PickerKeymap::load(),
    )?;
    app.sync_state()?;
    let mut terminal = TerminalSession::enter()?;

    loop {
        draw(&mut terminal.stdout, &app)?;

        match event::read().map_err(|error| format!("failed to read key event: {error}"))? {
            Event::Key(key) if matches!(key.kind, KeyEventKind::Press | KeyEventKind::Repeat) => {
                if app.consume_suppressed_enter(&key) {
                    continue;
                }

                if matches!(key.code, KeyCode::Char('c'))
                    && key.modifiers.contains(KeyModifiers::CONTROL)
                {
                    snapshot = session_snapshot(&socket_path)?;
                    app.restore_origin(&socket_path, &snapshot)?;
                    break;
                }

                if matches!(key.code, KeyCode::Esc) && !app.is_modal_open() {
                    snapshot = session_snapshot(&socket_path)?;
                    app.restore_origin(&socket_path, &snapshot)?;
                    break;
                }

                if should_close_picker_on_key(&app, &key) {
                    break;
                }

                let outcome = app.handle_key(&key);
                if let Some(workspace_id) = outcome.confirmed_delete_workspace_id {
                    snapshot = session_snapshot(&socket_path)?;
                    let delete_outcome =
                        app.delete_workspace(&socket_path, &snapshot, &workspace_id)?;
                    if delete_outcome.replaced_picker {
                        break;
                    }
                    snapshot = session_snapshot(&socket_path)?;
                    app.replace_workspaces(snapshot.workspaces.clone(), &snapshot.panes);
                } else if outcome.selection_changed {
                    snapshot = session_snapshot(&socket_path)?;
                    app.follow_selection(&socket_path, &snapshot)?;
                    snapshot = session_snapshot(&socket_path)?;
                    app.replace_workspaces(snapshot.workspaces.clone(), &snapshot.panes);
                } else if outcome.filter_changed {
                    snapshot = session_snapshot(&socket_path)?;
                    app.replace_workspaces(snapshot.workspaces.clone(), &snapshot.panes);
                }
            }
            Event::Resize(_, _) => {}
            _ => {}
        }
    }

    Ok(())
}

fn draw(stdout: &mut Stdout, app: &PickerApp) -> Result<(), String> {
    let (width, height) =
        terminal::size().map_err(|error| format!("failed to query terminal size: {error}"))?;
    let content_height = height.saturating_sub(5) as usize;
    let header = truncate_to_width(
        &format!(
            "{}/{}: move live  /: filter  {}: delete  enter: keep  esc: cancel",
            app.keymap.move_down.label, app.keymap.move_up.label, app.keymap.delete_workspace.label
        ),
        width as usize,
    );

    queue!(stdout, MoveTo(0, 0), Clear(ClearType::All))
        .map_err(|error| format!("failed to clear picker pane: {error}"))?;
    queue!(stdout, Print("Workspaces"), MoveTo(0, 1), Print(header))
        .map_err(|error| format!("failed to draw picker header: {error}"))?;

    draw_filter_box(stdout, app, 0, 2, width)?;
    draw_workspace_list(stdout, app, 0, 5, width, content_height)?;
    if let Some(dialog) = app.delete_confirmation.as_ref() {
        draw_delete_confirmation(stdout, dialog, width, height)?;
    }

    stdout
        .flush()
        .map_err(|error| format!("failed to flush picker output: {error}"))
}

fn should_close_picker_on_key(app: &PickerApp, key: &KeyEvent) -> bool {
    matches!(key.code, KeyCode::Enter)
        && matches!(key.kind, KeyEventKind::Press)
        && !app.is_modal_open()
        && app.selected_workspace_id().is_some()
}

fn draw_filter_box(
    stdout: &mut Stdout,
    app: &PickerApp,
    x: u16,
    y: u16,
    width: u16,
) -> Result<(), String> {
    let total_width = width.max(8) as usize;
    let inner_width = total_width.saturating_sub(2);
    let border_color = if app.search_mode {
        Color::Blue
    } else {
        Color::DarkGrey
    };
    let top = filter_box_top(inner_width, app.search_mode);
    let content = filter_box_content(inner_width, &app.filter_query, app.search_mode);
    let bottom = format!("+{}+", "-".repeat(inner_width));

    queue!(
        stdout,
        MoveTo(x, y),
        SetForegroundColor(border_color),
        Print(top),
        ResetColor,
        MoveTo(x, y + 1),
        SetForegroundColor(border_color),
        Print("|"),
        ResetColor,
        Print(content),
        SetForegroundColor(border_color),
        Print("|"),
        ResetColor,
        MoveTo(x, y + 2),
        SetForegroundColor(border_color),
        Print(bottom),
        ResetColor
    )
    .map_err(|error| format!("failed to draw filter box: {error}"))
}

fn draw_delete_confirmation(
    stdout: &mut Stdout,
    dialog: &DeleteConfirmation,
    width: u16,
    height: u16,
) -> Result<(), String> {
    let dialog_width = width.min(60).max(26);
    let inner_width = dialog_width.saturating_sub(2) as usize;
    let x = width.saturating_sub(dialog_width) / 2;
    let y = height.saturating_sub(5) / 2;
    let title = format!("+{}+", "-".repeat(inner_width));
    let message = truncate_to_width(
        &format!(" Delete workspace \"{}\" ?", dialog.label),
        inner_width,
    );
    let message_line = pad_to_width(message, inner_width);
    let actions = render_delete_actions(dialog, inner_width);
    let footer = pad_to_width(
        " Tab/left-right: switch  Enter: choose  Esc: cancel".to_string(),
        inner_width,
    );

    queue!(
        stdout,
        MoveTo(x, y),
        SetForegroundColor(Color::Red),
        Print(title.clone()),
        ResetColor,
        MoveTo(x, y + 1),
        SetForegroundColor(Color::Red),
        Print("|"),
        ResetColor,
        Print(message_line),
        SetForegroundColor(Color::Red),
        Print("|"),
        ResetColor,
        MoveTo(x, y + 2),
        SetForegroundColor(Color::Red),
        Print("|"),
        ResetColor,
        Print(actions),
        SetForegroundColor(Color::Red),
        Print("|"),
        ResetColor,
        MoveTo(x, y + 3),
        SetForegroundColor(Color::DarkGrey),
        Print("|"),
        ResetColor,
        Print(footer),
        SetForegroundColor(Color::DarkGrey),
        Print("|"),
        ResetColor,
        MoveTo(x, y + 4),
        SetForegroundColor(Color::Red),
        Print(title),
        ResetColor
    )
    .map_err(|error| format!("failed to draw delete confirmation: {error}"))
}

fn render_delete_actions(dialog: &DeleteConfirmation, inner_width: usize) -> String {
    let cancel = if matches!(dialog.choice, ConfirmationChoice::Cancel) {
        "[Cancel]"
    } else {
        " Cancel "
    };
    let ok = if matches!(dialog.choice, ConfirmationChoice::Ok) {
        "[OK]"
    } else {
        " OK "
    };
    pad_to_width(
        truncate_to_width(&format!(" {}   {}", cancel, ok), inner_width),
        inner_width,
    )
}

fn filter_box_top(inner_width: usize, search_mode: bool) -> String {
    let label = if search_mode {
        "[FILTER ACTIVE]"
    } else {
        "[Filter]"
    };
    let body_width = inner_width.saturating_sub(label.chars().count());
    format!("+{}{}+", label, "-".repeat(body_width))
}

fn filter_box_content(inner_width: usize, filter_query: &str, search_mode: bool) -> String {
    let content = if search_mode {
        format!(" /{}_", filter_query)
    } else if filter_query.is_empty() {
        " Press / to filter workspaces".to_string()
    } else {
        format!(" /{}", filter_query)
    };
    pad_to_width(truncate_to_width(&content, inner_width), inner_width)
}

fn pad_to_width(content: String, width: usize) -> String {
    let padding = width.saturating_sub(content.chars().count());
    format!("{}{}", content, " ".repeat(padding))
}

#[derive(Clone)]
struct OriginState {
    workspace_id: String,
    tab_id: String,
    target_pane_id: String,
}

impl OriginState {
    fn from_env(context: &PluginContext, snapshot: &SessionSnapshot) -> Result<Self, String> {
        Ok(Self {
            workspace_id: env_nonempty(ORIGIN_WORKSPACE_ID_ENV)
                .unwrap_or(resolve_current_workspace_id(context, snapshot)?),
            tab_id: env_nonempty(ORIGIN_TAB_ID_ENV)
                .unwrap_or(resolve_current_tab_id(context, snapshot)?),
            target_pane_id: env_nonempty(ORIGIN_PANE_ID_ENV)
                .unwrap_or(resolve_current_pane_id(context, snapshot)?),
        })
    }
}

struct PickerApp {
    all_workspaces: Vec<WorkspaceInfo>,
    workspaces: Vec<WorkspaceInfo>,
    selected: usize,
    picker_pane_id: String,
    host_workspace_id: String,
    host_tab_id: String,
    origin: OriginState,
    keymap: PickerKeymap,
    filter_query: String,
    search_mode: bool,
    delete_confirmation: Option<DeleteConfirmation>,
    suppress_close_on_enter: bool,
}

impl PickerApp {
    fn new(
        workspaces: Vec<WorkspaceInfo>,
        picker_pane_id: String,
        origin: OriginState,
        snapshot: &SessionSnapshot,
        keymap: PickerKeymap,
    ) -> Result<Self, String> {
        let all_workspaces = merge_workspace_agent_statuses(workspaces, &snapshot.panes);
        let picker = snapshot
            .panes
            .iter()
            .find(|pane| pane.pane_id == picker_pane_id)
            .ok_or_else(|| format!("picker pane {picker_pane_id} was not found"))?;
        let selected_workspace_id = all_workspaces
            .iter()
            .find(|workspace| workspace.workspace_id == origin.workspace_id)
            .or_else(|| all_workspaces.iter().find(|workspace| workspace.focused))
            .map(|workspace| workspace.workspace_id.clone());

        let mut app = Self {
            all_workspaces,
            workspaces: Vec::new(),
            selected: 0,
            picker_pane_id,
            host_workspace_id: picker.workspace_id.clone(),
            host_tab_id: picker.tab_id.clone(),
            origin,
            keymap,
            filter_query: String::new(),
            search_mode: false,
            delete_confirmation: None,
            suppress_close_on_enter: false,
        };
        app.rebuild_workspaces(selected_workspace_id.as_deref());
        Ok(app)
    }

    fn is_modal_open(&self) -> bool {
        self.delete_confirmation.is_some()
    }

    fn consume_suppressed_enter(&mut self, key: &KeyEvent) -> bool {
        if !self.suppress_close_on_enter {
            return false;
        }

        if matches!(key.code, KeyCode::Enter) {
            return true;
        }

        self.suppress_close_on_enter = false;
        false
    }

    fn replace_workspaces(&mut self, workspaces: Vec<WorkspaceInfo>, panes: &[PaneInfo]) {
        let selected_workspace_id = self.selected_workspace_id().map(ToOwned::to_owned);
        self.all_workspaces = merge_workspace_agent_statuses(workspaces, panes);
        self.rebuild_workspaces(selected_workspace_id.as_deref());
    }

    fn move_selection(&mut self, delta: isize) -> bool {
        if self.workspaces.is_empty() {
            return false;
        }

        let previous = self.selected;
        let last = self.workspaces.len().saturating_sub(1) as isize;
        let next = (self.selected as isize + delta).clamp(0, last);
        self.selected = next as usize;
        self.selected != previous
    }

    fn selected_workspace_id(&self) -> Option<&str> {
        self.workspaces
            .get(self.selected)
            .map(|workspace| workspace.workspace_id.as_str())
    }

    fn selected_workspace(&self) -> Option<&WorkspaceInfo> {
        self.workspaces.get(self.selected)
    }

    fn sync_state(&self) -> Result<(), String> {
        save_workspace_picker_state(&WorkspacePickerState {
            pane_id: self.picker_pane_id.clone(),
            workspace_id: self.host_workspace_id.clone(),
            tab_id: self.host_tab_id.clone(),
        })
    }

    fn handle_key(&mut self, key: &KeyEvent) -> KeyOutcome {
        if self.delete_confirmation.is_some() {
            return self.handle_delete_confirmation_key(key);
        }

        let previous_selected_workspace_id = self.selected_workspace_id().map(ToOwned::to_owned);
        if self.handle_filter_input(key) {
            let selection_changed = self.selected_workspace_id().map(ToOwned::to_owned)
                != previous_selected_workspace_id;
            return KeyOutcome {
                selection_changed,
                filter_changed: true,
                confirmed_delete_workspace_id: None,
            };
        }

        if self.keymap.delete_workspace.matches(key) {
            self.open_delete_confirmation();
            return KeyOutcome::default();
        }

        if self.keymap.move_up.matches(key) || matches!(key.code, KeyCode::Up) {
            return KeyOutcome {
                selection_changed: self.move_selection(-1),
                filter_changed: false,
                confirmed_delete_workspace_id: None,
            };
        }

        if self.keymap.move_down.matches(key) || matches!(key.code, KeyCode::Down) {
            return KeyOutcome {
                selection_changed: self.move_selection(1),
                filter_changed: false,
                confirmed_delete_workspace_id: None,
            };
        }

        KeyOutcome::default()
    }

    fn handle_delete_confirmation_key(&mut self, key: &KeyEvent) -> KeyOutcome {
        let Some(dialog) = self.delete_confirmation.as_mut() else {
            return KeyOutcome::default();
        };

        match key.code {
            KeyCode::Esc => {
                self.delete_confirmation = None;
                KeyOutcome::default()
            }
            KeyCode::Left | KeyCode::Char('h') | KeyCode::BackTab => {
                dialog.choice = ConfirmationChoice::Cancel;
                KeyOutcome::default()
            }
            KeyCode::Right | KeyCode::Char('l') | KeyCode::Tab => {
                dialog.choice = ConfirmationChoice::Ok;
                KeyOutcome::default()
            }
            KeyCode::Char('c') if normalize_modifiers(key.modifiers).is_empty() => {
                dialog.choice = ConfirmationChoice::Cancel;
                KeyOutcome::default()
            }
            KeyCode::Char('o') if normalize_modifiers(key.modifiers).is_empty() => {
                dialog.choice = ConfirmationChoice::Ok;
                KeyOutcome::default()
            }
            KeyCode::Enter => {
                let confirmed = matches!(dialog.choice, ConfirmationChoice::Ok);
                let workspace_id = dialog.workspace_id.clone();
                self.delete_confirmation = None;
                if confirmed {
                    self.suppress_close_on_enter = true;
                    KeyOutcome {
                        selection_changed: false,
                        filter_changed: false,
                        confirmed_delete_workspace_id: Some(workspace_id),
                    }
                } else {
                    KeyOutcome::default()
                }
            }
            _ => KeyOutcome::default(),
        }
    }

    fn open_delete_confirmation(&mut self) {
        let Some(workspace) = self.selected_workspace() else {
            return;
        };
        self.delete_confirmation = Some(DeleteConfirmation {
            workspace_id: workspace.workspace_id.clone(),
            label: workspace.label.clone(),
            choice: ConfirmationChoice::Cancel,
        });
    }

    fn handle_filter_input(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            KeyCode::Char('/') if normalize_modifiers(key.modifiers).is_empty() => {
                self.search_mode = true;
                false
            }
            KeyCode::Backspace
                if self.search_mode && normalize_modifiers(key.modifiers).is_empty() =>
            {
                if self.filter_query.pop().is_some() {
                    self.rebuild_workspaces(None);
                    true
                } else {
                    false
                }
            }
            KeyCode::Char('u')
                if self.search_mode
                    && normalize_modifiers(key.modifiers) == KeyModifiers::CONTROL =>
            {
                if self.filter_query.is_empty() {
                    false
                } else {
                    self.filter_query.clear();
                    self.rebuild_workspaces(None);
                    true
                }
            }
            KeyCode::Char(character)
                if self.search_mode
                    && !normalize_modifiers(key.modifiers).contains(KeyModifiers::CONTROL)
                    && !normalize_modifiers(key.modifiers).contains(KeyModifiers::ALT)
                    && !normalize_modifiers(key.modifiers).contains(KeyModifiers::SUPER) =>
            {
                self.filter_query.push(character);
                self.rebuild_workspaces(None);
                true
            }
            _ => false,
        }
    }

    fn follow_selection(
        &mut self,
        socket_path: &str,
        snapshot: &SessionSnapshot,
    ) -> Result<(), String> {
        let Some(selected_workspace_id) = self.selected_workspace_id().map(ToOwned::to_owned)
        else {
            return Ok(());
        };

        if selected_workspace_id != self.host_workspace_id {
            let destination = resolve_workspace_destination(
                snapshot,
                &selected_workspace_id,
                None,
                None,
                Some(&self.picker_pane_id),
            )?;
            self.move_picker(socket_path, &destination)?;
        }

        workspace_focus(socket_path, &selected_workspace_id)?;
        let _ = plugin_pane_focus(socket_path, &self.picker_pane_id);
        Ok(())
    }

    fn delete_workspace(
        &mut self,
        socket_path: &str,
        snapshot: &SessionSnapshot,
        workspace_id: &str,
    ) -> Result<DeleteWorkspaceOutcome, String> {
        let fallback = resolve_delete_destination(
            snapshot,
            workspace_id,
            &self.origin.workspace_id,
            &self.picker_pane_id,
        )?;

        if self.origin.workspace_id == workspace_id {
            self.origin.workspace_id = fallback.workspace_id.clone();
            self.origin.tab_id = fallback.tab_id.clone();
            self.origin.target_pane_id = fallback.target_pane_id.clone();
        }

        if self.host_workspace_id == workspace_id {
            self.schedule_reopen_picker(socket_path, &fallback)?;
            workspace_focus(socket_path, &fallback.workspace_id)?;
            let _ = workspace_close(socket_path, workspace_id)?;
            return Ok(DeleteWorkspaceOutcome {
                replaced_picker: true,
            });
        }

        workspace_focus(socket_path, &fallback.workspace_id)?;
        let _ = workspace_close(socket_path, workspace_id)?;
        let _ = plugin_pane_focus(socket_path, &self.picker_pane_id);
        Ok(DeleteWorkspaceOutcome {
            replaced_picker: false,
        })
    }

    fn restore_origin(
        &mut self,
        socket_path: &str,
        snapshot: &SessionSnapshot,
    ) -> Result<(), String> {
        let destination = resolve_workspace_destination(
            snapshot,
            &self.origin.workspace_id,
            Some(&self.origin.tab_id),
            Some(&self.origin.target_pane_id),
            Some(&self.picker_pane_id),
        )?;

        if destination.workspace_id != self.host_workspace_id
            || destination.tab_id != self.host_tab_id
        {
            self.move_picker(socket_path, &destination)?;
        }

        workspace_focus(socket_path, &self.origin.workspace_id)?;
        Ok(())
    }

    fn move_picker(
        &mut self,
        socket_path: &str,
        destination: &WorkspaceDestination,
    ) -> Result<(), String> {
        let move_result = pane_move_to_tab_split(
            socket_path,
            &self.picker_pane_id,
            &destination.tab_id,
            &destination.target_pane_id,
            SplitDirection::Right,
            true,
        )?;
        self.picker_pane_id = move_result.pane.pane_id.clone();
        self.host_workspace_id = move_result.pane.workspace_id.clone();
        self.host_tab_id = move_result.pane.tab_id.clone();
        self.sync_state()?;

        let _ = pane_swap(
            socket_path,
            &self.picker_pane_id,
            &destination.target_pane_id,
        );
        let _ = plugin_pane_focus(socket_path, &self.picker_pane_id);
        Ok(())
    }

    fn schedule_reopen_picker(
        &self,
        socket_path: &str,
        destination: &WorkspaceDestination,
    ) -> Result<(), String> {
        let plugin_id = env_nonempty("HERDR_PLUGIN_ID")
            .ok_or_else(|| "HERDR_PLUGIN_ID is missing".to_string())?;
        let helper_path = std::env::current_exe()
            .map_err(|error| format!("failed to resolve current executable path: {error}"))?
            .with_file_name("workspace-picker-reopen");

        let mut command = Command::new(&helper_path);
        command
            .arg("--socket-path")
            .arg(socket_path)
            .arg("--plugin-id")
            .arg(plugin_id)
            .arg("--target-pane-id")
            .arg(&destination.target_pane_id)
            .arg("--origin-pane-id")
            .arg(&self.origin.target_pane_id)
            .arg("--origin-tab-id")
            .arg(&self.origin.tab_id)
            .arg("--origin-workspace-id")
            .arg(&self.origin.workspace_id)
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null());

        unsafe {
            command.pre_exec(|| {
                if libc::setsid() == -1 {
                    return Err(std::io::Error::last_os_error());
                }
                if libc::signal(libc::SIGHUP, libc::SIG_IGN) == libc::SIG_ERR {
                    return Err(std::io::Error::last_os_error());
                }
                Ok(())
            });
        }

        command
            .spawn()
            .map(|_| ())
            .map_err(|error| format!("failed to spawn workspace picker reopen helper: {error}"))
    }

    fn rebuild_workspaces(&mut self, preferred_workspace_id: Option<&str>) {
        let focused_workspace_id = self
            .all_workspaces
            .iter()
            .find(|workspace| workspace.focused)
            .map(|workspace| workspace.workspace_id.clone());
        let previous_workspace_id = preferred_workspace_id
            .map(ToOwned::to_owned)
            .or_else(|| self.selected_workspace_id().map(ToOwned::to_owned))
            .or(focused_workspace_id);
        let query = self.filter_query.to_lowercase();

        self.workspaces = self
            .all_workspaces
            .iter()
            .filter(|workspace| {
                query.is_empty() || workspace.label.to_lowercase().contains(query.as_str())
            })
            .cloned()
            .collect();

        self.selected = previous_workspace_id
            .as_deref()
            .and_then(|workspace_id| {
                self.workspaces
                    .iter()
                    .position(|workspace| workspace.workspace_id == workspace_id)
            })
            .unwrap_or(0)
            .min(self.workspaces.len().saturating_sub(1));
    }
}

#[derive(Default)]
struct KeyOutcome {
    selection_changed: bool,
    filter_changed: bool,
    confirmed_delete_workspace_id: Option<String>,
}

struct DeleteWorkspaceOutcome {
    replaced_picker: bool,
}

#[derive(Clone)]
struct PickerKeymap {
    move_up: PickerKeyBinding,
    move_down: PickerKeyBinding,
    delete_workspace: PickerKeyBinding,
}

impl PickerKeymap {
    fn load() -> Self {
        let bindings = match load_workspace_picker_bindings() {
            Ok(bindings) => bindings,
            Err(error) => {
                eprintln!("{error}");
                WorkspacePickerBindings::default()
            }
        };

        Self {
            move_up: PickerKeyBinding::parse(&bindings.move_up).unwrap_or_else(|error| {
                eprintln!("{error}");
                PickerKeyBinding::default_up()
            }),
            move_down: PickerKeyBinding::parse(&bindings.move_down).unwrap_or_else(|error| {
                eprintln!("{error}");
                PickerKeyBinding::default_down()
            }),
            delete_workspace: PickerKeyBinding::parse(&bindings.delete_workspace).unwrap_or_else(
                |error| {
                    eprintln!("{error}");
                    PickerKeyBinding::default_delete()
                },
            ),
        }
    }

    #[cfg(test)]
    fn defaults() -> Self {
        Self {
            move_up: PickerKeyBinding::default_up(),
            move_down: PickerKeyBinding::default_down(),
            delete_workspace: PickerKeyBinding::default_delete(),
        }
    }
}

#[derive(Clone)]
struct PickerKeyBinding {
    code: KeyCode,
    modifiers: KeyModifiers,
    label: String,
}

impl PickerKeyBinding {
    fn parse(raw: &str) -> Result<Self, String> {
        let mut modifiers = KeyModifiers::empty();
        let mut key_code = None;

        for part in raw.split('+').map(|part| part.trim().to_lowercase()) {
            match part.as_str() {
                "" => {}
                "ctrl" | "control" => modifiers |= KeyModifiers::CONTROL,
                "alt" => modifiers |= KeyModifiers::ALT,
                "shift" => modifiers |= KeyModifiers::SHIFT,
                "cmd" | "super" => modifiers |= KeyModifiers::SUPER,
                "up" => key_code = Some(KeyCode::Up),
                "down" => key_code = Some(KeyCode::Down),
                "left" => key_code = Some(KeyCode::Left),
                "right" => key_code = Some(KeyCode::Right),
                "tab" => key_code = Some(KeyCode::Tab),
                value if value.chars().count() == 1 => {
                    key_code = Some(KeyCode::Char(value.chars().next().unwrap()))
                }
                _ => return Err(format!("unsupported workspace picker key binding: {raw}")),
            }
        }

        let code =
            key_code.ok_or_else(|| format!("workspace picker key binding has no key: {raw}"))?;

        Ok(Self {
            code,
            modifiers,
            label: raw.to_string(),
        })
    }

    fn default_up() -> Self {
        Self::parse("k").expect("default up key should parse")
    }

    fn default_down() -> Self {
        Self::parse("j").expect("default down key should parse")
    }

    fn default_delete() -> Self {
        Self::parse("ctrl+d").expect("default delete key should parse")
    }

    fn matches(&self, key: &KeyEvent) -> bool {
        key.code == self.code && normalize_modifiers(key.modifiers) == self.modifiers
    }
}

fn normalize_modifiers(modifiers: KeyModifiers) -> KeyModifiers {
    modifiers
        & (KeyModifiers::CONTROL | KeyModifiers::ALT | KeyModifiers::SHIFT | KeyModifiers::SUPER)
}

#[derive(Clone)]
struct DeleteConfirmation {
    workspace_id: String,
    label: String,
    choice: ConfirmationChoice,
}

#[derive(Clone, Copy)]
enum ConfirmationChoice {
    Cancel,
    Ok,
}

struct WorkspaceDestination {
    workspace_id: String,
    tab_id: String,
    target_pane_id: String,
}

fn resolve_delete_destination(
    snapshot: &SessionSnapshot,
    deleting_workspace_id: &str,
    preferred_workspace_id: &str,
    exclude_pane_id: &str,
) -> Result<WorkspaceDestination, String> {
    if snapshot.workspaces.len() <= 1 {
        return Err("cannot delete the last workspace".to_string());
    }

    let fallback_workspace_id = if preferred_workspace_id != deleting_workspace_id
        && snapshot
            .workspaces
            .iter()
            .any(|workspace| workspace.workspace_id == preferred_workspace_id)
    {
        preferred_workspace_id.to_string()
    } else {
        snapshot
            .workspaces
            .iter()
            .find(|workspace| workspace.workspace_id != deleting_workspace_id)
            .map(|workspace| workspace.workspace_id.clone())
            .ok_or_else(|| "no fallback workspace is available".to_string())?
    };

    resolve_workspace_destination(
        snapshot,
        &fallback_workspace_id,
        None,
        None,
        Some(exclude_pane_id),
    )
}

fn resolve_workspace_destination(
    snapshot: &SessionSnapshot,
    workspace_id: &str,
    preferred_tab_id: Option<&str>,
    preferred_pane_id: Option<&str>,
    exclude_pane_id: Option<&str>,
) -> Result<WorkspaceDestination, String> {
    if let Some(pane_id) = preferred_pane_id {
        if let Some(pane) = snapshot.panes.iter().find(|pane| {
            pane.pane_id == pane_id
                && pane.workspace_id == workspace_id
                && Some(pane.pane_id.as_str()) != exclude_pane_id
        }) {
            return Ok(WorkspaceDestination {
                workspace_id: pane.workspace_id.clone(),
                tab_id: pane.tab_id.clone(),
                target_pane_id: pane.pane_id.clone(),
            });
        }
    }

    let workspace = snapshot
        .workspaces
        .iter()
        .find(|workspace| workspace.workspace_id == workspace_id)
        .ok_or_else(|| format!("workspace {workspace_id} was not found"))?;

    let mut candidate_tab_ids = Vec::new();
    if let Some(tab_id) = preferred_tab_id {
        candidate_tab_ids.push(tab_id.to_string());
    }
    if !candidate_tab_ids
        .iter()
        .any(|tab_id| tab_id == &workspace.active_tab_id)
    {
        candidate_tab_ids.push(workspace.active_tab_id.clone());
    }

    for tab_id in &candidate_tab_ids {
        if let Some(pane_id) = snapshot
            .layouts
            .iter()
            .find(|layout| layout.workspace_id == workspace_id && layout.tab_id == *tab_id)
            .map(|layout| layout.focused_pane_id.as_str())
        {
            if let Some(pane) = select_pane(snapshot, pane_id, workspace_id, exclude_pane_id) {
                return Ok(WorkspaceDestination {
                    workspace_id: pane.workspace_id.clone(),
                    tab_id: pane.tab_id.clone(),
                    target_pane_id: pane.pane_id.clone(),
                });
            }
        }

        if let Some(pane) = snapshot.panes.iter().find(|pane| {
            pane.workspace_id == workspace_id
                && pane.tab_id == *tab_id
                && Some(pane.pane_id.as_str()) != exclude_pane_id
        }) {
            return Ok(WorkspaceDestination {
                workspace_id: pane.workspace_id.clone(),
                tab_id: pane.tab_id.clone(),
                target_pane_id: pane.pane_id.clone(),
            });
        }
    }

    if let Some(pane) = snapshot.panes.iter().find(|pane| {
        pane.workspace_id == workspace_id && Some(pane.pane_id.as_str()) != exclude_pane_id
    }) {
        return Ok(WorkspaceDestination {
            workspace_id: pane.workspace_id.clone(),
            tab_id: pane.tab_id.clone(),
            target_pane_id: pane.pane_id.clone(),
        });
    }

    Err(format!(
        "no destination pane is available in workspace {workspace_id}"
    ))
}

fn select_pane<'a>(
    snapshot: &'a SessionSnapshot,
    pane_id: &str,
    workspace_id: &str,
    exclude_pane_id: Option<&str>,
) -> Option<&'a PaneInfo> {
    snapshot.panes.iter().find(|pane| {
        pane.pane_id == pane_id
            && pane.workspace_id == workspace_id
            && Some(pane.pane_id.as_str()) != exclude_pane_id
    })
}

fn draw_workspace_list(
    stdout: &mut Stdout,
    app: &PickerApp,
    x: u16,
    y: u16,
    width: u16,
    height: usize,
) -> Result<(), String> {
    if app.workspaces.is_empty() {
        queue!(stdout, MoveTo(x, y), Print("No matching workspaces"))
            .map_err(|error| format!("failed to draw empty workspace state: {error}"))?;
        return Ok(());
    }

    let selected = app.selected.min(app.workspaces.len().saturating_sub(1));
    let start = selected.saturating_sub(height.saturating_sub(1));
    let end = (start + height).min(app.workspaces.len());

    for (row, workspace) in app.workspaces[start..end].iter().enumerate() {
        let row_y = y + row as u16;
        let marker = if start + row == selected { ">" } else { " " };
        let focused = if workspace.focused { "*" } else { " " };
        let prefix = format!("{}{}", marker, focused);
        let agent = workspace_agent_mark(workspace).to_string();
        let suffix = format!(" {:>2}  {}", workspace.number, workspace.label);
        let total_width = width as usize;
        let prefix_text = truncate_to_width(&prefix, total_width);
        let prefix_width = prefix_text.chars().count();
        let agent_width = total_width.saturating_sub(prefix_width).min(1);
        let suffix_width = total_width
            .saturating_sub(prefix_width)
            .saturating_sub(agent_width);

        queue!(stdout, MoveTo(x, row_y))
            .map_err(|error| format!("failed to position workspace row: {error}"))?;
        if start + row == selected {
            queue!(stdout, SetAttribute(Attribute::Reverse))
                .map_err(|error| format!("failed to set selection style: {error}"))?;
        }
        queue!(stdout, Print(prefix_text))
            .map_err(|error| format!("failed to draw workspace prefix: {error}"))?;
        if agent_width > 0 {
            if let Some(color) = workspace_agent_color(workspace) {
                queue!(stdout, SetForegroundColor(color))
                    .map_err(|error| format!("failed to set agent mark color: {error}"))?;
            }
            queue!(
                stdout,
                Print(truncate_to_width(&agent, agent_width)),
                ResetColor
            )
            .map_err(|error| format!("failed to draw workspace agent mark: {error}"))?;
        }
        queue!(
            stdout,
            Print(truncate_to_width(&suffix, suffix_width)),
            ResetColor,
            SetAttribute(Attribute::Reset)
        )
        .map_err(|error| format!("failed to draw workspace row: {error}"))?;
    }

    Ok(())
}

fn workspace_agent_mark(workspace: &WorkspaceInfo) -> char {
    match workspace.agent_status.as_str() {
        "working" | "idle" | "blocked" | "agent_unknown" => '●',
        _ => ' ',
    }
}

fn workspace_agent_color(workspace: &WorkspaceInfo) -> Option<Color> {
    match workspace.agent_status.as_str() {
        "working" => Some(Color::Yellow),
        "idle" => Some(Color::Green),
        "blocked" => Some(Color::Red),
        "agent_unknown" => Some(Color::Grey),
        _ => None,
    }
}

fn merge_workspace_agent_statuses(
    mut workspaces: Vec<WorkspaceInfo>,
    panes: &[PaneInfo],
) -> Vec<WorkspaceInfo> {
    let statuses = collect_workspace_agent_statuses(panes);
    for workspace in &mut workspaces {
        workspace.agent_status = statuses
            .get(&workspace.workspace_id)
            .cloned()
            .unwrap_or_else(|| "unknown".to_string());
    }
    workspaces
}

fn collect_workspace_agent_statuses(panes: &[PaneInfo]) -> BTreeMap<String, String> {
    let mut statuses: BTreeMap<String, String> = BTreeMap::new();
    for pane in panes {
        let Some(status) = pane_agent_status(pane) else {
            continue;
        };

        statuses
            .entry(pane.workspace_id.clone())
            .and_modify(|current| {
                if agent_status_priority(&status) > agent_status_priority(current) {
                    *current = status.clone();
                }
            })
            .or_insert(status);
    }
    statuses
}

fn pane_agent_status(pane: &PaneInfo) -> Option<String> {
    if pane.agent.is_some() {
        if pane.agent_status == "unknown" {
            Some("agent_unknown".to_string())
        } else {
            Some(pane.agent_status.clone())
        }
    } else {
        None
    }
}

fn agent_status_priority(status: &str) -> usize {
    match status {
        "blocked" => 4,
        "working" => 3,
        "idle" => 2,
        "agent_unknown" => 1,
        _ => 0,
    }
}

fn truncate_to_width(line: &str, width: usize) -> String {
    line.chars().take(width).collect()
}

struct TerminalSession {
    stdout: Stdout,
}

impl TerminalSession {
    fn enter() -> Result<Self, String> {
        let mut stdout = stdout();
        enable_raw_mode().map_err(|error| format!("failed to enable raw mode: {error}"))?;
        if let Err(error) = execute!(stdout, EnterAlternateScreen, Hide) {
            let _ = disable_raw_mode();
            return Err(format!("failed to enter alternate screen: {error}"));
        }

        Ok(Self { stdout })
    }
}

impl Drop for TerminalSession {
    fn drop(&mut self) {
        let _ = execute!(self.stdout, Show, LeaveAlternateScreen);
        let _ = disable_raw_mode();
    }
}

#[cfg(test)]
mod tests {
    use super::{
        filter_box_content, filter_box_top, merge_workspace_agent_statuses, normalize_modifiers,
        render_delete_actions, resolve_delete_destination, resolve_workspace_destination,
        should_close_picker_on_key, workspace_agent_color, workspace_agent_mark,
        ConfirmationChoice, DeleteConfirmation, OriginState, PickerApp, PickerKeyBinding,
        PickerKeymap,
    };
    use crossterm::event::{KeyCode, KeyEvent, KeyEventKind, KeyEventState, KeyModifiers};
    use crossterm::style::Color;
    use tab_move::{PaneInfo, SessionSnapshot, WorkspaceInfo};

    #[test]
    fn destination_prefers_layout_focused_pane() {
        let snapshot = SessionSnapshot {
            focused_pane_id: Some("picker".into()),
            focused_tab_id: Some("w1:t1".into()),
            focused_workspace_id: Some("w1".into()),
            workspaces: vec![WorkspaceInfo {
                workspace_id: "w2".into(),
                number: 2,
                label: "two".into(),
                focused: false,
                pane_count: 2,
                tab_count: 1,
                active_tab_id: "w2:t1".into(),
                agent_status: "unknown".into(),
            }],
            layouts: vec![tab_move::LayoutInfo {
                workspace_id: "w2".into(),
                tab_id: "w2:t1".into(),
                focused_pane_id: "w2:p9".into(),
            }],
            panes: vec![
                PaneInfo {
                    pane_id: "picker".into(),
                    workspace_id: "w1".into(),
                    tab_id: "w1:t1".into(),
                    cwd: None,
                    foreground_cwd: None,
                    agent: None,
                    agent_status: "unknown".into(),
                },
                PaneInfo {
                    pane_id: "w2:p9".into(),
                    workspace_id: "w2".into(),
                    tab_id: "w2:t1".into(),
                    cwd: None,
                    foreground_cwd: None,
                    agent: None,
                    agent_status: "unknown".into(),
                },
            ],
        };

        let destination =
            resolve_workspace_destination(&snapshot, "w2", None, None, Some("picker")).unwrap();

        assert_eq!(destination.target_pane_id, "w2:p9");
        assert_eq!(destination.tab_id, "w2:t1");
    }

    #[test]
    fn delete_destination_prefers_origin_when_available() {
        let snapshot = SessionSnapshot {
            focused_pane_id: Some("picker".into()),
            focused_tab_id: Some("w2:t1".into()),
            focused_workspace_id: Some("w2".into()),
            workspaces: vec![
                WorkspaceInfo {
                    workspace_id: "w1".into(),
                    number: 1,
                    label: "one".into(),
                    focused: false,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w1:t1".into(),
                    agent_status: "unknown".into(),
                },
                WorkspaceInfo {
                    workspace_id: "w2".into(),
                    number: 2,
                    label: "two".into(),
                    focused: true,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w2:t1".into(),
                    agent_status: "unknown".into(),
                },
            ],
            layouts: vec![],
            panes: vec![
                PaneInfo {
                    pane_id: "w1:p1".into(),
                    workspace_id: "w1".into(),
                    tab_id: "w1:t1".into(),
                    cwd: None,
                    foreground_cwd: None,
                    agent: None,
                    agent_status: "unknown".into(),
                },
                PaneInfo {
                    pane_id: "picker".into(),
                    workspace_id: "w2".into(),
                    tab_id: "w2:t1".into(),
                    cwd: None,
                    foreground_cwd: None,
                    agent: None,
                    agent_status: "unknown".into(),
                },
            ],
        };

        let destination = resolve_delete_destination(&snapshot, "w2", "w1", "picker").unwrap();

        assert_eq!(destination.workspace_id, "w1");
    }

    #[test]
    fn picker_preserves_selected_workspace_when_refreshing() {
        let mut app = PickerApp {
            all_workspaces: vec![],
            workspaces: vec![
                WorkspaceInfo {
                    workspace_id: "w1".into(),
                    number: 1,
                    label: "one".into(),
                    focused: true,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w1:t1".into(),
                    agent_status: "unknown".into(),
                },
                WorkspaceInfo {
                    workspace_id: "w2".into(),
                    number: 2,
                    label: "two".into(),
                    focused: false,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w2:t1".into(),
                    agent_status: "unknown".into(),
                },
            ],
            selected: 1,
            picker_pane_id: "picker".into(),
            host_workspace_id: "w2".into(),
            host_tab_id: "w2:t1".into(),
            origin: OriginState {
                workspace_id: "w1".into(),
                tab_id: "w1:t1".into(),
                target_pane_id: "w1:p1".into(),
            },
            keymap: PickerKeymap::defaults(),
            filter_query: String::new(),
            search_mode: false,
            delete_confirmation: None,
            suppress_close_on_enter: false,
        };

        app.replace_workspaces(
            vec![
                WorkspaceInfo {
                    workspace_id: "w1".into(),
                    number: 1,
                    label: "one".into(),
                    focused: false,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w1:t1".into(),
                    agent_status: "unknown".into(),
                },
                WorkspaceInfo {
                    workspace_id: "w2".into(),
                    number: 2,
                    label: "two".into(),
                    focused: true,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w2:t1".into(),
                    agent_status: "unknown".into(),
                },
            ],
            &[],
        );

        assert_eq!(app.selected_workspace_id(), Some("w2"));
    }

    #[test]
    fn workspace_agent_mark_is_visible_for_agent_workspace() {
        assert_eq!(
            workspace_agent_mark(&WorkspaceInfo {
                workspace_id: "w1".into(),
                number: 1,
                label: "one".into(),
                focused: false,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w1:t1".into(),
                agent_status: "working".into(),
            }),
            '●'
        );
        assert_eq!(
            workspace_agent_mark(&WorkspaceInfo {
                workspace_id: "w2".into(),
                number: 2,
                label: "two".into(),
                focused: false,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w2:t1".into(),
                agent_status: "unknown".into(),
            }),
            ' '
        );
    }

    #[test]
    fn workspace_agent_color_matches_status() {
        assert_eq!(
            workspace_agent_color(&WorkspaceInfo {
                workspace_id: "w1".into(),
                number: 1,
                label: "one".into(),
                focused: false,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w1:t1".into(),
                agent_status: "working".into(),
            }),
            Some(Color::Yellow)
        );
        assert_eq!(
            workspace_agent_color(&WorkspaceInfo {
                workspace_id: "w2".into(),
                number: 2,
                label: "two".into(),
                focused: false,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w2:t1".into(),
                agent_status: "idle".into(),
            }),
            Some(Color::Green)
        );
        assert_eq!(
            workspace_agent_color(&WorkspaceInfo {
                workspace_id: "w3".into(),
                number: 3,
                label: "three".into(),
                focused: false,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w3:t1".into(),
                agent_status: "blocked".into(),
            }),
            Some(Color::Red)
        );
        assert_eq!(
            workspace_agent_color(&WorkspaceInfo {
                workspace_id: "w4".into(),
                number: 4,
                label: "four".into(),
                focused: false,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w4:t1".into(),
                agent_status: "unknown".into(),
            }),
            None
        );
    }

    #[test]
    fn merge_workspace_agent_statuses_prefers_agent_panes_over_workspace_snapshot() {
        let workspaces = merge_workspace_agent_statuses(
            vec![
                WorkspaceInfo {
                    workspace_id: "w1".into(),
                    number: 1,
                    label: "one".into(),
                    focused: false,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w1:t1".into(),
                    agent_status: "unknown".into(),
                },
                WorkspaceInfo {
                    workspace_id: "w2".into(),
                    number: 2,
                    label: "two".into(),
                    focused: false,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w2:t1".into(),
                    agent_status: "unknown".into(),
                },
            ],
            &[
                PaneInfo {
                    pane_id: "w1:p1".into(),
                    workspace_id: "w1".into(),
                    tab_id: "w1:t1".into(),
                    cwd: None,
                    foreground_cwd: None,
                    agent: Some("codex".into()),
                    agent_status: "working".into(),
                },
                PaneInfo {
                    pane_id: "w2:p1".into(),
                    workspace_id: "w2".into(),
                    tab_id: "w2:t1".into(),
                    cwd: None,
                    foreground_cwd: None,
                    agent: Some("codex".into()),
                    agent_status: "unknown".into(),
                },
            ],
        );

        assert_eq!(workspaces[0].agent_status, "working");
        assert_eq!(workspaces[1].agent_status, "agent_unknown");
    }

    #[test]
    fn filter_query_reduces_workspace_list_by_label() {
        let mut app = PickerApp {
            all_workspaces: vec![
                WorkspaceInfo {
                    workspace_id: "w1".into(),
                    number: 1,
                    label: "dotfiles".into(),
                    focused: true,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w1:t1".into(),
                    agent_status: "unknown".into(),
                },
                WorkspaceInfo {
                    workspace_id: "w2".into(),
                    number: 2,
                    label: "bff".into(),
                    focused: false,
                    pane_count: 1,
                    tab_count: 1,
                    active_tab_id: "w2:t1".into(),
                    agent_status: "unknown".into(),
                },
            ],
            workspaces: vec![],
            selected: 0,
            picker_pane_id: "picker".into(),
            host_workspace_id: "w1".into(),
            host_tab_id: "w1:t1".into(),
            origin: OriginState {
                workspace_id: "w1".into(),
                tab_id: "w1:t1".into(),
                target_pane_id: "w1:p1".into(),
            },
            keymap: PickerKeymap::defaults(),
            filter_query: String::new(),
            search_mode: false,
            delete_confirmation: None,
            suppress_close_on_enter: false,
        };
        app.rebuild_workspaces(Some("w1"));

        assert!(
            !app.handle_key(&KeyEvent::new(KeyCode::Char('/'), KeyModifiers::empty()))
                .selection_changed
        );
        let outcome = app.handle_key(&KeyEvent::new(KeyCode::Char('b'), KeyModifiers::empty()));
        assert!(outcome.filter_changed);
        assert!(outcome.selection_changed);

        assert_eq!(app.workspaces.len(), 1);
        assert_eq!(app.selected_workspace_id(), Some("w2"));
    }

    #[test]
    fn configurable_key_binding_matches_ctrl_j() {
        let binding = PickerKeyBinding::parse("ctrl+j").expect("binding should parse");

        assert!(binding.matches(&KeyEvent::new(KeyCode::Char('j'), KeyModifiers::CONTROL)));
        assert!(!binding.matches(&KeyEvent::new(KeyCode::Char('j'), KeyModifiers::empty())));
        assert_eq!(
            normalize_modifiers(KeyModifiers::CONTROL | KeyModifiers::SHIFT),
            KeyModifiers::CONTROL | KeyModifiers::SHIFT
        );
    }

    #[test]
    fn filter_box_reflects_active_search_state() {
        assert_eq!(filter_box_top(18, true), "+[FILTER ACTIVE]---+");
        assert_eq!(filter_box_top(18, false), "+[Filter]----------+");
        assert_eq!(filter_box_content(18, "bff", true), " /bff_            ");
        assert_eq!(filter_box_content(18, "", false), " Press / to filter");
    }

    #[test]
    fn ctrl_d_opens_delete_confirmation() {
        let mut app = PickerApp {
            all_workspaces: vec![],
            workspaces: vec![WorkspaceInfo {
                workspace_id: "w1".into(),
                number: 1,
                label: "dotfiles".into(),
                focused: true,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w1:t1".into(),
                agent_status: "unknown".into(),
            }],
            selected: 0,
            picker_pane_id: "picker".into(),
            host_workspace_id: "w1".into(),
            host_tab_id: "w1:t1".into(),
            origin: OriginState {
                workspace_id: "w1".into(),
                tab_id: "w1:t1".into(),
                target_pane_id: "w1:p1".into(),
            },
            keymap: PickerKeymap::defaults(),
            filter_query: String::new(),
            search_mode: false,
            delete_confirmation: None,
            suppress_close_on_enter: false,
        };

        let outcome = app.handle_key(&KeyEvent::new(KeyCode::Char('d'), KeyModifiers::CONTROL));

        assert!(!outcome.selection_changed);
        assert!(app.is_modal_open());
    }

    #[test]
    fn delete_confirmation_requires_ok_choice() {
        let dialog = DeleteConfirmation {
            workspace_id: "w1".into(),
            label: "dotfiles".into(),
            choice: ConfirmationChoice::Cancel,
        };

        assert_eq!(render_delete_actions(&dialog, 22), " [Cancel]    OK       ");
    }

    #[test]
    fn enter_repeat_does_not_close_picker_after_delete_confirmation() {
        let app = PickerApp {
            all_workspaces: vec![],
            workspaces: vec![WorkspaceInfo {
                workspace_id: "w1".into(),
                number: 1,
                label: "dotfiles".into(),
                focused: true,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w1:t1".into(),
                agent_status: "unknown".into(),
            }],
            selected: 0,
            picker_pane_id: "picker".into(),
            host_workspace_id: "w1".into(),
            host_tab_id: "w1:t1".into(),
            origin: OriginState {
                workspace_id: "w1".into(),
                tab_id: "w1:t1".into(),
                target_pane_id: "w1:p1".into(),
            },
            keymap: PickerKeymap::defaults(),
            filter_query: String::new(),
            search_mode: false,
            delete_confirmation: None,
            suppress_close_on_enter: false,
        };
        let repeat_enter = KeyEvent {
            code: KeyCode::Enter,
            modifiers: KeyModifiers::empty(),
            kind: KeyEventKind::Repeat,
            state: KeyEventState::empty(),
        };

        assert!(!should_close_picker_on_key(&app, &repeat_enter));
    }

    #[test]
    fn confirmed_delete_suppresses_following_enter_until_other_key() {
        let mut app = PickerApp {
            all_workspaces: vec![],
            workspaces: vec![WorkspaceInfo {
                workspace_id: "w1".into(),
                number: 1,
                label: "dotfiles".into(),
                focused: true,
                pane_count: 1,
                tab_count: 1,
                active_tab_id: "w1:t1".into(),
                agent_status: "unknown".into(),
            }],
            selected: 0,
            picker_pane_id: "picker".into(),
            host_workspace_id: "w1".into(),
            host_tab_id: "w1:t1".into(),
            origin: OriginState {
                workspace_id: "w1".into(),
                tab_id: "w1:t1".into(),
                target_pane_id: "w1:p1".into(),
            },
            keymap: PickerKeymap::defaults(),
            filter_query: String::new(),
            search_mode: false,
            delete_confirmation: Some(DeleteConfirmation {
                workspace_id: "w1".into(),
                label: "dotfiles".into(),
                choice: ConfirmationChoice::Ok,
            }),
            suppress_close_on_enter: false,
        };

        let outcome = app.handle_key(&KeyEvent::new(KeyCode::Enter, KeyModifiers::empty()));

        assert_eq!(outcome.confirmed_delete_workspace_id.as_deref(), Some("w1"));
        assert!(app.consume_suppressed_enter(&KeyEvent::new(KeyCode::Enter, KeyModifiers::empty())));
        assert!(app.suppress_close_on_enter);
        assert!(!app
            .consume_suppressed_enter(&KeyEvent::new(KeyCode::Char('j'), KeyModifiers::empty())));
        assert!(!app.suppress_close_on_enter);
    }
}
