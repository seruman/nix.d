// https://github.com/glide-browser/glide/discussions/114#discussioncomment-15009330
function on_tab_enter(
	pattern: glide.AutocmdPatterns["UrlEnter"],
	callback: (args: glide.AutocmdArgs["UrlEnter"]) => void | Promise<void>,
): void {
	let last_tab_id: number | undefined;
	glide.autocmds.create("UrlEnter", pattern, async (props) => {
		const is_tab_enter = last_tab_id !== props.tab_id;
		last_tab_id = props.tab_id;
		// only trigger on tab enter, not URL change within same tab
		if (is_tab_enter) {
			await callback(props);
		}
	});
}

// It's annoying to be in insert mode when switching tabs.
on_tab_enter({}, async ({ url }) => {
	if (url !== "about:newtab") {
		// HACK: sleep is needed when switching tabs quickly, otherwise `mode_change normal` may not take effect
		await new Promise((resolve) => setTimeout(resolve, 50));
		await glide.excmds.execute("mode_change normal");
	}
});

// https://github.com/glide-browser/glide/discussions/30#discussioncomment-14661338
async function focus_page() {
	// HACK: defocus the editable element by focusing the address bar and then
	// refocusing the page
	await glide.keys.send("<F6>", { skip_mappings: true });
	await new Promise((resolve) => setTimeout(resolve, 100));
	// check insert mode for address bar
	if (glide.ctx.mode === "insert") {
		await glide.keys.send("<F6>", { skip_mappings: true });
	}
}

glide.autocmds.create("CommandLineExit", focus_page);
glide.keymaps.set("normal", "<Esc>", async () => {
	await glide.keys.send("<Esc>", { skip_mappings: true });

	if (await glide.ctx.is_editing()) {
		await focus_page();
	}
});

const cmd_tab_edit = glide.excmds.create({ name: "tab_edit", description: "Edit tabs in a text editor" }, async () => {
	const tabs = await browser.tabs.query({ pinned: false });

	const tab_lines = tabs.map((tab) => {
		const title = tab.title?.replace(/\n/g, " ") || "No Title";
		const url = tab.url || "about:blank";
		return `${tab.id}: ${title} (${url})`;
	});

	const mktempcmd = await glide.process.execute("mktemp", ["-t", "glide_tab_edit.XXXXXX"]);
	const temp_filepath = (await mktempcmd.stdout.text()).trim();

	tab_lines.unshift("// Delete the corresponding lines to close the tabs");
	tab_lines.unshift("// vim: ft=qute-tab-edit");
	tab_lines.unshift("");
	await glide.fs.write(temp_filepath, tab_lines.join("\n"));

	console.log("Temp file created at:", temp_filepath);
	// --args --width-percent 70 --height-percent 60 --center
	await glide.process.execute("open", [
		"-W",
		"-a",
		"Nvimify.app",
		"-n",
		`${temp_filepath}`,
		"--args",
		"--width-percent",
		"50",
		"--height-percent",
		"60",
		"--center",
	]);

	// read the edited file
	const edited_content = await glide.fs.read(temp_filepath, "utf8");
	const edited_lines = edited_content
		.split("\n")
		.filter((line) => line.trim().length > 0)
		.filter((line) => !line.startsWith("//"));

	const tabs_to_keep = edited_lines.map((line) => {
		const tab_id = line.split(":")[0];
		return Number(tab_id);
	});

	const tab_ids_to_close = tabs
		.filter((tab) => tab.id && !tabs_to_keep.includes(tab.id))
		.map((tab) => tab.id)
		.filter((id): id is number => id !== undefined);
	await browser.tabs.remove(tab_ids_to_close);
});

declare global {
	interface ExcmdRegistry {
		tab_edit: typeof cmd_tab_edit;
	}
}

let previousTabId: number | undefined;
browser.tabs.onActivated.addListener((activeInfo) => {
	previousTabId = activeInfo.previousTabId;
});

const cmd_b_hash = glide.excmds.create(
	{ name: "b#", description: "[b]uffer [#]alternate -> switch to previously active tab" },
	async () => {
		if (previousTabId) {
			await browser.tabs.update(previousTabId, { active: true });
		}
	},
);

declare global {
	interface ExcmdRegistry {
		"b#": typeof cmd_b_hash;
	}
}

const cmd_noh = glide.excmds.create(
	{ name: "noh", description: "[no] [h]ighlight -> clear find highlights" },
	async () => {
		await browser.find.removeHighlighting();
	},
);

declare global {
	interface ExcmdRegistry {
		noh: typeof cmd_noh;
	}
}

const cmd_tabo = glide.excmds.create(
	{ name: "tabo", description: "[tab] [o]nly -> close all non-active non-pinned tabs" },
	async () => {
		const tabs_to_close = await browser.tabs.query({ active: false, pinned: false });
		await browser.tabs.remove(tabs_to_close.map((t) => t.id).filter((id): id is number => id !== undefined));
	},
);

declare global {
	interface ExcmdRegistry {
		tabo: typeof cmd_tabo;
	}
}

const REDDIT_EXCLUDED_PATHS =
	/^\/(media|mod|poll|settings|topics|community-points|appeals?|notifications|message\/compose\/|r\/[a-zA-Z0-9_]+\/s\/)/;

browser.webRequest.onBeforeRequest.addListener(
	(details) => {
		const url = new URL(details.url);
		if (url.hostname === "old.reddit.com" || url.hostname === "sh.reddit.com") {
			return {};
		}
		if (REDDIT_EXCLUDED_PATHS.test(url.pathname)) {
			return {};
		}
		if (url.pathname.startsWith("/gallery/")) {
			const id = url.pathname.replace("/gallery/", "");
			return { redirectUrl: `https://old.reddit.com/comments/${id}` };
		}
		url.hostname = "old.reddit.com";
		return { redirectUrl: url.toString() };
	},
	{ urls: ["*://*.reddit.com/*"] },
	["blocking"],
);
