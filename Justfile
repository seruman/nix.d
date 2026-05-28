set shell := ["/usr/bin/env", "bash", "-euo", "pipefail", "-c"]

flake := ".#dumpedcore"
system := ".#darwinConfigurations.dumpedcore.system"
rebuild := "/run/current-system/sw/bin/darwin-rebuild"

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
    nixfmt --check flake.nix hosts/darwin/dumpedcore/*.nix hosts/darwin/dumpedcore/home/*.nix
    nix build {{system}} --no-link --print-out-paths

# Format Nix files.
fmt:
    nixfmt flake.nix hosts/darwin/dumpedcore/*.nix hosts/darwin/dumpedcore/home/*.nix

# Update flake inputs.
update:
    nix flake update

# Show current generation target.
current:
    readlink /run/current-system
