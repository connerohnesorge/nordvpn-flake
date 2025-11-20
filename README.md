# nordvpn-flake

A NixOS flake providing the NordVPN client package and a NixOS module for easy system integration.

## Features

- 📦 NordVPN client package for NixOS
- 🔧 NixOS module for system-wide VPN configuration
- 🔒 Automatic firewall rule configuration
- 👥 User group management
- 🚀 Systemd service integration
- 🏗️ Support for x86_64-linux and aarch64-linux

## Installation

### As a Flake Input

Add this flake to your NixOS configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nordvpn-flake.url = "github:connerohnesorge/nordvpn-flake";
  };

  outputs = { nixpkgs, nordvpn-flake, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [
        nordvpn-flake.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### Configuration

Enable and configure NordVPN in your NixOS configuration:

```nix
{
  services.nordvpn = {
    enable = true;
    users = [ "youruser" ];  # Users to add to nordvpn group
  };
}
```

This will:
- Install the NordVPN client
- Configure systemd service for the NordVPN daemon
- Set up necessary firewall rules (TCP 443, UDP 1194)
- Add specified users to the `nordvpn` group
- Configure `networking.firewall.checkReversePath = false`

#### Example Configuration

See [dotfiles](https://github.com/connerohnesorge/dotfiles) for a complete example configuration namely [`flake.nix`](https://github.com/connerohnesorge/dotfiles/blob/main/flake.nix) and [`engineer.nix`](https://github.com/connerohnesorge/dotfiles/blob/main/modules/features/engineer.nix).

## Usage

After rebuilding your system:

```bash
# Log in to your NordVPN account
nordvpn login

# Connect to a server
# nordvpn connect
nordvpn c 

# Check connection status
nordvpn status

# Disconnect
nordvpn disconnect
```

## Building from Source

### Build the Package

```bash
nix build .#nordvpn
```

### Run Directly

```bash
nix run .#nordvpn -- --help
```

## Development

This flake includes a development shell with useful Nix tools:

```bash
nix develop
```

Available development commands:
- `nix build .#nordvpn` - Build the package
- `nix flake check` - Check flake validity
- `nixfmt-rfc-style .` - Format nix files
- `statix check .` - Check for common nix issues
- `deadnix .` - Find dead code in nix files

## Requirements

- NixOS with flakes enabled
- x86_64-linux or aarch64-linux system

## License

MIT License - see [LICENSE](LICENSE) for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Notes

- This flake requires `allowUnfree = true` as NordVPN is proprietary software
- The NordVPN daemon runs as a system service and requires root privileges
- Users must be in the `nordvpn` group to interact with the VPN client
