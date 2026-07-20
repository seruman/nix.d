/// <reference path="./teteye-js-env.d.ts" />
// @ts-check

const berkeleyMono = "Berkeley Mono";

const openURLPaths = [
  "/Users/selman/go/bin",
  "/Users/selman/.cargo/bin",
  "/Users/selman/bin",
  "/Users/selman/sbin",
  "/Users/selman/.local/bin",
  "/Users/selman/.nix-profile/bin",
  "/etc/profiles/per-user/selman/bin",
  "/run/current-system/sw/bin",
  "/opt/homebrew/bin",
  "/opt/homebrew/sbin",
];

teteye.config({
  terminal: {
    cursorBlink: false,
    cursorStyle: "block",
    fontFamily: berkeleyMono,
    fontSize: 14,
    fontThicken: true,
    scrollbackLines: 200000000,
  },
  colors: {
    background: "#F4F0ED",
    foreground: "#6B5C4D",
    palette: [
      "#867462",
      "#d7898c",
      "#659e69",
      "#cc7f2b",
      "#485f84",
      "#854882",
      "#436460",
      "#d4cbc3",
      "#a69582",
      "#c65333",
      "#83b887",
      "#c29830",
      "#abb9d6",
      "#be79bb",
      "#729893",
      "#FFFFFF",
    ],
  },
  window: {
    opacity: 1,
    paddingX: 10,
    quitAfterLastWindowClosed: true,
  },
  clipboard: {
    pasteBracketedSafe: true,
    pasteProtection: true,
    read: "ask",
    trimTrailingSpaces: true,
    write: "ask",
  },
  shell: {
    integration: "fish",
    integrationFeatures: "no-cursor",
  },
  titlebar: {
    fontFamily: berkeleyMono,
  },
});

teteye.openURL.path(...openURLPaths);
teteye.keytable("copy", { stay: true }, table => {
  table.bind("h", teteye.action.copyMode({ command: "move", direction: "left" }));
  table.bind("j", teteye.action.copyMode({ command: "move", direction: "down" }));
  table.bind("k", teteye.action.copyMode({ command: "move", direction: "up" }));
  table.bind("l", teteye.action.copyMode({ command: "move", direction: "right" }));
  table.bind("ctrl+b", teteye.action.copyMode({ command: "move", direction: "page_up" }));
  table.bind("ctrl+f", teteye.action.copyMode({ command: "move", direction: "page_down" }));
  table.bind("0", teteye.action.copyMode({ command: "move", direction: "beginning_of_line" }));
  table.bind("$", teteye.action.copyMode({ command: "move", direction: "end_of_line" }));
  table.bind("g", teteye.action.copyMode({ command: "move", direction: "home" }));
  table.bind("shift+g", teteye.action.copyMode({ command: "move", direction: "end" }));
  table.bind("v", teteye.action.copyMode({ command: "visual", mode: "character" }));
  table.bind("shift+v", teteye.action.copyMode({ command: "visual", mode: "line" }));
  table.bind("ctrl+v", teteye.action.copyMode({ command: "visual", mode: "rectangle" }));
  table.bind("y", teteye.action.copyMode({ command: "yank" }));
  table.bind("enter", teteye.action.copyMode({ command: "yank" }));
  table.bind("escape", teteye.action.copyMode({ command: "cancel" }));
  table.bind("q", teteye.action.copyMode({ command: "cancel" }));
});

teteye.keytable("prefix", { timeoutMs: 1500, timeoutAction: teteye.action.pop() }, table => {
  table.bind("minus", teteye.action.split("down"));
  table.bind("backslash", teteye.action.split("right"));
  table.bind("o", teteye.action.palette("panes", { scope: "all-tabs" }));
  table.bind("x", teteye.action.closePane());
  table.bind("z", teteye.action.zoomPane());
  table.bind("h", teteye.action.focusPane("left"));
  table.bind("j", teteye.action.focusPane("down"));
  table.bind("k", teteye.action.focusPane("up"));
  table.bind("l", teteye.action.focusPane("right"));
  table.bind("c", teteye.action.newTab());
  table.bind("n", teteye.action.nextTab());
  table.bind("p", teteye.action.prevTab());
  table.bind("1", teteye.action.gotoTab(0));
  table.bind("2", teteye.action.gotoTab(1));
  table.bind("3", teteye.action.gotoTab(2));
  table.bind("4", teteye.action.gotoTab(3));
  table.bind("5", teteye.action.gotoTab(4));
  table.bind("6", teteye.action.gotoTab(5));
  table.bind("7", teteye.action.gotoTab(6));
  table.bind("8", teteye.action.gotoTab(7));
  table.bind("9", teteye.action.gotoTab(8));
  table.bind("shift+period", teteye.action.moveTab("right"));
  table.bind("shift+comma", teteye.action.moveTab("left"));
  table.bind("slash", teteye.action.search());
  table.bind("bracketleft", teteye.action.copyMode({ command: "begin" }));
  table.bind("r", teteye.action.switchTable("resize"));
  table.bind("escape", teteye.action.pop());
});

teteye.keytable("resize", { timeoutMs: 3000, timeoutAction: teteye.action.pop(), stay: true }, table => {
  table.bind("h", teteye.action.resizePane("left", 2));
  table.bind("j", teteye.action.resizePane("down", 2));
  table.bind("k", teteye.action.resizePane("up", 2));
  table.bind("l", teteye.action.resizePane("right", 2));
  table.bind("=", teteye.action.equalizePanes());
  table.bind("enter", teteye.action.popAll());
  table.bind("escape", teteye.action.popAll());
});

teteye.keytable("root", table => {
  table.bind("cmd+p", teteye.action.palette("commands"));
  table.bind("ctrl+b", teteye.action.switchTable("prefix"));
  table.bind("ctrl+k", teteye.action.clearScreen());
});
