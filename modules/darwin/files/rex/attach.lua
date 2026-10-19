-- Run the working-tree picker without rebuilding or reloading Rex:
-- rex do /Users/selman/etc/nix/modules/darwin/files/rex/attach.lua
-- rex do puts this script's directory on package.path.
rex.action({
	name = "attach_block",
	title = "Attach Block",
	args = { selected_block_id = "string?", placement = "string?" },
	run = require("restore"),
})

return require("utils").must(rex.invoke("attach_block", rex.args))
