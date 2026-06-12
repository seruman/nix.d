type Address = `http://${string}` | `https://${string}`;
type GitHubParams = {
	addr: Address;
	org: string;
	repo: string;
	issue?: string;
	pr?: string;
};

function github_params(url: URL): GitHubParams | null {
	const PROJECTS_URL_PATTERN = /https:\/\/github(.*)\.com\/orgs\/(.+)\/projects\/(\d+)/;
	const DEFAULT_PATTERN = /https:\/\/github(.*)\.com\/(.+)\/(.+)/;
	const ISSUE_OR_PR_NUMBER_PATTERN = /^\d+$/;

	const addr = `${url.protocol}//${url.host}` as Address;

	if (PROJECTS_URL_PATTERN.test(url.href)) {
		const match = url.href.match(PROJECTS_URL_PATTERN);
		if (!match) return null;

		const issueQuery = url.searchParams.get("issue") ?? "";
		if (!issueQuery) return null;

		const [org, repo, issue] = issueQuery.split("|");
		if (!org || !repo || !issue || !ISSUE_OR_PR_NUMBER_PATTERN.test(issue)) return null;

		return { addr, org, repo, issue };
	}

	if (DEFAULT_PATTERN.test(url.href)) {
		const match = url.href.match(DEFAULT_PATTERN);
		if (!match) return null;

		const path = url.pathname.slice(1).split("/");
		if (path.length < 2) return null;

		const org = path[0];
		const repo = path[1];
		if (!org || !repo) return null;

		const resource = path[2];
		const id = path[3];
		if (resource === "issues" && id && ISSUE_OR_PR_NUMBER_PATTERN.test(id)) {
			return { addr, org, repo, issue: id };
		}
		if (resource === "pull" && id && ISSUE_OR_PR_NUMBER_PATTERN.test(id)) {
			return { addr, org, repo, pr: id };
		}

		return { addr, org, repo };
	}

	return null;
}

function github_open(path_fn: (params: GitHubParams) => string, new_tab: boolean) {
	return async ({ tab_id }: { tab_id: number }) => {
		const params = github_params(glide.ctx.url);
		if (!params) return;
		const url = path_fn(params);
		if (new_tab) {
			await browser.tabs.create({ url, active: true, openerTabId: tab_id });
		} else {
			await browser.tabs.update(tab_id, { url });
		}
	};
}

function github_yank_issue() {
	return async () => {
		const params = github_params(glide.ctx.url);
		if (!params?.issue) {
			await browser.notifications.create({
				type: "basic",
				title: "Glide",
				message: "No GitHub issue found on this page",
			});
			return;
		}

		await navigator.clipboard.writeText(issues_path(params));
		await browser.notifications.create({
			type: "basic",
			title: "Glide",
			message: "GitHub issue URL copied to clipboard",
		});
	};
}

const repo_path = (p: GitHubParams) => `${p.addr}/${p.org}/${p.repo}`;
const issues_path = (p: GitHubParams) => (p.issue ? `${repo_path(p)}/issues/${p.issue}` : `${repo_path(p)}/issues`);
const pulls_path = (p: GitHubParams) => (p.pr ? `${repo_path(p)}/pull/${p.pr}` : `${repo_path(p)}/pulls`);
const actions_path = (p: GitHubParams) => `${repo_path(p)}/actions`;
const discussions_path = (p: GitHubParams) => `${repo_path(p)}/discussions`;
const commits_path = (p: GitHubParams) => `${repo_path(p)}/commits`;
const branches_path = (p: GitHubParams) => `${repo_path(p)}/branches`;
const tags_path = (p: GitHubParams) => `${repo_path(p)}/tags`;
const godoc_path = (p: GitHubParams) => `https://pkg.go.dev/github.com/${p.org}/${p.repo}`;

glide.autocmds.create("UrlEnter", /https:\/\/github(.*)\.com/, () => {
	glide.buf.keymaps.set("normal", "<C-g>i", github_open(issues_path, false), {
		description: "Open GitHub issues in current tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>I", github_open(issues_path, true), {
		description: "Open GitHub issues in a new tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>yi", github_yank_issue(), {
		description: "Copy the resolved GitHub issue URL to the clipboard",
	});
	glide.buf.keymaps.set("normal", "<C-g>r", github_open(repo_path, false), {
		description: "Open GitHub repo root in current tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>R", github_open(repo_path, true), {
		description: "Open GitHub repo root in a new tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>p", github_open(pulls_path, false), {
		description: "Open GitHub PRs in current tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>P", github_open(pulls_path, true), {
		description: "Open GitHub PRs in a new tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>a", github_open(actions_path, false), {
		description: "Open GitHub Actions in current tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>A", github_open(actions_path, true), {
		description: "Open GitHub Actions in a new tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>d", github_open(discussions_path, false), {
		description: "Open GitHub Discussions in current tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>D", github_open(discussions_path, true), {
		description: "Open GitHub Discussions in a new tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>c", github_open(commits_path, false), {
		description: "Open GitHub commits in current tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>C", github_open(commits_path, true), {
		description: "Open GitHub commits in a new tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>b", github_open(branches_path, false), {
		description: "Open GitHub branches in current tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>B", github_open(branches_path, true), {
		description: "Open GitHub branches in a new tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>t", github_open(tags_path, false), {
		description: "Open GitHub tags in current tab",
	});
	glide.buf.keymaps.set("normal", "<C-g>T", github_open(tags_path, true), {
		description: "Open GitHub tags in a new tab",
	});
});

glide.autocmds.create("UrlEnter", { hostname: "github.com" }, () => {
	glide.buf.keymaps.set("normal", "<C-g>g", github_open(godoc_path, false), {
		description: "Open Go docs for this repo",
	});
	glide.buf.keymaps.set("normal", "<C-g>G", github_open(godoc_path, true), {
		description: "Open Go docs for this repo in a new tab",
	});
});
