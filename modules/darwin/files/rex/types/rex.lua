---@meta

-- Local editor definitions.
-- API: https://www.superlogical.com/rex/docs/reference/lua
-- Action schemas: installed Rex client's and server's "rex actions --json".
-- Binding overloads describe this snapshot; add custom action names as needed.

---@class rex.Context
---@field session_id? string
---@field block_id? string
---@field client_id? string
---@field origin? string
---@field server? table

---@class rex.KeyEvent
---@field keybinding string
---@field prefix? string[]

---@alias rex.KeyHandler fun(ctx: rex.Context, ev: rex.KeyEvent): boolean?

---@class rex.Binding
---@field key string
---@field mode? string
---@field action? string
---@field fn? rex.KeyHandler
---@field args? table
---@field source string

---@class rex.Mode
---@field name string
---@field exclusive boolean
---@field source string

---@class rex.Action
---@field name string
---@field title string
---@field run fun(ctx: rex.Context, args: table): any
---@field description? string
---@field category? string
---@field keywords? string
---@field args? table
---@field repeats? boolean

---@class rex.Args.session_select
---@field session_id string The identifier that the session's server assigned.
---@field window_id? string A window in the session to show. If omitted, the session opens as usual.

---@class rex.Args.client_tab_goto
---@field index integer The tab to show. Tabs count from 1, and -1 means the last tab.

---@class rex.Args.client_tab_move
---@field direction "backward"|"forward"

---@class rex.Args.pane_split
---@field direction "right"|"down"|"left"|"up"|"auto"

---@class rex.Args.pane_focus
---@field direction "left"|"right"|"up"|"down"

---@class rex.Args.pane_resize
---@field amount? number How far to move the divider, as a percentage of the split it divides. The default is 5.
---@field direction "left"|"right"|"up"|"down"

---@class rex.Args.pane_send_key
---@field key string The key to send, written the way a key binding is, such as "ctrl+u".

---@class rex.Args.client_mode_enter
---@field name string The mode to enter, as the configuration names it.
---@field once? boolean Leave the mode after one of its own keys performs. The default is false.

---@class rex.Args.client_theme_change
---@field name? string Theme name or ID to fuzzy-match. Omit to open the theme picker.

---@class rex.Args.client_appearance_switch_mode
---@field mode "light"|"dark"|"toggle" Use light or dark appearance, or toggle the currently visible appearance.

---@class rex.Args.com_superlogical_terminal_format
---@field format? string
---@field trim? boolean
---@field unwrap? boolean
---@field extra_charsets? boolean
---@field extra_cursor? boolean
---@field extra_hyperlink? boolean
---@field extra_keyboard? boolean
---@field extra_kitty_keyboard? boolean
---@field extra_modes? boolean
---@field extra_palette? boolean
---@field extra_protection? boolean
---@field extra_pwd? boolean
---@field extra_scrolling_region? boolean
---@field extra_style? boolean
---@field extra_tabstops? boolean

---@class rex.Args.com_superlogical_terminal_list_dir
---@field path? string
---@field prefix? string
---@field limit? integer
---@field files? boolean

---@class rex.Args.com_superlogical_terminal_resize
---@field columns? integer
---@field rows? integer
---@field cell_width_px? nil|integer
---@field cell_height_px? nil|integer
---@field mode? ""|"advisory"|"take"|"release" With advisory, record a desired size and resize only for the owner or an unowned block, claiming ownership if unowned. With take, resize and make the caller owner. Empty or omitted means take. With release, remove the desired size and, if owner, promote the newest remaining advisory. Supplied dimensions are ignored for release. Without a caller, every mode resizes without changing ownership and requires valid dimensions.

---@class rex.Args.com_superlogical_terminal_set_theme
---@field foreground? string
---@field background? string
---@field cursor? string
---@field palette? nil|(string)[]
---@field scheme? string

---@class rex.Args.com_superlogical_terminal_write
---@field data string

---@alias rex.NoArgsAction
---| "client.window.new" # New Window
---| "client.window.close" # Close Window
---| "client.close" # Close
---| "client.palette.toggle" # Command Palette…
---| "client.settings" # Settings…
---| "client.diagnostics" # Rex Diagnostics
---| "client.version.copy" # Copy Version Info
---| "client.debug.copy" # Copy Debug Info
---| "client.pair_device" # Pair Device with QR Code…
---| "client.update.accept" # Install Update
---| "client.notice.dismiss" # Dismiss Notice
---| "client.shortcuts.edit" # Change Shortcut…
---| "session.new" # New Session
---| "session.switch" # Change Session…
---| "session.next" # Next Session
---| "session.previous" # Previous Session
---| "session.rename" # Rename Session
---| "session.close" # Close Session
---| "session.refresh" # Refresh Sessions
---| "session.open_on_web" # Open Session on Web…
---| "client.host.switch" # Switch Host
---| "client.host.add" # Add Remote Host…
---| "client.host.remove" # Remove Host…
---| "client.tab.new" # New Tab
---| "client.tab.close" # Close Tab
---| "client.tab.rename" # Rename Tab
---| "client.tab.next" # Show Next Tab
---| "client.tab.previous" # Show Previous Tab
---| "client.tab.move.backward" # Move Tab Backward
---| "client.tab.move.forward" # Move Tab Forward
---| "pane.split.left" # Split Pane Left
---| "pane.split.right" # Split Pane Right
---| "pane.split.up" # Split Pane Up
---| "pane.split.down" # Split Pane Down
---| "pane.split.auto" # Split Pane Best Fit
---| "pane.focus.left" # Focus Pane Left
---| "pane.focus.right" # Focus Pane Right
---| "pane.focus.up" # Focus Pane Up
---| "pane.focus.down" # Focus Pane Down
---| "pane.focus_next" # Focus Next Pane
---| "pane.focus_previous" # Focus Previous Pane
---| "pane.zoom" # Zoom Pane
---| "pane.close" # Close Pane
---| "pane.balance" # Balance Splits
---| "pane.move_to_new_tab" # Move Pane to New Tab
---| "pane.go_to_directory" # Go to Directory…
---| "pane.insert_path" # Insert Path…
---| "client.key.forward" # Send Key to Server
---| "client.mode.exit" # Exit Mode
---| "client.mode.exit_all" # Exit All Modes
---| "client.find.open" # Find…
---| "client.find.next" # Find Next
---| "client.find.previous" # Find Previous
---| "client.font.increase" # Increase Font Size
---| "client.font.decrease" # Decrease Font Size
---| "client.font.reset" # Reset Font Size
---| "client.sidebar.toggle" # Toggle Sidebar
---| "client.tab_style.toggle" # Toggle Tab Style
---| "client.config.copy_path" # Copy Config File Path
---| "client.config.reload" # Reload Config
---| "com.superlogical.terminal.clear" # Clear Terminal
---| "com.superlogical.terminal.process"
---| "com.superlogical.terminal.program_status"
---| "com.superlogical.terminal.pwd"
---| "com.superlogical.terminal.reset" # Reset Terminal
---| "com.superlogical.terminal.size"
---| "com.superlogical.terminal.title"

