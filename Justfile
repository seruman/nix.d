set shell := ["/usr/bin/env", "bash", "-euo", "pipefail", "-c"]

flake := ".#dumpedcore"
system := ".#darwinConfigurations.dumpedcore.system"
rebuild := "/run/current-system/sw/bin/darwin-rebuild"
nixpi := env_var_or_default("NIXPI_HOST", "nixpi")
nixpi-repo := env_var_or_default("NIXPI_REPO", "~/etc/nix")
keepy-bin := "/var/lib/keepy/bin/keep"
local-package-checks := ".#checks.aarch64-darwin.bttf .#checks.aarch64-darwin.cloudflareCf .#checks.aarch64-darwin.gitHunks .#checks.aarch64-darwin.glimpseui .#checks.aarch64-darwin.wb"

_default:
    just --list

build:
    nix build {{ system }} --no-link --print-out-paths

switch:
    sudo {{ rebuild }} switch --flake {{ flake }}

activate-path:
    out=$(nix build {{ system }} --no-link --print-out-paths); echo "$out/activate"

check:
    just --fmt --check
    nix fmt -- --check $(git ls-files '*.nix')
    nix shell --inputs-from . nixpkgs-unstable#deadnix -c deadnix --fail $(git ls-files '*.nix')
    nix shell --inputs-from . nixpkgs-unstable#statix -c statix check .
    fish -n $(git ls-files '*.fish')
    fish_indent --check $(git ls-files '*.fish')
    nix build {{ local-package-checks }} --no-link --print-out-paths
    nix build {{ system }} --no-link --print-out-paths
    nix eval .#nixosConfigurations.nixpi.config.system.build.toplevel.drvPath

fmt:
    just --fmt
    nix fmt $(git ls-files '*.nix')
    fish_indent --write $(git ls-files '*.fish')

update:
    nix flake update

brew-cleanup:
    brew cleanup --prune=all -s

current:
    readlink /run/current-system

nixpi-switch:
    ssh {{ nixpi }} 'cd {{ nixpi-repo }} && git fetch origin main && git reset --hard origin/main && sudo nixos-rebuild switch --flake .#nixpi'

nixpi-logf service:
    ssh {{ nixpi }} 'sudo journalctl -u {{ service }} -f'

nixpi-status service:
    ssh {{ nixpi }} 'sudo systemctl status {{ service }} --no-pager'

nixpi-install-keepy localbin:
    scp {{ localbin }} {{ nixpi }}:/tmp/keep
    ssh {{ nixpi }} 'sudo install -o keepy -g keepy -m 0755 /tmp/keep {{ keepy-bin }} && rm -f /tmp/keep && sudo systemctl restart keepy.service'
