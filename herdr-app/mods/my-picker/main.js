// Switch spaces. All spaces in sidebar order; type to filter, ↑/↓ (ctrl+j/k)
// and Enter to switch, Esc to leave. ctrl+h/ctrl+l (←/→) move between the
// space list and the tab tree: in the tree ↑/↓ pick a single tab and Enter
// switches to it. The shown space follows the selection live; leaving without
// Enter comes back to where you were. Last rows: a new space on this computer
// or on each connected machine.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, panes, run, hc, theme, settings, props, closeOverlay, shared, setShared } from "herdr";

const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// Space colors, kept by space id in shared "space.colors": a theme
// color name ("ansi6") or a picked #rrggbb. A space seen without one gets
// the theme color fewest spaces use, once; every mod does the same in the
// same order, so they agree, and adding or renaming spaces moves nothing.
const PROJECT_COLORS = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
function spaceColors() {
  const ids = new Set(spaces().map((p) => p.id));
  const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
  let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
  for (const p of spaces()) {
    if (kept[p.id] || p.name === "~") continue;
    const uses = (c) => Object.values(kept).filter((v) => v === c).length;
    kept[p.id] = PROJECT_COLORS.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    changed = true;
  }
  if (changed) setShared("space.colors", kept);
  return kept;
}
function spaceColor(t, p) {
  if (p.name === "~") return t.dim;
  const c = spaceColors()[p.id] ?? PROJECT_COLORS[0];
  return c.startsWith("#") ? c : (MARK[c] ?? t[c]);
}

