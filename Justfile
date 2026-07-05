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

# Build the nix-darwin system without switching.
build:
    nix build {{ system }} --no-link --print-out-paths

# Build and activate the nix-darwin system.
switch:
    sudo {{ rebuild }} switch --flake {{ flake }}

# Build the system and show the resulting activation script path.
activate-path:
    out=$(nix build {{ system }} --no-link --print-out-paths); echo "$out/activate"

# Check formatting and buildability.
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

# Format Nix, fish, and just files.
fmt:
    just --fmt
    nix fmt $(git ls-files '*.nix')
    fish_indent --write $(git ls-files '*.fish')

# Update flake inputs.
update:
    nix flake update

# Remove old Homebrew downloads, caches, and stale lock files.
brew-cleanup:
    brew cleanup --prune=all -s

# Show current generation target.
current:
    readlink /run/current-system

# Fetch this flake on nixpi and activate it there.
nixpi-switch:
    ssh {{ nixpi }} 'cd {{ nixpi-repo }} && git fetch origin main && git reset --hard origin/main && sudo nixos-rebuild switch --flake .#nixpi'

# Stream service logs from nixpi.
nixpi-logf service:
    ssh {{ nixpi }} 'sudo journalctl -u {{ service }} -f'

# Show service status on nixpi.
nixpi-status service:
    ssh {{ nixpi }} 'sudo systemctl status {{ service }} --no-pager'

# Copy a built keepy binary to nixpi and restart the service.
nixpi-install-keepy localbin:
    scp {{ localbin }} {{ nixpi }}:/tmp/keep
    ssh {{ nixpi }} 'sudo install -o keepy -g keepy -m 0755 /tmp/keep {{ keepy-bin }} && rm -f /tmp/keep && sudo systemctl restart keepy.service'
