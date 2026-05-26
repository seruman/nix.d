glide.prefs.set("toolkit.legacyUserProfileCustomizations.stylesheets", true);
glide.prefs.set("devtools.debugger.prompt-connection", false);
glide.prefs.set("media.videocontrols.picture-in-picture.audio-toggle.enabled", true);
glide.prefs.set("browser.tabs.insertAfterCurrent", true);
glide.prefs.set("browser.tabs.insertRelatedAfterCurrent", true);
glide.prefs.set("browser.uidensity", 1);
glide.prefs.set("browser.startup.page", 3);
glide.prefs.set("browser.warnOnQuitShortcut", false);
glide.prefs.clear("ui.textScaleFactor");
glide.prefs.clear("layout.css.devPixelsPerPx");
glide.prefs.clear("browser.zoom.full");

glide.include("ui.glide.ts");

const plugins = [
	"https://addons.mozilla.org/firefox/downloads/file/4429158/kagi_search_for_firefox-0.7.6.xpi",
	"https://addons.mozilla.org/firefox/downloads/file/4598854/ublock_origin-1.67.0.xpi",
	"https://addons.mozilla.org/firefox/downloads/file/4602298/1password_x_password_manager-8.11.15.5.xpi",
	"https://addons.mozilla.org/firefox/downloads/file/4579487/readwise_highlighter-0.15.25.xpi",
	"https://addons.mozilla.org/firefox/downloads/file/4385912/icloud_hide_my_email-1.2.9.xpi",
	"https://addons.mozilla.org/firefox/downloads/file/4409277/prometheus_formatter-3.2.0.xpi",
];

for (const plugin of plugins) {
	glide.addons.install(plugin);
}

glide.include("glide.work.ts");
glide.include("github.glide.ts");
glide.include("commands.glide.ts");

glide.autocmds.create("ConfigLoaded", async () => {
	await glide.excmds.execute("mode_change normal");
});

glide.g.mapleader = "\\";
glide.o.hint_size = "16px";
glide.o.hint_chars = "asdfghjkl";

glide.keymaps.set(
	"normal",
	"<leader><C-r>",
	async () => {
		await browser.notifications.create({ type: "basic", title: "Glide", message: "Glide config reloaded" });
		await glide.excmds.execute("config_reload");
	},
	{ description: "Reload Glide config" },
);

glide.keymaps.set("normal", "<C-f>", "hint --location=browser-ui");
glide.keymaps.set("normal", ";", "commandline_show", { description: "Open command line" });

async function ensure_toolbar_visible(): Promise<void> {
	if (glide.styles.has("hide-toolbox")) {
		glide.styles.remove("hide-toolbox");
		await new Promise((resolve) => setTimeout(resolve, 40));
	}
}

function with_toolbar_visible(
	action: (props: glide.KeymapCallbackProps) => void | Promise<void>,
): glide.KeymapCallback {
	return async (props) => {
		await ensure_toolbar_visible();
		await action(props);
	};
}

async function focus_native_urlbar(opts?: { open_in_new_tab?: boolean; respect_pinned?: boolean }) {
	await ensure_toolbar_visible();

	const open_in_new_tab = opts?.open_in_new_tab ?? false;
	const respect_pinned = opts?.respect_pinned ?? false;

	let target_new_tab = open_in_new_tab;
	if (!target_new_tab && respect_pinned) {
		const tab = await glide.tabs.active();
		target_new_tab = tab.pinned;
	}

	glide.prefs.set("browser.urlbar.openintab", target_new_tab);
	await glide.keys.send("<D-l>", { skip_mappings: true });
	if (glide.ctx.mode !== "insert") {
		await new Promise((resolve) => setTimeout(resolve, 30));
		await glide.keys.send("<D-l>", { skip_mappings: true });
	}
}

glide.keymaps.set(
	"normal",
	"go",
	async () => {
		await focus_native_urlbar({ open_in_new_tab: false, respect_pinned: true });
	},
	{ description: "Edit current URL" },
);

glide.keymaps.set(
	"normal",
	"gO",
	async () => {
		await focus_native_urlbar({ open_in_new_tab: true });
	},
	{ description: "Edit current URL in new tab" },
);

