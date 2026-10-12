local must = require("utils").must

return function(_, args)
	local session_id
	for _, session in ipairs(must(rex.call("session.list")).sessions or {}) do
		if session.label == args.label then
			session_id = session.session_id
			break
		end
	end

	local layout = rex.layout.block({
		flavor = "com.superlogical.terminal.shell",
		options = { cwd = args.cwd },
	})
	local window
	if session_id then
		must(rex.call("session.attach", { session_id = session_id }))
		window = must(rex.session.new_window({ session_id = session_id, layout = layout }))
	else
		local session = must(rex.call("session.create", {
			label = args.label,
			initial_windows = { { layout = layout } },
		}))
		session_id, window = session.session_id, session.initial_windows[1]
	end

	rex.client.queue("session.select", { session_id = session_id, window_id = window.window_id })
	return { session_id = session_id, window_id = window.window_id }
end
