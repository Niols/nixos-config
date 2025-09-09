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
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ## NixOS configurations
        ./helga
        ./orianne
        ./siegfried
        ./wallace

        ## Other
        inputs.git-hooks.flakeModule
        inputs.nixops4.modules.flake.default

        { options.flake.nixops4Resources = inputs.nixpkgs.lib.mkOption { }; }

        ./keys
        ./secrets
      ];

      flake.machines = [
        "helga"
        "orianne"
        "siegfried"
        "wallace"
      ];

      flake.nixosConfigurations =
        let
          inherit (builtins) map listToAttrs;
        in
        listToAttrs (
          map (machine: {
            name = machine;
            value = inputs.nixpkgs.lib.nixosSystem {
              ## FIXME: specialArgs = { inherit inputs; }
              ## FIXME: inject inputs (eg. home manager module) here
              modules = [ self.nixosModules.${machine} ];
            };
          }) self.machines
        );

      nixops4Deployments =
        let
          inherit (builtins) mapAttrs;
        in
        mapAttrs (
          machine: makeResource:
          nixops4Inputs@{ providers, ... }:
          {
            providers.local = inputs.nixops4.modules.nixops4Provider.local;
            resources.${machine} = makeResource nixops4Inputs;
          }
        ) self.nixops4Resources
        // {
          default =
            nixops4Inputs@{ providers, ... }:
            {
              providers.local = inputs.nixops4.modules.nixops4Provider.local;
              resources = mapAttrs (_: makeResource: makeResource nixops4Inputs) self.nixops4Resources;
            };
        };

      flake.homeConfigurations.niols = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          (import ./home { inherit inputs; })
          {
            home.username = "niols";
            home.homeDirectory = "/home/niols";
          }
        ];
      };

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

              inputs'.disko.packages.disko
              inputs'.disko.packages.disko-install

              ## FIXME: Move the following to `secrets/default.nix`
              inputs'.agenix.packages.default
              pkgs.borgbackup
              pkgs.apacheHttpd # provides the `htpasswd` utility
              pkgs.easyrsa # for OpenVPN's `easyrsa` command
            ];
            shellHook = config.pre-commit.installationScript;
          };
        };

      ## Improve the way `inputs'` are computed by also handling the case of
      ## flakes having a `lib.${system}` attribute.
      ##
      perInput = system: flake: if flake ? lib.${system} then { lib = flake.lib.${system}; } else { };
    };
}