export default class Picker extends View {
  init(_props, cx) {
    this.filter = "";
    this.input = InputState.new({ placeholder: "Go to a space…" });
    this.input.on("change", (_e, cx) => { this.filter = this.input.value(); this.at = 0; this.side = "left"; this.preview(); cx.notify(); });
    this.input.on("submit", () => {
      if (this.side === "right") {
        const item = this.treeTabs?.[this.treeAt ?? 0];
        if (item) {
          this.confirmed = true;
          this.close();
          run("tab.select", { id: item.c.id });
        }
      } else this.go(this.rows()[this.at]);
    });
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.at = null;
    this.side = "left";
    this.treeAt = null;
    this.treeTabs = [];
    this.scroll = 0;
    this.machines = [];
    const where = spaces().find((p) => p.active);
    this.from = where?.id ?? null;
    this.fromTab = where?.tabs.find((x) => x.active)?.id ?? null;
    this.confirmed = false;
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      try {
        const r = await hc(["machine", "ls", "--json"]);
        if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter((m) => m.state === "connected" && !m.temporary).map((m) => m.name);
      } catch {}
      cx.notify();
    });
  }

  close() {
    if (!this.confirmed && this.from) {
      if (this.fromTab) run("tab.select", { id: this.fromTab });
      else run("space.select", { id: this.from });
    }
    closeOverlay(props().overlay);
  }

  // The shown space follows the selection live.
  preview() {
    const r = this.rows()[this.at];
    if (r?.kind !== "space" || r.w.active) return;
    run("space.select", { id: r.w.id });
  }

  // In the tab tree the preview follows at tab granularity.
  previewTab(item) {
    if (!item || (item.w.active && item.c.active)) return;
    run("tab.select", { id: item.c.id });
  }

  rows() {
    const f = this.filter.toLowerCase();
    const out = spaces()
      .filter((p) => !f || p.name.toLowerCase().includes(f))
      .map((p) => ({ kind: "space", w: p }));
    out.push({ kind: "new", machine: null });
    for (const m of this.machines) out.push({ kind: "new", machine: m });
    return out;
  }

  go(r) {
    if (!r) return;
    this.confirmed = true;
    this.close();
    if (r.kind === "space") run("space.select", { id: r.w.id });
    else if (r.kind === "new") run("space.new", r.machine ? { machine: r.machine } : {});
  }

  glyph(t, st) {
    if (st === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900);
    return div().w(12).flex_none().text_color(t[st] ?? t.dim).child(st === "idle" ? "○" : st ? "●" : "·");
  }

  render() {
    const t = theme();
    const rows = this.rows();
    // Opens on where you are.
    if (this.at === null) this.at = Math.max(0, rows.findIndex((r) => r.kind === "space" && r.w.active));
    this.at = Math.min(this.at, rows.length - 1);
    const sel = rows[this.at];
    // One continuous strip: each row at a fixed y. Scrolling moves the strip
    // only as far as it takes to keep the selected row in view, so the
    // arrows can't run the selection off the list.
    const H = { space: 34, new: 32 };
    const tops = [];
    let y = 0;
    rows.forEach((r) => { tops.push(y); y += H[r.kind] ?? 32; });
    const total = y;
    const height = Math.min(320, this.listHeight ?? 320);
    const fixed = total > height;
    const maxScroll = Math.max(0, total - height);
    this.scroll = Math.max(0, Math.min(this.scroll, maxScroll));
    const si = rows.indexOf(sel);
    if (si >= 0) {
      if (tops[si] < this.scroll) this.scroll = tops[si];
      if (tops[si] + (H[sel.kind] ?? 32) > this.scroll + height) this.scroll = tops[si] + (H[sel.kind] ?? 32) - height;
    }
    const place = (el, i) =>
      fixed
        ? el.absolute().left(0).right(0).top(tops[i] - this.scroll).bottom(height - (tops[i] + (H[rows[i].kind] ?? 32) - this.scroll))
        : el;
    const visible = (i) => !fixed || (tops[i] + (H[rows[i].kind] ?? 32) > this.scroll && tops[i] < this.scroll + height);

    const row = (r) => {
      const on = r === sel && this.side !== "right";
      if (r.kind === "new") {
        const label = r.machine ? `new space on ${r.machine}` : "new space";
        return h_flex()
          .id(`pk-new-${r.machine ?? "here"}`)
          .mx(4)
          .mt(4)
          .px(10)
          .h(32)
          .items_center()
          .rounded(7)
          .gap(8)
          .text_color(t.muted)
          .cursor_pointer()
          .when(on, (el) => el.bg(t.hover))
          .hover((s) => s.bg(t.hover))
          .on_click(() => this.go(r))
          .child(div().w(12).child("+"))
          .child(label);
      }
      return h_flex()
        .id(`pk-space-${r.w.id}`)
        .mx(4)
        .px(10)
        .h(34)
        .rounded(7)
        .gap(10)
        .items_center()
        .cursor_pointer()
        .when(on, (el) => el.bg(t.hover))
        .hover((s) => s.bg(t.hover))
        .on_click(() => this.go(r))
        .child(h_flex().size(18).rounded(5).bg(spaceColor(t, r.w)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...r.w.name][0]?.toUpperCase() ?? "?"))
        .child(div().flex_1().truncate().text_color(t.foreground).when(r.w.active, (d) => d.font_semibold()).child(r.w.name))
        .child(this.glyph(t, r.w.status));
    };

    // The right half: every space's tabs and what runs in them, at a glance.
    // A working agent spins, a blocked one says "needs you", and a tab without
    // an agent shows the program that runs in it. Clicking goes there.
    const chip = (w) => h_flex().size(16).rounded(4).bg(spaceColor(t, w)).items_center().justify_center().text_size(9.5).font_bold().text_color("#ffffff").child([...w.name][0]?.toUpperCase() ?? "?");
    const treeRows = [];
    const treeTabs = [];
    let treeTotal = 0;
    for (const w of spaces()) {
      treeRows.push(
        h_flex()
          .id(`ag-s-${w.id}`)
          .h(26)
          .px(10)
          .gap(7)
          .items_center()
          .text_size(11.5)
          .font_semibold()
          .text_color(w.active ? t.foreground : t.dim)
          .cursor_pointer()
          .hover((s) => s.bg(t.hover))
          .on_click(() => this.go({ kind: "space", w }))
          .child(chip(w))
          .child(w.name)
      );
      treeTotal += 26;
      for (const c of w.tabs) {
        const st = c.status;
        const pane = panes().find((p) => p.tab === c.id && p.program?.agent) ?? panes().find((p) => p.tab === c.id);
        const program = pane?.program;
        // A program that never set a title shows its terminal address ("t18") as it;
        // shells rarely set one, and anything else shows the title it set.
        const title = pane?.title && !/^t\d+$/.test(pane.title) ? pane.title : null;
        const shown = c.named ? c.name
          : pane?.program?.shell ? program?.name || title || String(c.index)
          : title || program?.name || String(c.index);
        const label = st === "blocked" ? "needs you" : st === "done" ? "finished" : program?.name && !shown.includes(program.name) ? program.name : "";
        const here = w.active && c.active;
        const ti = treeTabs.length;
        const on2 = this.side === "right" && ti === (this.treeAt ?? -1);
        treeTabs.push({ w, c });
        treeRows.push(
          h_flex()
            .id(`ag-t-${c.id}`)
            .h(24)
            .pl(33)
            .pr(10)
            .gap(8)
            .items_center()
            .cursor_pointer()
            .when(on2, (el) => el.bg(t.hover))
            .hover((s) => s.bg(t.hover))
            .on_click(() => {
              this.confirmed = true;
              this.close();
              run("tab.select", { id: c.id });
            })
            .child(this.glyph(t, st))
            .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(here ? t.foreground : t.muted).when(here, (d) => d.font_semibold()).child(shown))
            .child(div().flex_none().text_size(11).text_color(st === "blocked" ? t.blocked : st === "done" ? t.done : t.dim).child(label))
        );
        treeTotal += 24;
      }
    }
    this.treeTabs = treeTabs;
    const agentsPane = v_flex()
      .id("pk-agents")
      .min_h(0)
      .flex_1()
      .border_l(1)
      .border_color(t.border)
      .child(div().px(10).pt(2).pb(4).text_size(11).font_semibold().text_color(t.dim).child("Agents"))
      .child(v_flex().min_h(0).when(treeTotal > 318, (el) => el.overflow_y_scrollbar()).h(Math.min(318, treeTotal)).children(treeRows));

    return v_flex()
      .id("picker")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        const k = e.key;
        if (k === "escape") return this.close();
        if (k === "right" || (k === "l" && e.modifiers.control)) {
          if (this.side === "right" || treeTabs.length === 0) return;
          this.side = "right";
          // Land on the active tab of the space selected on the left, every time.
          const left = rows[this.at]?.kind === "space" ? rows[this.at].w : spaces().find((p) => p.active);
          const tabId = left?.tabs.find((x) => x.active)?.id;
          this.treeAt = Math.max(0, treeTabs.findIndex((item) => item.c.id === tabId));
        } else if (k === "left" || (k === "h" && e.modifiers.control)) {
          if (this.side === "left") return;
          this.side = "left";
          // Keep both sides in step: follow the tree cursor back to its space.
          const item = treeTabs[this.treeAt];
          if (item) {
            const at = rows.findIndex((r) => r.kind === "space" && r.w.id === item.w.id);
            if (at >= 0) this.at = at;
          }
        } else if (k === "down" || (k === "j" && e.modifiers.control)) {
          if (this.side === "right") this.treeAt = (this.treeAt + 1) % treeTabs.length;
          else this.at = (this.at + 1) % rows.length;
        } else if (k === "up" || (k === "k" && e.modifiers.control)) {
          if (this.side === "right") this.treeAt = (this.treeAt + treeTabs.length - 1) % treeTabs.length;
          else this.at = (this.at + rows.length - 1) % rows.length;
        } else return;
        if (this.side === "right") this.previewTab(treeTabs[this.treeAt]);
        else this.preview();
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Spaces…")).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)),
      )
      .child(
        h_flex()
          .id("pk-split")
          .min_h(0)
          .gap(14)
          .child(
            v_flex()
              .id("pk-left")
              .min_h(0)
              .flex_1()
              .child(
                v_flex()
                  .id("pk-list")
                  .on_size_change((size, cx) => {
                    this.listHeight = size.height / settings().zoom;
                    cx.notify();
                  })
                  .h(Math.min(320, total))
                  .min_h(0)
                  .mb(6)
                  .when(fixed, (el) =>
                    el.overflow_hidden().on_scroll_wheel((e, cx) => {
                      this.scroll = Math.max(0, Math.min(this.scroll - e.delta.y, maxScroll));
                      // The selection follows the wheel, so the next frame doesn't scroll back to it.
                      while (this.at < rows.length - 1 && tops[this.at] < this.scroll) this.at++;
                      while (this.at > 0 && tops[this.at] + (H[rows[this.at].kind] ?? 32) > this.scroll + height) this.at--;
                      this.preview();
                      cx.notify();
                    }))
                  .children(rows.map((r, i) => (visible(i) ? place(row(r), i) : null)).filter(Boolean)),
              ),
          )
          .child(agentsPane),
      );
  }
}
