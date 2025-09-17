{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixops4-nixos.url = "github:nixops4/nixops4-nixos";
    nixops4.follows = "nixops4-nixos/nixops4";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = ""; # saves some resources on Linux

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    dancelor.url = "github:paris-branch/dancelor";

    doomemacs.url = "github:doomemacs/doomemacs/8f55404781edacf66fa330205533b002de3fb5eeb";
    doomemacs.flake = false;
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.git-hooks.flakeModule
        ./nixos
        ./home
        ./keys
        ./secrets
      ];

      perSystem =
        {
          config,
          pkgs,
          inputs',
          ...
        }:
        {
          formatter = pkgs.nixfmt-rfc-style;

          pre-commit.settings.hooks = {
            nixfmt-rfc-style.enable = true;
            deadnix.enable = true;
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.nil
              inputs'.nixops4.packages.default

              ## FIXME: Move the following to `secrets/default.nix`
              inputs'.agenix.packages.default
              pkgs.borgbackup
              pkgs.apacheHttpd # provides the `htpasswd` utility
              pkgs.easyrsa # for OpenVPN's `easyrsa` command
              pkgs.openssl # for key/cert pair generation
              pkgs.wireguard-tools # for `wg`
            ];
            shellHook = config.pre-commit.installationScript;
          };

          devShells.install = pkgs.mkShell {
            packages = [
              inputs'.disko.packages.disko
              pkgs.autorandr
              pkgs.gh
            ];
          };

          ## Expose Home Manager as one of the packages of the flake. This is
          ## useful when trying to use it on a random machine as it avoids
          ## having to first get Home Manager (and probably a nixpkgs), and then
          ## also get this flake.
          packages.home-manager = inputs'.home-manager.packages.home-manager;
        };

      ## Improve the way `inputs'` are computed by also handling the case of
      ## flakes having a `lib.${system}` attribute.
      ##
      perInput = system: flake: if flake ? lib.${system} then { lib = flake.lib.${system}; } else { };
    };
}
