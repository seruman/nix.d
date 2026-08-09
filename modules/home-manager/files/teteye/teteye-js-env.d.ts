/**
 * Draft Teteye JavaScript config environment: implemented v1 plus planned TODO contract.
 *
 * This is an internal design contract, not a shipped user-facing type bundle yet.
 * V1 is intentionally a small synchronous config DSL over Teteye's existing
 * typed config, key tables, and open-url pipeline.
 *
 * Runtime rules:
 * - config evaluation and local file inclusion are synchronous.
 * - Ghostty still receives generated static key=value config from Teteye.
 * - JavaScriptCore stays behind the config boundary.
 * - no Node/npm/DOM globals are provided.
 *
 * The callback-returned action surface is implemented for key and link/open-url callbacks.
 * Keep TODO work aligned to this file; do not
 * add process stdout/stderr, general fs, timers, or live process handles here
 * until a separate design is accepted.
 */

declare global {
  const teteye: Teteye.API;
  const console: Teteye.Console;
}

declare namespace Teteye {
  interface API {
    readonly apiVersion: 1;

    /** Merge static settings into the config snapshot. Last write wins. */
    config(config: Config): void;

    /**
     * Evaluate a local JavaScript config fragment once in declaration order.
     * Each file has its own function scope, so declarations and helpers do not leak between files.
     * Explicit global object and prototype mutations remain shared across the config runtime.
     * Relative paths resolve from the including file; absolute paths support generated files such as Nix store paths.
     * Only `.js` files are supported. URLs, packages, ESM, and callback-time inclusion are unavailable.
     */
    include(path: string): void;

    /** Define or extend a key table. Later options and bindings override only matching fields and keys. */
    keytable(name: string, build: (table: KeyTableBuilder) => void): void;
    keytable(name: string, options: KeyTableOptions, build: (table: KeyTableBuilder) => void): void;

    readonly action: ActionAPI;
    readonly links: LinksAPI;
    readonly openURL: OpenURLAPI;
  }

  interface Console {
    log(...items: unknown[]): void;
    warn(...items: unknown[]): void;
    error(...items: unknown[]): void;
  }

  interface Config {
    terminal?: TerminalConfig;
    colors?: ColorsConfig;
    window?: WindowConfig;
    clipboard?: ClipboardConfig;
    shell?: ShellConfig;
    titlebar?: TitlebarConfig;
    macos?: MacOSConfig;
    ipc?: IPCConfig;
  }

  interface TerminalConfig {
    fontFamily?: string;
    fontSize?: number;
    fontThicken?: boolean;
    fontFeatures?: readonly string[];
    /** Signed 32-bit pixel adjustment or percentage adjustment relative to the font's underline thickness. */
    underlineThickness?: number | `${number}%`;
    scrollback?: ScrollbackConfig;
    cursorStyle?: "block" | "bar" | "underline" | string;
    cursorBlink?: boolean;
    mouseHideWhileTyping?: boolean;
    /** Raw Ghostty link regexes with no Teteye action. Prefer teteye.links.add for handled links. */
    linkPatterns?: readonly string[];
  }

  interface ScrollbackConfig {
    /** Non-negative JavaScript safe integer of uncompressed logical page bytes per surface, or "unlimited". Defaults to 50 MB. */
    limitBytes?: number | "unlimited";
    /** Non-negative JavaScript safe integer approximate line cap per surface, excluding the active screen, or "unlimited". Defaults to "unlimited". */
    limitLines?: number | "unlimited";
    /** Compress idle historical pages, typically reducing their resident memory by 70%-90%; savings vary by content. Defaults to true. */
    compression?: boolean;
  }

  interface ColorsConfig {
    theme?: string;
    foreground?: Color;
    background?: Color;
    cursor?: TerminalColor;
    cursorText?: TerminalColor;
    selectionForeground?: Color;
    selectionBackground?: Color;
    /** Palette indexes 0-15. */
    palette?: Partial<Record<PaletteIndex, Color>> | readonly Color[];
  }

  type Color = `#${string}` | string;
  type TerminalColor = Color | "cell-foreground" | "cell-background";
  type PaletteIndex = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15;