// Reset urlbar.openintab when leaving insert mode so normal navigation stays in current tab.
glide.autocmds.create("ModeChanged", "insert:*", async () => {
	glide.prefs.set("browser.urlbar.openintab", false);
});

glide.keymaps.set(
	"normal",
	"o",
	async () => {
		await focus_native_urlbar({ open_in_new_tab: false, respect_pinned: true });
	},
	{ description: "Focus the address bar" },
);

glide.keymaps.set(
	"normal",
	"O",
	async () => {
		await focus_native_urlbar({ open_in_new_tab: true });
	},
	{ description: "Focus the address bar (open in new tab)" },
);

glide.keymaps.set("normal", "J", "tab_next", { description: "Next tab" });
glide.keymaps.set("normal", "K", "tab_prev", { description: "Previous tab" });
glide.keymaps.set("normal", "r", "reload", { description: "Reload the page" });
glide.keymaps.set("normal", "R", "reload_hard", { description: "Reload the page, bypass cache" });

glide.keymaps.set(
	"normal",
	"d",
	async ({ tab_id }) => {
		const tab = await browser.tabs.get(tab_id);

		if (tab.pinned) {
			browser.notifications.create({
				type: "basic",
				title: "Glide",
				message: "Cannot close a pinned tab",
			});
			return;
		}

		await glide.excmds.execute("tab_close");
	},
	{ description: "Close current tab, unless it's pinned" },
);

glide.keymaps.set("normal", "D", "tab_close", { description: "Close current tab" });

glide.keymaps.set("normal", "<C-]>", "forward", { description: "Go forward in history" });
glide.keymaps.set("normal", "<C-[>", "back", { description: "Go back in history" });
glide.keymaps.set("normal", "<leader>ff", "commandline_show tab ", { description: "Open tab switcher" });

glide.keymaps.set("normal", "u", "tab_reopen", { description: "Reopen recently closed tab" });

glide.keymaps.set("normal", "/", () => glide.findbar.open({ highlight_all: true, query: "" }), {
	description: "Search",
});

glide.keymaps.set(
	"insert",
	"<CR>",
	async () => {
		await glide.keys.send("<CR>", { skip_mappings: true });
		if (glide.findbar.is_focused()) {
			await glide.excmds.execute("mode_change normal");
		}
	},
	{ description: "Submit and exit to normal mode if in findbar" },
);

glide.keymaps.set(
	"insert",
	"<Esc>",
	async () => {
		if (glide.findbar.is_focused()) {
			await glide.findbar.close();
			return;
		}
		await glide.excmds.execute("mode_change normal");
	},
	{ description: "Close findbar or exit insert mode" },
);

glide.keymaps.set("normal", "n", () => glide.findbar.next_match(), { description: "Next search match" });
glide.keymaps.set("normal", "N", () => glide.findbar.previous_match(), { description: "Previous search match" });

glide.keymaps.set(
	"normal",
	"<leader>nh",
	async () => {
		await glide.findbar.close();
		await browser.find.removeHighlighting();
	},
	{ description: "Close findbar and clear highlights" },
);

glide.keymaps.set(
	"normal",
	"wi",
	with_toolbar_visible(async () => {
		await glide.keys.send("<D-A-i>", { skip_mappings: true });
	}),
	{ description: "Open devtools inspector" },
);

glide.keymaps.set(
	"normal",
	"<leader>go",
	with_toolbar_visible(async () => {
		await glide.keys.send("<D-S-k>", { skip_mappings: true });
	}),
	{ description: "Focus on Okta extension" },
);

glide.keymaps.set("command", "<C-j>", "commandline_focus_next");
glide.keymaps.set("command", "<C-k>", "commandline_focus_back");

glide.keymaps.set(
	"normal",
	"<C-;>",
	async ({ tab_id }) => {
		const tab = await browser.tabs.get(tab_id);
		await browser.tabs.update(tab_id, { pinned: !tab.pinned });
	},
	{ description: "Toggle pin for current tab" },
);

