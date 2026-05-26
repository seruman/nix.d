glide.styles.add(
	`
		:root {
			--chrome-content-separator-color: transparent !important;
			--glide-mode-ui-bg: color-mix(in srgb, var(--glide-current-mode-color) 32%, var(--toolbar-bgcolor, transparent));
			--glide-font-family: "Berkeley Mono", monospace !important;
			--glide-font-family-sans: "Berkeley Mono", monospace !important;
			--glide-ui-font-size: 14px;

			--glide-mode-normal: #aeb6c7;
			--glide-mode-insert: #9cc7b8;
			--glide-mode-visual: #cf9466;
			--glide-mode-command: #c0caf5;
			--glide-mode-hint: #c8b26a;
			--glide-mode-ignore: #d4a1a1;
			--glide-mode-op-pending: #b9c48a;
			--glide-fallback-mode: #c7cbd4;
		}

		#navigator-toolbox,
		#sidebar-box,
		#sidebar-main,
		sidebar-main {
			background: var(--glide-mode-ui-bg) !important;
			box-shadow: 0 0 0 1px color-mix(in srgb, var(--glide-current-mode-color) 65%, transparent) inset,
				0 0 18px -10px var(--glide-current-mode-color) inset !important;
			transition: background-color 80ms linear, box-shadow 80ms linear;
		}

		#navigator-toolbox,
		#navigator-toolbox *,
		#sidebar-box,
		#sidebar-box *,
		#sidebar-main,
		#sidebar-main *,
		#urlbar,
		#urlbar-input,
		.findbar-textbox {
			font-family: "Berkeley Mono", monospace !important;
		}

		#navigator-toolbox,
		#sidebar-box,
		#sidebar-main,
		#urlbar,
		#urlbar-input,
		.tab-label,
		.toolbarbutton-text,
		.findbar-textbox {
			font-size: var(--glide-ui-font-size) !important;
		}

		#navigator-toolbox,
		#nav-bar,
		#sidebar-box,
		#sidebar-main,
		sidebar-main,
		#browser,
		#appcontent,
		#tabbrowser-tabbox,
		#tabbrowser-tabpanels {
			border: none !important;
			outline: none !important;
		}

		#navigator-toolbox::before,
		#navigator-toolbox::after,
		#sidebar-box::before,
		#sidebar-box::after,
		#sidebar-main::before,
		#sidebar-main::after {
			border: none !important;
			box-shadow: none !important;
			background: transparent !important;
		}

		sidebar-main {
			border-inline: none !important;
			border-inline-width: 0 !important;
		}

		#browser {
			position: relative !important;
			margin-top: -1px !important;
			padding-top: 1px !important;
		}

		#browser::before {
			content: "";
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			height: 2px;
			pointer-events: none;
			z-index: 2147483647;
			background: var(--glide-mode-ui-bg) !important;
		}
		#sidebar-splitter {
			border: none !important;
			background: transparent !important;
			width: 0 !important;
			min-width: 0 !important;
		}
	`,
	{ id: "glide-custom-mode-indicator", overwrite: true },
);

