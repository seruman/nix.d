status is-interactive; or return

# The nixpkgs forgit plugin provides `git-forgit` as a Fish alias/function from
# vendor_conf.d, which is loaded after user conf.d. Register abbreviations
# unconditionally; the function will exist by the time the prompt is ready.

abbr -a -- ga git-forgit add
abbr -a -- grh git-forgit reset_head
abbr -a -- glo git-forgit log
abbr -a -- grl git-forgit reflog
abbr -a -- gd git-forgit diff
abbr -a -- gcf git-forgit checkout_file
abbr -a -- gcb git-forgit checkout_branch
abbr -a -- gbd git-forgit branch_delete
abbr -a -- gclean git-forgit clean
abbr -a -- gss git-forgit stash_show
abbr -a -- gsp git-forgit stash_push
abbr -a -- gcp git-forgit cherry_pick_from_branch
abbr -a -- grb git-forgit rebase
abbr -a -- gfu git-forgit fixup
abbr -a -- gco git-forgit checkout_commit
abbr -a -- grc git-forgit revert_commit
abbr -a -- gbl git-forgit blame
abbr -a -- gct git-forgit checkout_tag
# Intentionally no `gi` / other default forgit abbreviations.
