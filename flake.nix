{
  description = "Common python utilities for RAD-Development projects";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org/?priority=1&want-mass-query=true"
      "https://attic.alicehuston.xyz/cache-nix-dot?priority=4&want-mass-query=true"
      "https://nix-community.cachix.org/?priority=10&want-mass-query=true"
    ];
    trusted-substituters = [
      "https://cache.nixos.org"
      "https://attic.alicehuston.xyz/cache-nix-dot"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache-nix-dot:Od9KN34LXc6Lu7y1ozzV1kIXZa8coClozgth/SYE7dU="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # nixpkgs-stable.follows = "nixpkgs-stable";
        # flake-compat.follows = "flake-compat";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        pkgs = nixpkgs.legacyPackages.${system};
        poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };

        overrides = poetry2nix.overrides.withDefaults (
          _final: prev: {
            # prefer binary wheels instead of source distributions for rust based dependencies
            # avoids needing to build them from source. technically a security risk
            polars = prev.polars.override { preferWheel = true; };
            ruff = prev.ruff.override { preferWheel = true; };
            greenlet = prev.greenlet.override { preferWheel = true; };
            sqlalchemy = prev.sqlalchemy.override { preferWheel = true; };
          }
        );

        poetryConfig = {
          inherit overrides;
          projectDir = self;
          python = pkgs.python312;
        };
      in
      rec {
        packages = {
          rad-development-python = poetry2nix.mkPoetryApplication poetryConfig // {
            develop = true;
          };
          default = self.packages.${system}.rad-development-python;
        };

        formatter = pkgs.nixfmt-rfc-style;

        devShells = import ./shell.nix {
          inherit
            self
            poetryConfig
            poetry2nix
            inputs
            system
            checks
            ;
        };
        checks = import ./checks.nix { inherit inputs system formatter; };
      }
    )
    // {
      hydraJobs = import ./hydra/jobs.nix { inherit (self) inputs outputs; };
    };
}
