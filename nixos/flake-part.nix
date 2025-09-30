{ self, inputs, ... }:

let
  inherit (inputs.nixpkgs.lib)
    genAttrs
    mapAttrs
    mapAttrs'
    mkForce
    nixosSystem
    ;

  ## Some metadata for the servers of this configuration.
  servers = {
    helga.ipv4 = "188.245.212.11";
    orianne.ipv4 = "89.168.38.231";
    siegfried.ipv4 = "158.178.201.160";
  };

  ## The special arguments that we need to propagate throughout the whole
  ## codebase and all the modules.
  specialArgs = { inherit inputs; };

  nixosModuleFor =
    machine:
    (
      { config, ... }:
      {
        imports = [
          self.nixosModules.keys
          self.nixosModules.secrets
          self.nixosModules.${machine}
          inputs.home-manager.nixosModules.home-manager
        ];

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

          sharedModules = [ self.homeModules.secrets ];

          extraSpecialArgs = specialArgs;
        };

        ## The default timeout for Home Manager services is 5 minutes. This is
        ## extremely reasonable, except that we may compile all of Doom Emacs
        ## in that time, so we need to bump it for all our HM users.
        systemd.services = mapAttrs' (user: _: {
          name = "home-manager-${user}";
          value.serviceConfig.TimeoutStartSec = mkForce "20m";
        }) config.home-manager.users;
      }
    );

  nixops4ResourceFor = machine: providers: {
    type = providers.local.exec;
    imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];
    ssh = {
      host = servers.${machine}.ipv4;
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
  ];

  flake.machines = [
    "ahlaya"
    "helga"
    "orianne"
    "siegfried"
    "gromit"
  ];

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
    ) servers
    // {
      default =
        { providers, ... }:
        {
          providers.local = inputs.nixops4.modules.nixops4Provider.local;
          resources = mapAttrs (machine: _: nixops4ResourceFor machine providers) servers;
        };
    };
}
