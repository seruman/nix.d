local M = {}

local home = vim.env.HOME

function M.get_sdkman_java_versions()
	local sdkman_java_dir = home .. "/.sdkman/candidates/java"
	local java_version_pattern = "(%d+)%.(%d+)%.(%d+)[%-_]?([^/]*)"

	if vim.fn.isdirectory(sdkman_java_dir) ~= 1 then
		return {}
	end

	local found_versions = {}

	for name, type in vim.fs.dir(sdkman_java_dir) do
		if type == "directory" and name ~= "current" then
			local path = sdkman_java_dir .. "/" .. name
			local major = name:match(java_version_pattern)
			if major then
				major = tonumber(major)
				table.insert(found_versions, {
					path = path,
					version = name,
					major = major,
					is_default = vim.fn.isdirectory(sdkman_java_dir .. "/current") == 1
						and vim.fn.resolve(sdkman_java_dir .. "/current") == path,
				})
			end
		end
	end

	table.sort(found_versions, function(a, b)
		return a.major > b.major
	end)

	return found_versions
end

function M.find_java_home()
	local versions = M.get_sdkman_java_versions()

	if #versions > 0 then
		return versions[1].path
	end

	if vim.env.JAVA_HOME and vim.fn.isdirectory(vim.env.JAVA_HOME) == 1 then
		return vim.env.JAVA_HOME
	end

	local java_path = vim.fn.exepath("java")
	if java_path ~= "" then
		-- Extract JAVA_HOME from the java path (remove /bin/java)
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

	return 17
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
			"curl", "-L",
			"https://projectlombok.org/downloads/lombok.jar",
			"-o", lombok_path,
		})
	end
	return lombok_path
end

function M.get_java_runtimes(java_home, project_java_version)
	local runtimes = {}
	local versions = M.get_sdkman_java_versions()

	local function java_runtime_name(major)
		if major == 8 then return "JavaSE-1.8" end
		if major >= 9 then return string.format("JavaSE-%d", major) end
		return nil
	end

	for _, version in ipairs(versions) do
		local name = java_runtime_name(version.major)
		if name then
			table.insert(runtimes, {
				name = name,
				path = version.path,
				default = (version.major == project_java_version)
					or (project_java_version == nil and version.is_default)
					or (#runtimes == 0 and not project_java_version),
			})
		end
	end

	if vim.env.JAVA_HOME and vim.fn.isdirectory(vim.env.JAVA_HOME) == 1 then
		local result = vim.system({ vim.env.JAVA_HOME .. "/bin/java", "-version" }, { text = true }):wait()
		if result.code == 0 then
			-- java -version outputs to stderr
			local output = result.stderr or result.stdout or ""
			local major = output:match('version%s+"(%d+)')
			if major then
				major = tonumber(major)
				local name = java_runtime_name(major)

				local has_version = false
				for _, runtime in ipairs(runtimes) do
					if runtime.name == name then
						has_version = true
						break
					end
				end

				if not has_version and name then
					table.insert(runtimes, {
						name = name,
						path = vim.env.JAVA_HOME,
						default = major == project_java_version and #runtimes == 0,
					})
				end
			end
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

	return runtimes
end

return M
