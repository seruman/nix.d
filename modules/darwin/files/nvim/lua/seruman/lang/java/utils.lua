local M = {}

-- Optional Nix-generated tool paths; falls back to env when absent.
local nix_paths_loaded, nix_paths_cache = false, nil
local function nix_paths()
	if not nix_paths_loaded then
		nix_paths_loaded = true
		local path = vim.fn.expand("~/.config/nvim-nix/paths.lua")
		if vim.fn.filereadable(path) == 1 then
			local ok, result = pcall(dofile, path)
			if ok and type(result) == "table" then
				nix_paths_cache = result
			end
		end
	end
	return nix_paths_cache
end
M.nix_paths = nix_paths

local function probe_java_major(java_home)
	if not java_home or vim.fn.isdirectory(java_home) ~= 1 then
		return nil
	end
	local java_bin = java_home .. "/bin/java"
	if vim.fn.executable(java_bin) ~= 1 then
		return nil
	end
	-- `java -version` writes to stderr.
	local result = vim.system({ java_bin, "-version" }, { text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	local output = result.stderr or result.stdout or ""
	local major = output:match('version%s+"(%d+)')
	return major and tonumber(major) or nil
end

local function java_runtime_name(major)
	if major == 8 then
		return "JavaSE-1.8"
	end
	if major and major >= 9 then
		return string.format("JavaSE-%d", major)
	end
	return nil
end

function M.find_java_home()
	local nix = nix_paths()
	if nix and nix.java and vim.fn.isdirectory(nix.java) == 1 then
		return nix.java
	end

	if vim.env.JAVA_HOME and vim.fn.isdirectory(vim.env.JAVA_HOME) == 1 then
		return vim.env.JAVA_HOME
	end

	local java_path = vim.fn.exepath("java")
	if java_path ~= "" then
		-- ${java_home}/bin/java -> ${java_home}
		return vim.fn.fnamemodify(java_path, ":h:h")
	end

	local result = vim.system({ "/usr/libexec/java_home" }, { text = true }):wait()
	if result.code == 0 then
		return vim.trim(result.stdout)
	end

	return nil
end

function M.detect_project_java_version(root_dir)
	local version_files = {
		".java-version",
		".sdkmanrc",
		".tool-versions",
		"build.gradle",
		"pom.xml",
	}

	for _, file in ipairs(version_files) do
		local file_path = root_dir .. "/" .. file
		if vim.fn.filereadable(file_path) == 1 then
			local handle = io.open(file_path, "r")
			if handle then
				local content = handle:read("*all")
				handle:close()

				local version_patterns = {
					"sourceCompatibility%s*=%s*['\"]([%d%.]+)['\"]", -- Gradle
					"<java%.version>([%d%.]+)</java%.version>", -- Maven
					"languageVersion%s*=%s*JavaLanguageVersion%.of%((%d+)%)", -- Gradle toolchain
					"java=([%d%.]+)", -- .sdkmanrc
					"java%s+([%d%.]+)", -- .tool-versions
					"^([%d%.]+)$", -- .java-version
				}

				for _, pattern in ipairs(version_patterns) do
					local match = string.match(content, pattern)
					if match then
						local major = string.match(match, "^(%d+)")
						if major then
							return tonumber(major)
						end
					end
				end
			end
		end
	end

	return nil
end

local function sha256_file(filepath)
	local result = vim.system({ "sha256sum", filepath }, { text = true }):wait()
	if result.code == 0 then
		return result.stdout:match("%w+")
	end

	result = vim.system({ "openssl", "dgst", "-sha256", filepath }, { text = true }):wait()
	if result.code == 0 then
		return result.stdout:match("%w+$")
	end

	return nil
end

function M.setup_gradle_checksums(root_dir, trusted_checksums, save_checksums_func)
	local checksum_entries = {}
	for _, cs in ipairs(trusted_checksums) do
		table.insert(checksum_entries, {
			sha256 = cs,
			allowed = true,
		})
	end

	local gradle_wrapper_jar = root_dir .. "/gradle/wrapper/gradle-wrapper.jar"
	if vim.fn.filereadable(gradle_wrapper_jar) == 1 then
		local checksum = sha256_file(gradle_wrapper_jar)

		if checksum and not vim.tbl_contains(trusted_checksums, checksum) then
			vim.defer_fn(function()
				local choice = vim.fn.confirm("Trust Gradle wrapper with checksum: " .. checksum .. "?", "&Yes\n&No", 1)

				if choice == 1 then
					table.insert(trusted_checksums, checksum)
					save_checksums_func()

					local clients = vim.lsp.get_clients({ name = "jdtls" })
					if clients and #clients > 0 then
						clients[1]:stop()
					end

					vim.defer_fn(function()
						vim.cmd("edit")
					end, 500)

					vim.notify("Gradle checksum trusted and saved. JDTLS will restart.", vim.log.levels.INFO)
				else
					vim.notify("Gradle checksum not trusted. Some JDTLS features may not work.", vim.log.levels.WARN)
				end
			end, 100)
		end
	end

	return checksum_entries
end

function M.find_lombok()
	local nix = nix_paths()
	if nix and nix.lombok and vim.fn.filereadable(nix.lombok) == 1 then
		return nix.lombok
	end

	if vim.env.LOMBOK_JAR and vim.fn.filereadable(vim.env.LOMBOK_JAR) == 1 then
		return vim.env.LOMBOK_JAR
	end
	return nil
end

-- Build the JDTLS `runtimes` list.
--
-- Sources, in order:
--   * nix_paths().runtimes — JDKs declared by the nix config, each with an explicit
--     `major`.
--   * JAVA_HOME — the active JDK, major probed via `java -version`.
--   * JAVA_HOME_<major> (e.g. JAVA_HOME_11, JAVA_HOME_17) — additional JDKs.
--
-- Entries carry `major` for callers; strip it before sending them to JDTLS.
-- The default flag goes to the runtime whose major matches `project_java_version`
-- if provided, otherwise to the first runtime declaring itself default.
function M.get_java_runtimes(java_home, project_java_version)
	local runtimes = {}
	local seen = {}

	local function add(major, path, is_active)
		local name = java_runtime_name(major)
		if not name or not path or vim.fn.isdirectory(path) ~= 1 then
			return
		end
		if seen[major] then
			return
		end
		seen[major] = true
		table.insert(runtimes, {
			name = name,
			major = major,
			path = path,
			default = (project_java_version ~= nil and major == project_java_version)
				or (project_java_version == nil and is_active),
		})
	end

	local nix = nix_paths()
	if nix and type(nix.runtimes) == "table" then
		for _, rt in ipairs(nix.runtimes) do
			add(rt.major, rt.path, rt.default == true)
		end
	end

	-- JAVA_HOME: the active JDK, which a project shell may have overridden.
	local active_home = vim.env.JAVA_HOME
	if active_home and vim.fn.isdirectory(active_home) == 1 then
		add(probe_java_major(active_home), active_home, true)
	end

	-- JAVA_HOME_<major>: additional declared runtimes.
	for name, value in pairs(vim.fn.environ()) do
		local suffix = name:match("^JAVA_HOME_(%d+)$")
		if suffix and value ~= "" then
			add(tonumber(suffix), value, false)
		end
	end

	if #runtimes == 0 then
		vim.notify("No Java runtimes found. JDTLS may not work properly.", vim.log.levels.WARN)
		table.insert(runtimes, {
			name = "JavaSE-17",
			major = 17,
			path = java_home,
			default = true,
		})
	end

	-- JDTLS accepts a single default, so keep the first one only.
	local has_default = false
	for _, rt in ipairs(runtimes) do
		if rt.default and has_default then
			rt.default = false
		elseif rt.default then
			has_default = true
		end
	end
	if not has_default then
		runtimes[1].default = true
	end

	return runtimes
end

-- JDK the Gradle daemon should run on.
--
-- Gradle only auto-detects toolchains in well-known locations, so a build requesting
-- a toolchain the daemon JVM does not provide fails to import with
-- ToolchainDownloadFailedException. Running the daemon on the project's own JDK makes
-- it a candidate. Returns nil when nothing matches, leaving JDTLS to pick.
function M.find_gradle_java_home(runtimes, project_java_version)
	if project_java_version == nil then
		return nil
	end

	for _, rt in ipairs(runtimes) do
		if rt.major == project_java_version then
			return rt.path
		end
	end

	return nil
end

-- JDTLS only knows name/path/default; drop the bookkeeping fields.
function M.to_jdtls_runtimes(runtimes)
	local out = {}
	for _, rt in ipairs(runtimes) do
		table.insert(out, { name = rt.name, path = rt.path, default = rt.default })
	end
	return out
end

return M