rex = { client = {}, session = {}, block = {}, layout = {} }

---@param key string
---@param action rex.NoArgsAction|rex.KeyHandler
---@overload fun(key: string, action: "session.select", args: rex.Args.session_select)
---@overload fun(key: string, action: "client.tab.goto", args: rex.Args.client_tab_goto)
---@overload fun(key: string, action: "client.tab.move", args: rex.Args.client_tab_move)
---@overload fun(key: string, action: "pane.split", args: rex.Args.pane_split)
---@overload fun(key: string, action: "pane.focus", args: rex.Args.pane_focus)
---@overload fun(key: string, action: "pane.resize", args: rex.Args.pane_resize)
---@overload fun(key: string, action: "pane.send_key", args: rex.Args.pane_send_key)
---@overload fun(key: string, action: "client.mode.enter", args: rex.Args.client_mode_enter)
---@overload fun(key: string, action: "client.theme.change", args?: rex.Args.client_theme_change)
---@overload fun(key: string, action: "client.appearance.switch_mode", args: rex.Args.client_appearance_switch_mode)
---@overload fun(key: string, action: "com.superlogical.terminal.format", args?: rex.Args.com_superlogical_terminal_format)
---@overload fun(key: string, action: "com.superlogical.terminal.list_dir", args?: rex.Args.com_superlogical_terminal_list_dir)
---@overload fun(key: string, action: "com.superlogical.terminal.resize", args?: rex.Args.com_superlogical_terminal_resize)
---@overload fun(key: string, action: "com.superlogical.terminal.set_theme", args?: rex.Args.com_superlogical_terminal_set_theme)
---@overload fun(key: string, action: "com.superlogical.terminal.write", args: rex.Args.com_superlogical_terminal_write)
function rex.bind(key, action, ...) end

---@param key string
---@param target? string|rex.KeyHandler
---@return integer
---@overload fun(binding: rex.Binding): integer
---@overload fun(options: {mode: string}): integer
function rex.unbind(key, target) end

---@param name string
---@param options? {exclusive?: boolean}
function rex.mode(name, options) end

---@param filter? {key?: string, mode?: string, action?: string}
---@return rex.Binding[]
function rex.bindings(filter) end

---@return rex.Mode[]
function rex.modes() end

---@param definition rex.Action
function rex.action(definition) end

---@param name string
---@param args? table
---@return any result
---@return string? error
function rex.invoke(name, args) end

---@param name string
---@param args? table
function rex.client.queue(name, args) end

---@param method string
---@param args? table
---@return table? result
---@return string? error
function rex.call(method, args) end

---@param creator string
---@param method string
---@param args? table
---@return table? result
---@return string? error
function rex.block.call(creator, method, args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.view(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.list_blocks(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.list_clients(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.describe_block(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.new_window(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.new_split(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.new_block(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.new_layer(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.close_window(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.close_layer(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.move_block(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.swap_blocks(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.detach_block(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.float_block(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.zoom_block(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.resize_pane(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.resize_layer(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.raise_layer(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.lower_layer(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.move_window(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.focus_block(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.focus_window(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.focus_direction(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.focus_next_pane(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.focus_previous_pane(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.focus_next_window(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.focus_previous_window(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.set_label(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.set_window_label(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.set_block_label(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.attach(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.detach(args) end

---@param args table
---@return table? result
---@return string? error
function rex.session.help(args) end

---@class rex.TerminalOptions
---@field command? string[]
---@field shell? string
---@field cwd? string
---@field initial_input? string
---@field exit? {on_completion?: boolean}

---@param options {flavor: string, options?: rex.TerminalOptions}
---@return table
function rex.layout.block(options) end

---@param ratio number
---@param a table
---@param b table
---@return table
function rex.layout.horizontal(ratio, a, b) end

---@param ratio number
---@param a table
---@param b table
---@return table
function rex.layout.vertical(ratio, a, b) end

---@param options {label: string, endpoints?: string[], endpoint?: string, id?: string, icon?: string}
function rex.host(options) end

---@return string[]
function rex.servers() end

---@return {session: table, block: table, call: function}
---@param label string
function rex.server(label) end

---@param level "debug"|"info"|"warn"|"error"
---@param message string
---@overload fun(message: string)
function rex.log(level, message) end
