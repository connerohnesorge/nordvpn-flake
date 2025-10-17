{
  description = "NordVPN package and NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
    nordvpn-amd64-deb = {
      url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_4.2.0_amd64.deb";
      flake = false;
    };
    nordvpn-arm64-deb = {
      url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_4.2.0_arm64.deb";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    hercules-ci-effects,
    nordvpn-amd64-deb,
    nordvpn-arm64-deb,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"]
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        nordvpn = pkgs.callPackage ./nordvpn.nix {inherit nordvpn-amd64-deb nordvpn-arm64-deb;};
      in {
        packages = {
          default = nordvpn;
          inherit nordvpn;
        };

        apps = {
          default = {
            type = "app";
            meta = {
              description = "NordVPN CLI";
            };
            program = "${nordvpn}/bin/nordvpn";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixd
            nil
            alejandra
            statix
            deadnix
          ];
          shellHook = ''
            echo "NordVPN flake development environment"
            echo "Available commands:"
            echo "  nix build .#nordvpn - Build the package"
            echo "  nix flake check - Check flake validity"
            echo "  nixfmt-rfc-style . - Format nix files"
            echo "  statix check . - Check for common nix issues"
            echo "  deadnix . - Find dead code in nix files"
          '';
        };
      }
    )
    // {
      nixosModules = {
        default = self.nixosModules.nordvpn;
        nordvpn =
          import ./module.nix {inherit nordvpn-amd64-deb nordvpn-arm64-deb;};
      };
      overlays = {
        default = self.overlays.nordvpn;
        nordvpn = final: prev: {
          nordvpn = final.callPackage ./nordvpn.nix {
            inherit nordvpn-amd64-deb nordvpn-arm64-deb;
          };
        };
      };

      herculesCI = herculesCI: {
        ciSystems = ["x86_64-linux" "aarch64-linux"];
        onPush.default.outputs = {
          packages.x86_64-linux = ["nordvpn"];
          packages.aarch64-linux = ["nordvpn"];
          checks.x86_64-linux = ["all"];
          checks.aarch64-linux = ["all"];
        };
        onSchedule.update = {
          when = {
            hour = [2];
            dayOfWeek = ["Mon"];
          };
          outputs = {
            effects = {
              flake-update = hercules-ci-effects.lib.mkEffect {
                src = self;
                settings.autoMergeMethod = "merge";
              };
            };
          };
        };
      };
    };
}
