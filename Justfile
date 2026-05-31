set shell := ["/usr/bin/env", "bash", "-euo", "pipefail", "-c"]

flake := ".#dumpedcore"
system := ".#darwinConfigurations.dumpedcore.system"
rebuild := "/run/current-system/sw/bin/darwin-rebuild"
nixpi := "seruman@nixpi.local"
nixpi-target := "/etc/nixos"

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
    nixfmt --check flake.nix hosts/darwin/dumpedcore/*.nix hosts/darwin/dumpedcore/home/*.nix hosts/nixos/nixpi/*.nix
    nix build {{system}} --no-link --print-out-paths
    nix eval .#nixosConfigurations.nixpi.config.system.build.toplevel.drvPath

# Format Nix files.
fmt:
    nixfmt flake.nix hosts/darwin/dumpedcore/*.nix hosts/darwin/dumpedcore/home/*.nix hosts/nixos/nixpi/*.nix

# Update flake inputs.
update:
    nix flake update

# Show current generation target.
current:
    readlink /run/current-system

# Copy this flake to nixpi and activate it there.
nixpi-switch:
    rsync -az --delete --rsync-path='sudo rsync' --exclude .git --exclude result --exclude TODO.md ./ {{nixpi}}:{{nixpi-target}}/
    ssh {{nixpi}} 'sudo nixos-rebuild switch --flake {{nixpi-target}}#nixpi'
