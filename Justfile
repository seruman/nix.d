set shell := ["/usr/bin/env", "bash", "-euo", "pipefail", "-c"]

flake := ".#dumpedcore"
system := ".#darwinConfigurations.dumpedcore.system"
rebuild := "/run/current-system/sw/bin/darwin-rebuild"
nixpi := "seruman@nixpi.local"
nixpi-target := "/etc/nixos"
keepy-bin := "/var/lib/keepy/bin/keep"
nix-files := "flake.nix modules/darwin/*.nix modules/darwin/home/*.nix modules/darwin/packages/*.nix hosts/darwin/dumpedcore/*.nix hosts/nixos/nixpi/*.nix"
fish-files := "modules/darwin/files/fish/config.fish modules/darwin/files/fish/conf.d/*.fish modules/darwin/files/fish/functions/*.fish modules/darwin/files/fish/completions/*.fish modules/darwin/files/fish/pkg/*.fish"

_default:
    just --list

# Build the nix-darwin system without switching.
build:
    nix build {{system}} --no-link --print-out-paths

# Build and activate the nix-darwin system.
switch:
    sudo {{rebuild}} switch --flake {{flake}}

# Build the system and show the resulting activation script path.
activate-path:
    out=$(nix build {{system}} --no-link --print-out-paths); echo "$out/activate"

# Check formatting and buildability.
check:
    nix fmt -- --check {{nix-files}}
    fish -n {{fish-files}}
    fish_indent --check {{fish-files}}
    nix build {{system}} --no-link --print-out-paths
    nix eval .#nixosConfigurations.nixpi.config.system.build.toplevel.drvPath

# Format Nix and fish files.
fmt:
    nix fmt {{nix-files}}
    fish_indent --write {{fish-files}}

# Update flake inputs.
update:
    nix flake update

# Remove old Homebrew downloads, caches, and stale lock files.
brew-cleanup:
    brew cleanup --prune=all -s

# Show current generation target.
current:
    readlink /run/current-system

# Copy this flake to nixpi and activate it there.
nixpi-switch:
    rsync -az --delete --rsync-path='sudo rsync' --exclude .git --exclude result --exclude TODO.md ./ {{nixpi}}:{{nixpi-target}}/
    ssh {{nixpi}} 'sudo nixos-rebuild switch --flake {{nixpi-target}}#nixpi'

# Stream keepy service logs from nixpi.
nixpi-keepy-logs:
    ssh {{nixpi}} 'sudo journalctl -u keepy.service -f'

# Show keepy service status on nixpi.
nixpi-keepy-status:
    ssh {{nixpi}} 'sudo systemctl status keepy.service --no-pager'

# Copy a built keepy binary to nixpi and restart the service.
nixpi-install-keepy localbin:
    scp {{localbin}} {{nixpi}}:/tmp/keep
    ssh {{nixpi}} 'sudo install -o keepy -g keepy -m 0755 /tmp/keep {{keepy-bin}} && rm -f /tmp/keep && sudo systemctl restart keepy.service'
