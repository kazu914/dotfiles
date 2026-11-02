import { View, div } from "gpui-kit";
import { nextCommand, run, spaces } from "herdr";

export default class TabActions extends View {
  init(_props, cx) {
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "move-right") this.move(1);
        else if (command === "move-left") this.move(-1);
        cx.notify();
      }
    });
  }

  move(by) {
    const space = spaces().find((s) => s.active);
    if (!space) return;
    const tab = space.tabs.find((t) => t.active);
    if (!tab) return;
    const index = Math.min(Math.max(tab.index + by, 1), space.tabs.length);
    if (index !== tab.index) run("tab.move", { id: tab.id, index });
  }

  render(_cx) {
    return div();
  }
}
