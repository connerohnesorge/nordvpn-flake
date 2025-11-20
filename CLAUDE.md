# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS flake that packages the proprietary NordVPN client and provides a NixOS service module for system integration. The flake handles compatibility challenges with the upstream Debian package, including legacy library dependencies and FHS environment requirements.

## Common Commands

### Building and Running
```bash
# Build the NordVPN package
nix build .#nordvpn

# Run NordVPN directly
nix run .#nordvpn -- --help

# Enter development shell
nix develop
```

### Development and Linting
```bash
# Check flake validity
nix flake check

# Format Nix files (RFC style)
nixfmt-rfc-style .

# Check for common Nix anti-patterns
statix check .

# Find dead code in Nix files
deadnix .

# Update flake inputs
nix flake update
```

### Testing Changes
```bash
# Test in a NixOS configuration
# Add to flake.nix inputs and use services.nordvpn.enable = true

# Build and test the package locally
nix build .#nordvpn
./result/bin/nordvpn --version
```

### Using the Overlay
```nix
# In your flake.nix:
{
  inputs.nordvpn-flake.url = "github:connerohnesorge/nordvpn-flake";
  
  outputs = { self, nixpkgs, nordvpn-flake, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        # Apply the overlay to make nordvpn available in pkgs
        { nixpkgs.overlays = [ nordvpn-flake.overlays.default ]; }
        # Your other modules...
      ];
    };
  };
}

# Then use in your configuration:
{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.nordvpn ];
}
```

## Architecture

### File Structure and Purpose

**Core Files:**
- `flake.nix` - Main flake definition that exports the package and NixOS module
- `nordvpn.nix` - Package derivation that downloads and patches the NordVPN Debian package
- `module.nix` - NixOS service module providing `services.nordvpn` configuration options

**Key Architectural Decisions:**

1. **FHS Environment**: Uses `buildFHSEnvChroot` to provide a traditional Linux filesystem hierarchy, required for the proprietary NordVPN binary to function correctly.

2. **Legacy Library Handling**: The package explicitly handles libxml2 2.9.x dependency by symlinking to newer versions, as the upstream binary expects older library versions.

3. **Binary Patching**: Uses `autoPatchelfHook` to automatically patch ELF binaries with correct library paths for NixOS.

4. **Service Architecture**: 
   - Runs `nordvpnd` as a system daemon
   - Creates `nordvpn` system group for access control
   - Opens required firewall ports (TCP 443, UDP 1194)
   - Provides systemd service management

### Configuration Flow

1. User adds flake to their system configuration
2. Enables `services.nordvpn.enable = true`
3. NixOS module:
   - Installs the nordvpn package system-wide
   - Creates systemd service for nordvpnd
   - Configures firewall rules
   - Sets up user groups
4. Users interact via `nordvpn` CLI command

### Development Notes

- The package version (3.18.3) is hardcoded in `nordvpn.nix` and should be updated when new versions are released
- SHA256 hashes must be updated when changing versions
- The FHS environment approach is necessary due to hardcoded paths in the proprietary binary
- Consider testing on both x86_64 and aarch64 architectures when making changes