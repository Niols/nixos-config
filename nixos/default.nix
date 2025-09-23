{ self, inputs, ... }:

let
  inherit (inputs.nixpkgs.lib)
    genAttrs
    mapAttrs
    mkOption
    nixosSystem
    ;

  ## The special arguments that we need to propagate throughout the whole
  ## codebase and all the modules.
  specialArgs = { inherit inputs; };

  nixosModuleFor = machine: {
    imports = [
      self.nixosModules.keys
      self.nixosModules.secrets
      self.nixosModules.${machine}
      {
        imports = [ inputs.home-manager.nixosModules.home-manager ];
        home-manager = {
          ## By default, Home Manager uses a private pkgs instance that is
          ## configured via the `home-manager.users.<name>.nixpkgs` options.
          ## The following option instead uses the global pkgs that is
          ## configured via the system level nixpkgs options; This saves an
          ## extra Nixpkgs evaluation, adds consistency, and removes the
          ## dependency on `NIX_PATH`, which is otherwise used for importing
          ## Nixpkgs.
          useGlobalPkgs = true;

          ## By default packages will be installed to `$HOME/.nix-profile` but
          ## they can be installed to `/etc/profiles` if the following is
          ## added to the system configuration. This option may become the
          ## default value in the future.
          useUserPackages = true;

          extraSpecialArgs = specialArgs;
        };
      }
    ];
  };

  nixops4ResourceFor = machine: providers: {
    type = providers.local.exec;
    imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];
    ssh = {
      host = self.nixops4Hosts.${machine};
      opts = "";
      hostPublicKey = self.keys.machines.${machine};
    };
    inherit (inputs) nixpkgs;
    nixos = {
      module = nixosModuleFor machine;
      inherit specialArgs;
    };
  };

in

{
  imports = [
    ## NixOS configurations
    ./ahlaya.nix
    ./helga
    ./orianne
    ./siegfried
    ./gromit.nix

    ## NixOps4
    inputs.nixops4.modules.flake.default
    { options.flake.nixops4Hosts = mkOption { }; }
  ];

  flake.machines = [
    "ahlaya"
    "helga"
    "orianne"
    "siegfried"
    "gromit"
  ];

  flake.nixops4Hosts = {
    helga = "188.245.212.11";
    orianne = "89.168.38.231";
    siegfried = "158.178.201.160";
  };

  flake.nixosConfigurations = genAttrs self.machines (
    machine:
    nixosSystem {
      inherit specialArgs;
      modules = [ (nixosModuleFor machine) ];
    }
  );

  nixops4Deployments =
    mapAttrs (
      machine: _:
      { providers, ... }:
      {
        providers.local = inputs.nixops4.modules.nixops4Provider.local;
        resources.${machine} = nixops4ResourceFor machine providers;
      }
    ) self.nixops4Hosts
    // {
      default =
        { providers, ... }:
        {
          providers.local = inputs.nixops4.modules.nixops4Provider.local;
          resources = mapAttrs (machine: _: nixops4ResourceFor machine providers) self.nixops4Hosts;
        };
    };
}