  interface WindowConfig {
    style?: "native" | "borderless" | string;
    padding?: number;
    paddingX?: number;
    paddingY?: number;
    paddingColor?: "background" | "extend" | "extend-always";
    opacity?: number;
    /** Opacity of nonfocused panes in a split, clamped to Ghostty's 0.15 through 1 range. */
    unfocusedSplitOpacity?: number;
    /** Insert new tabs after the current tab or at the end of the native tab group. */
    newTabPosition?: "current" | "end";
    inheritCwd?: boolean;
    quitAfterLastWindowClosed?: boolean;
  }

  interface ClipboardConfig {
    read?: ClipboardPolicy;
    write?: ClipboardPolicy;
    trimTrailingSpaces?: boolean;
    pasteProtection?: boolean;
    pasteBracketedSafe?: boolean;
    copyOnSelect?: "clipboard" | "primary" | "false" | string;
  }

  type ClipboardPolicy = "allow" | "deny" | "ask" | string;

  interface ShellConfig {
    command?: string;
    workingDirectory?: string;
    env?: Record<string, string | number | boolean>;
    integration?: string;
    integrationFeatures?: string;
    titleReport?: boolean;
  }

  interface TitlebarConfig {
    fontFamily?: string;
  }

  interface MacOSConfig {
    autoSecureInput?: boolean;
    secureInputIndication?: boolean;
    optionAsAlt?: "left" | "right" | "both" | "none" | string;
  }

  interface IPCConfig {
    enabled?: boolean;
    socketPath?: string;
  }

  interface KeyTableBuilder {
    /** Bind Teteye key syntax: "ctrl+b", "cmd+shift+p", "escape", "1". */
    bind(key: string, target: KeyBindingTarget): void;
  }

  /**
   * Enqueued on key dispatch; returned actions are executed by Teteye after the callback settles.
   * Key actions use the captured pane/tab/window when supported and run only if that source
   * is still the active terminal responder, except reloadConfig. Key-table stack actions returned from callbacks
   * are ignored in v1.
   */
  type KeyCallback = (ctx: KeyContext) => CallbackResult | Promise<CallbackResult>;
  type KeyBindingTarget = KeyAction | readonly KeyAction[] | KeyCallback;

  interface KeyTableOptions {
    timeoutMs?: number;
    timeoutAction?: KeyAction;
    passthrough?: boolean;
    stay?: boolean;
  }

  /** Base opaque action value created by teteye.action.*. */
  interface Action {
    readonly __teteyeAction: unique symbol;
  }

  interface KeyAction extends Action {
    readonly __teteyeKeyAction: unique symbol;
  }

  interface OpenURLAction extends Action {
    readonly __teteyeOpenURLAction: unique symbol;
  }

  type CallbackResult = Action | readonly Action[] | null | undefined | false;

  interface KeyContext extends CallbackContext {
    /** Canonical Teteye key syntax ordered as ctrl, alt, cmd, shift, then key. */
    readonly key: string;
  }

  interface LinkContext extends CallbackContext {
    readonly raw: string;
    readonly kind: "text" | "html" | "unknown";
    readonly match: readonly string[];
  }

  interface CallbackContext {
    readonly pane: Pane;
    readonly tab: Tab;
    readonly window: Window;
  }

  interface Pane {
    readonly id: string;
    readonly title: string;
    readonly cwd: string | null;
    readonly focused: boolean;
    readonly zoomed: boolean;
    readonly secureInput: boolean;
    readonly passwordInput: boolean;
  }

  interface Tab {
    readonly id: string;
    readonly index: number;
    readonly title: string;
  }

  interface Window {
    readonly id: string;
    readonly focused: boolean;
  }

  type PaneRef = Pane | string;
  type TabRef = Tab | string | number;
  type WindowRef = Window | string;

  interface PaneLaunchOptions {
    /** Working directory for the new terminal. Defaults to Teteye's normal inheritance behavior. */
    cwd?: string | null;
    /** argv-style command. Teteye does not run this through a shell. */
    command?: readonly string[];
    /** Text sent to the default shell after launch, for shell-style workflows. */
    initialInput?: string;
    /** Focus the created pane/tab/window. Defaults to true. */
    focus?: boolean;
  }

  interface TargetOptions {
    target?: PaneRef;
  }

  interface DumpOptions extends TargetOptions {
    scope?: "viewport" | "scrollback" | "all";
    format?: "text" | "ansi" | "html";
    to: { file: string } | { clipboard: true };
  }

