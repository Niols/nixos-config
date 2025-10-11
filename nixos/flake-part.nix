{ self, inputs, ... }:

let
  inherit (inputs.nixpkgs.lib)
    mapAttrs
    mapAttrs'
    mkForce
    nixosSystem
    filterAttrs
    ;

  ## Some metadata for the machines of this configuration.
  all = mapAttrs (name: meta: meta // { inherit name; }) {
    ahlaya = {
      kind = "laptop";
    };
    gromit = {
      kind = "laptop";
    };
    helga = {
      kind = "server";
      ipv4 = "188.245.212.11";
      ipv6 = "2a01:4f8:1c1c:42dc::1"; # in fact, we have the whole /64 subnet
    };
    orianne = {
      kind = "server";
      ipv4 = "89.168.38.231";
    };
    siegfried = {
      kind = "server";
      ipv4 = "158.178.201.160";
    };
  };
  machines = {
    inherit all;
    laptops = filterAttrs (_: { kind, ... }: kind == "laptop") all;
    servers = filterAttrs (_: { kind, ... }: kind == "server") all;
  };

  ## The special arguments that we need to propagate throughout the whole
  ## codebase and all the modules, specialised for the given machine.
  specialArgsFor = name: {
    inherit inputs;
    machines = machines // {
      this = machines.all.${name};
    };
  };

  nixosModuleFor =
    name:
    (
      { config, ... }:
      {
        imports = [
          self.nixosModules.keys
          self.nixosModules.secrets
          self.nixosModules.${name}
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

          extraSpecialArgs = specialArgsFor name;
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

  nixops4ResourceFor = name: providers: {
    type = providers.local.exec;
    imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];
    ssh = {
      host = machines.all.${name}.ipv4;
      opts = "";
      hostPublicKey = self.keys.machines.${name};
    };
    inherit (inputs) nixpkgs;
    nixos = {
      module = nixosModuleFor name;
      specialArgs = specialArgsFor name;
    };
  };

in

{
  imports = [
    ## NixOS configurations
    ./ahlaya.nix
    ./helga.nix
    ./orianne
    ./siegfried
    ./gromit.nix

    ## NixOps4
    inputs.nixops4.modules.flake.default
  ];

  ## FIXME: stop passing arguments via `self` like this
  flake.machines = machines;

  flake.nixosConfigurations = mapAttrs (
    name: _:
    nixosSystem {
      modules = [ (nixosModuleFor name) ];
      specialArgs = specialArgsFor name;
    }
  ) machines.all;

  ## Deployments for all servers
  nixops4Deployments =
    mapAttrs (
      name: _:
      { providers, ... }:
      {
        providers.local = inputs.nixops4.modules.nixops4Provider.local;
        resources.${name} = nixops4ResourceFor name providers;
      }
    ) machines.servers
    // {
      default =
        { providers, ... }:
        {
          providers.local = inputs.nixops4.modules.nixops4Provider.local;
          resources = mapAttrs (name: _: nixops4ResourceFor name providers) machines.servers;
        };
    };
}