glide.keymaps.set(
	"normal",
	"ym",
	async ({ tab_id }) => {
		const tab = await browser.tabs.get(tab_id);
		await navigator.clipboard.writeText(`[${tab.title}](${tab.url})`);
		await browser.notifications.create({
			type: "basic",
			title: "Glide",
			message: "Markdown link copied to clipboard",
		});
	},
	{ description: "Yank markdown link" },
);

glide.keymaps.set(
	"normal",
	"F",
	async ({ tab_id }) => {
		glide.hints.show({
			selector: "[href]",
			async action({ content }) {
				const href = await content.execute((target) => (target as HTMLAnchorElement).href);
				await browser.tabs.create({ url: href, active: false, openerTabId: tab_id });
			},
		});
	},
	{ description: "Open link in a new background tab" },
);

glide.keymaps.set(
	"normal",
	",m",
	() => {
		const mpvPath = "/opt/homebrew/bin/mpv";
		const mpvArgs = ["--autofit-larger=960x540"];

		glide.hints.show({
			selector: "a[href], area[href], link[href], [role='link'][href], video",
			async action({ content }) {
				const url = await content.execute((target) => {
					if (target instanceof HTMLVideoElement) {
						return target.currentSrc || target.src || target.querySelector("source")?.src || null;
					}

					if (
						target instanceof HTMLAnchorElement ||
						target instanceof HTMLAreaElement ||
						target instanceof HTMLLinkElement
					) {
						return target.href;
					}

					if (target.matches("[role='link'][href]")) {
						return target.getAttribute("href");
					}

					return null;
				});

				if (!url) {
					await browser.notifications.create({
						type: "basic",
						title: "Glide",
						message: "No playable URL found for hinted element",
					});
					return;
				}

				if (url.startsWith("blob:")) {
					await browser.notifications.create({
						type: "basic",
						title: "Glide",
						message: "Hinted video uses a blob URL; hint the page link instead",
					});
					return;
				}

				try {
					await glide.process.spawn(mpvPath, [...mpvArgs, url]);
				} catch (error) {
					await browser.notifications.create({
						type: "basic",
						title: "Glide",
						message: error instanceof Error ? error.message : `Failed to launch mpv: ${String(error)}`,
					});
				}
			},
		});
	},
	{ description: "Hint a link or video and open it in mpv" },
);

glide.keymaps.set(
	"normal",
	"<leader>tt",
	() => {
		const v = glide.o.native_tabs;
		if (["autohide", "show"].includes(v)) {
			glide.o.native_tabs = "hide";
			return;
		}
		glide.o.native_tabs = "show";
	},
	{ description: "Toggle tab bar" },
);

glide.keymaps.set(
	"normal",
	"<leader>tr",
	() => {
		const id = "hide-toolbox";
		if (!glide.styles.has(id)) {
			glide.styles.add(
				`
					#navigator-toolbox {
						visibility: collapse !important;
						opacity: 0 !important;
						height: 0 !important;
						max-height: 0 !important;
						min-height: 0 !important;
						margin: 0 !important;
						padding: 0 !important;
						border: 0 !important;
						overflow: clip !important;
						pointer-events: none !important;
					}
				`,
				{ id },
			);
			return;
		}

		glide.styles.remove(id);
	},
	{ description: "Toggle top toolbar" },
);

glide.keymaps.set("normal", "<leader>h", async () => {
	const entries = await browser.history.search({
		text: "",
		endTime: Date.now(),
		startTime: Date.now() - 7 * 24 * 60 * 60 * 1000, // last 7 days
		maxResults: 10000,
	});

	glide.commandline.show({
		title: "history",
		options: entries.map((entry) => ({
			label: `${entry.title} - ${entry.url}`,
			async execute() {
				const tab = await glide.tabs.get_first({
					url: entry.url,
				});
				if (tab) {
					await browser.tabs.update(tab.id, {
						active: true,
					});
				} else {
					await browser.tabs.create({
						active: true,
						url: entry.url,
					});
				}
			},
		})),
	});
});

glide.keymaps.set("normal", "<C-,>", "blur");
