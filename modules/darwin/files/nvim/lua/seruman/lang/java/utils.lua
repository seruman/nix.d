local M = {}

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

function M.ensure_lombok(workspace_dir)
	local lombok_path = workspace_dir .. "/lombok.jar"
	if vim.fn.filereadable(lombok_path) ~= 1 then
		vim.notify("Lombok jar not found. Downloading...", vim.log.levels.INFO)
		vim.fn.system({
			"curl",
			"-L",
			"https://projectlombok.org/downloads/lombok.jar",
			"-o",
			lombok_path,
		})
	end
	return lombok_path
end

-- Build the JDTLS `runtimes` list from environment variables.
--
-- Sources:
--   * JAVA_HOME — the active default JDK. Major version probed via `java -version`.
--   * JAVA_HOME_<major> (e.g. JAVA_HOME_11, JAVA_HOME_17) — additional JDKs.
--     The major version is read directly from the env var name.
--
-- The default flag goes to the runtime whose major matches `project_java_version`
-- if provided; otherwise to JAVA_HOME's runtime.
function M.get_java_runtimes(java_home, project_java_version)
	local runtimes = {}
	local seen = {}

	local function add(major, path, is_active)
		local name = java_runtime_name(major)
		if not name or not path or vim.fn.isdirectory(path) ~= 1 then
			return
		end
		if seen[name] then
			return
		end
		seen[name] = true
		table.insert(runtimes, {
			name = name,
			path = path,
			default = (project_java_version ~= nil and major == project_java_version)
				or (project_java_version == nil and is_active),
		})
	end

	-- JAVA_HOME: the active default.
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
			path = java_home,
			default = true,
		})
	end

	-- If nothing got marked default (e.g. project version provided but none matched),
	-- fall back to the JAVA_HOME entry, then the first.
	local has_default = false
	for _, rt in ipairs(runtimes) do
		if rt.default then
			has_default = true
			break
		end
	end
	if not has_default then
		runtimes[1].default = true
	end

	return runtimes
end

return M
