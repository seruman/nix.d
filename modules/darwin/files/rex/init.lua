rex.bind("cmd+p", "client.palette.toggle")
rex.bind("ctrl+k", "com.superlogical.terminal.clear")
rex.bind("ctrl+b", "client.mode.enter", { name = "prefix", once = true })

rex.mode("prefix", { exclusive = true })
rex.bind("prefix/\\", "pane.split", { direction = "right" })
rex.bind("prefix/-", "pane.split", { direction = "down" })
rex.bind("prefix/o", "session.switch")
rex.bind("prefix/x", "client.close")
rex.action({
	name = "detach_block",
	title = "Detach Block",
	description = "Detach the pane without stopping its process",
	run = function(ctx)
		if not ctx.block_id then return end
		local _, err = rex.session.detach_block({ block_id = ctx.block_id })
		if err then error(err, 0) end
	end,
})
rex.bind("prefix/d", "detach_block")
rex.action({
	name = "attach_block",
	title = "Attach Block",
	description = "Attach a detached block in a split or new tab",
	keywords = "attach reattach recover split tab",
	args = { selected_block_id = "string?", placement = "string?" },
	run = require("restore"),
})
rex.bind("prefix/z", "pane.zoom")
rex.bind("prefix/h", "pane.focus", { direction = "left" })
rex.bind("prefix/j", "pane.focus", { direction = "down" })
rex.bind("prefix/k", "pane.focus", { direction = "up" })
rex.bind("prefix/l", "pane.focus", { direction = "right" })
rex.bind("prefix/c", "client.tab.new")
rex.bind("prefix/n", "client.tab.next")
rex.bind("prefix/p", "client.tab.previous")
for index = 1, 9 do
	rex.bind("prefix/" .. index, "client.tab.goto", { index = index })
end
rex.bind("prefix/shift+.", "client.tab.move", { direction = "forward" })
rex.bind("prefix/shift+,", "client.tab.move", { direction = "backward" })
rex.bind("prefix//", "client.find.open")
rex.bind("prefix/r", "client.mode.enter", { name = "resize" })
rex.bind("prefix/escape", "client.mode.exit_all")

rex.mode("resize", { exclusive = true })
rex.bind("resize/h", "pane.resize", { direction = "left", amount = 2 })
rex.bind("resize/j", "pane.resize", { direction = "down", amount = 2 })
rex.bind("resize/k", "pane.resize", { direction = "up", amount = 2 })
rex.bind("resize/l", "pane.resize", { direction = "right", amount = 2 })
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit_all")
rex.bind("resize/escape", "client.mode.exit_all")