  interface ActionAPI {
    // Table navigation
    switchTable(table: string): KeyAction;
    pop(): KeyAction;
    popAll(): KeyAction;

    // Panes
    split(direction: SplitDirection, options?: PaneLaunchOptions): KeyAction;
    split(options: PaneLaunchOptions): KeyAction;
    closePane(options?: TargetOptions): KeyAction;
    focusPane(direction: FocusDirection): KeyAction;
    focusPane(target: PaneRef): KeyAction;
    zoomPane(options?: TargetOptions): KeyAction;
    equalizePanes(): KeyAction;
    resizePane(direction: PaneDirection, amount?: number, options?: TargetOptions): KeyAction;
    swapPane(direction: PaneDirection, options?: TargetOptions): KeyAction;
    nextPane(): KeyAction;
    prevPane(): KeyAction;

    // Tabs/windows
    newTab(options?: PaneLaunchOptions): KeyAction;
    closeTab(target?: TabRef): KeyAction;
    focusTab(target: TabRef): KeyAction;
    nextTab(): KeyAction;
    prevTab(): KeyAction;
    gotoTab(index: number): KeyAction;
    moveTab(direction: "left" | "right" | string, target?: TabRef): KeyAction;
    setTabColor(color: string, target?: TabRef): KeyAction;
    newWindow(options?: PaneLaunchOptions): KeyAction;
    focusWindow(target: WindowRef): KeyAction;
    closeWindow(target: WindowRef): KeyAction;

    // App and terminal content
    palette(target: "tabs" | "panes" | "commands", options?: PaletteOptions): KeyAction;
    scroll(direction: "up" | "down" | string, amount?: "page" | "half-page" | number | string): KeyAction;
    search(): KeyAction;
    scrollbackEditor(): KeyAction;
    jumpToPrompt(direction: "previous" | "next"): KeyAction;
    clearScreen(): KeyAction;
    reloadConfig(): KeyAction;
    sendText(text: string, options?: TargetOptions): KeyAction;
    sendKeys(keys: readonly string[], options?: TargetOptions): KeyAction;
    dump(options: DumpOptions): KeyAction;

    // Clipboard/copy mode
    copy(): KeyAction;
    paste(): KeyAction;
    copyMode(command: CopyModeAction): KeyAction;

    // Composition and URL/link helpers. Prefer returning/binding action arrays in JS.
    sequence(actions: readonly KeyAction[]): KeyAction;
    openURL(url: string): OpenURLAction;
    run(command: string, args?: readonly string[]): OpenURLAction;
  }

  type SplitDirection = "right" | "down";
  type PaneDirection = "left" | "right" | "up" | "down";
  type FocusDirection = PaneDirection | "next" | "prev";

  interface PaletteOptions {
    scope?: "current-tab" | "all-tabs";
  }

  type CopyModeAction =
    | { command: "begin" }
    | { command: "move"; direction: CopyModeDirection }
    | { command: "visual"; mode: "character" | "line" | "rectangle" }
    | { command: "yank" }
    | { command: "cancel" };

  type CopyModeDirection =
    | "left"
    | "right"
    | "up"
    | "down"
    | "page_up"
    | "page_down"
    | "home"
    | "end"
    | "beginning_of_line"
    | "end_of_line";

  interface LinksAPI {
    /**
     * Make terminal text clickable through Ghostty's static link regex support,
     * then let Teteye handle matching payloads in declaration order.
     * RegExp flags are rejected in v1; use explicit regex syntax instead.
     */
    add(pattern: Pattern, target: LinkTarget): void;
  }

  type Pattern = RegExp | string;
  /** Requires a source pane context; matched callback rules fail closed with no fallback when Teteye cannot build one. */
  type LinkCallback = (ctx: LinkContext) => CallbackResult | Promise<CallbackResult>;
  type LinkTarget = OpenURLAction | URLTemplate | LinkCallback;

  interface URLTemplate {
    urlTemplate: string;
  }

  interface OpenURLAPI {
    /** Prepend command lookup paths for link/open-url command handlers only. */
    path(...directories: readonly string[]): void;

    /** Handle URLs from OSC 8, Ghostty OPEN_URL actions, and teteye.links matches. */
    handle(pattern: Pattern, target: OpenURLTarget): void;
  }

  type OpenURLTarget = OpenURLAction | URLTemplate | LinkCallback;
}

export {};
