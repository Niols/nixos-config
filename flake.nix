{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = ""; # saves some resources on Linux

    dancelor.url = "github:paris-branch/dancelor";

    secrets.url = "github:niols/nixos-secrets";
    secrets.flake = false;
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      imports = [
        ## NixOS configurations
        ./dagrun
        ./orianne
        ./siegfried
        ./wallace

        ## Other
        inputs.pre-commit-hooks.flakeModule
      ];

      perSystem = { config, pkgs, ... }: {
        formatter = pkgs.nixfmt;

        pre-commit.settings.hooks = {
          nixfmt.enable = true;
          deadnix.enable = true;
        };

        devShells.default =
          pkgs.mkShell { shellHook = config.pre-commit.installationScript; };
      };

      ## Improve the way `inputs'` are computed by also handling the case of
      ## flakes having a `lib.${system}` attribute.
      ##
      perInput = system: flake:
        if flake ? lib.${system} then { lib = flake.lib.${system}; } else { };
    };
}
