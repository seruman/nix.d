{
  ...
}:

{
  programs.ghostty = {
    enable = true;
    # Install Ghostty itself with Homebrew `ghostty@tip`.
    package = null;

    settings = {
      "window-padding-x" = 10;
      "window-padding-color" = "background";
      "window-title-font-family" = "Berkeley Mono";
      "window-new-tab-position" = "end";
      "mouse-hide-while-typing" = false;
      "macos-option-as-alt" = "left";
      "macos-titlebar-style" = "transparent";
      "macos-window-shadow" = true;
      scrollbar = "never";
      "unfocused-split-opacity" = 0.90;
      "copy-on-select" = true;
      "scrollback-limit" = 200000000;
      "quick-terminal-position" = "left";
      "quick-terminal-animation-duration" = 0;
      "quick-terminal-size" = "50%,95%";

      "cursor-style" = "block";
      "cursor-style-blink" = false;
      "cursor-invert-fg-bg" = true;
      "shell-integration" = "fish";
      "shell-integration-features" = "no-cursor";

      keybind = [
        "ctrl+b>n=new_window"
        "ctrl+b>c=new_tab"

        "ctrl+b>n=next_tab"
        "ctrl+b>p=previous_tab"

        "ctrl+b>1=goto_tab:1"
        "ctrl+b>2=goto_tab:2"
        "ctrl+b>3=goto_tab:3"
        "ctrl+b>4=goto_tab:4"
        "ctrl+b>5=goto_tab:5"
        "ctrl+b>6=goto_tab:6"
        "ctrl+b>7=goto_tab:7"
        "ctrl+b>8=goto_tab:8"
        "ctrl+b>9=goto_tab:9"
        "ctrl+b>0=goto_tab:10"

        "ctrl+b>shift+period=move_tab:1"
        "ctrl+b>shift+comma=move_tab:-1"

        "ctrl+b>\\=new_split:right"
        "ctrl+b>-=new_split:down"

        "ctrl+b>l=goto_split:right"
        "ctrl+b>h=goto_split:left"
        "ctrl+b>k=goto_split:top"
        "ctrl+b>j=goto_split:bottom"

        "ctrl+b>shift+l=resize_split:right,100"
        "ctrl+b>shift+h=resize_split:left,100"
        "ctrl+b>shift+k=resize_split:up,100"
        "ctrl+b>shift+j=resize_split:down,100"

        "ctrl+b>z=toggle_split_zoom"
        "ctrl+b>,=prompt_surface_title"

        "ctrl+b>ctrl+b=text:\\x02"

        "ctrl+b>ctrl+n=jump_to_prompt:1"
        "ctrl+b>ctrl+p=jump_to_prompt:-1"

        "ctrl+k=clear_screen"

        "ctrl+b>u=toggle_quick_terminal"
        "global:cmd+shift+u=toggle_quick_terminal"

        "shift+enter=text:\\n"

        "ctrl+b>[=activate_key_table:scrollmode"

        "scrollmode/"
        "scrollmode/j=scroll_page_lines:1"
        "scrollmode/k=scroll_page_lines:-1"

        "scrollmode/ctrl+d=scroll_page_down"
        "scrollmode/ctrl+u=scroll_page_up"
        "scrollmode/ctrl+f=scroll_page_down"
        "scrollmode/ctrl+b=scroll_page_up"
        "scrollmode/shift+j=scroll_page_down"
        "scrollmode/shift+k=scroll_page_up"

        "scrollmode/g>g=scroll_to_top"
        "scrollmode/shift+g=scroll_to_bottom"

        "scrollmode/slash=start_search"
        "scrollmode/n=navigate_search:next"

        "scrollmode/v=activate_key_table:selectmode"

        "scrollmode/shift+semicolon=toggle_command_palette"

        "scrollmode/escape=deactivate_key_table"
        "scrollmode/q=deactivate_key_table"
        "scrollmode/i=deactivate_key_table"

        "scrollmode/catch_all=ignore"

        "selectmode/h=adjust_selection:left"
        "selectmode/l=adjust_selection:right"
        "selectmode/j=adjust_selection:down"
        "selectmode/k=adjust_selection:up"
        "selectmode/0=adjust_selection:beginning_of_line"
        "selectmode/shift+4=adjust_selection:end_of_line"
        "selectmode/g>g=adjust_selection:home"
        "selectmode/shift+g=adjust_selection:end"

        "selectmode/y=copy_to_clipboard"
        "selectmode/escape=deactivate_key_table"
        "selectmode/catch_all=ignore"
      ];

      "font-family" = "Berkeley Mono";
      "font-size" = 14;
      "font-feature" = "-calt";
      "font-thicken" = true;
      "adjust-underline-thickness" = "-50%";
      theme = "seruzen";
      "auto-update-channel" = "tip";
    };

    themes.seruzen = {
      background = "#F4F0ED";
      foreground = "#6B5C4D";
      palette = [
        "0=#867462"
        "1=#d7898c"
        "2=#659e69"
        "3=#cc7f2b"
        "4=#485f84"
        "5=#854882"
        "6=#436460"
        "7=#d4cbc3"
        "8=#a69582"
        "9=#c65333"
        "10=#83b887"
        "11=#c29830"
        "12=#abb9d6"
        "13=#be79bb"
        "14=#729893"
        "15=#FFFFFF"
      ];
      "split-divider-color" = "#d4cbc3";
    };
  };
}
