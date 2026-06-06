{
  self,
  inputs,
  withSystem,
  ...
}:

let
  inherit (inputs.nixpkgs.lib)
    mapAttrs
    mapAttrs'
    mkForce
    nixosSystem
    filterAttrs
    ;

  ## The prefix of the IPs used for the internal WireGuard network. It can be
  ## anything within 10.x but we choose something fairly unique in the hope of
  ## avoiding conflicts with other networks.
  ##
  wgIpPrefix = "10.187.93";

  ## Some metadata for the machines of this configuration.
  ##
  all = mapAttrs (name: meta: meta // { inherit name; }) {
    ahlaya = {
      kind = "laptop";
    };
    anastasia = rec {
      kind = "server";
      localIp = "192.168.1.11"; # on the local network, in this case a home 192.168.* network
      internalIndex = 1;
      internalIp = "${wgIpPrefix}.${toString internalIndex}"; # on the internal WireGuard network
      wgPublicKey = "ElfanRos88bHayCTJM9qhg1XPOM/egor8ShHoOXAz1c=";
      cores = 2;
    };
    gromit = {
      kind = "laptop";
    };
    helga = rec {
      kind = "server";
      ipv4 = "188.245.212.11";
      ipv6 = "2a01:4f8:1c1c:42dc::1"; # in fact, we have the whole /64 subnet
      internalIndex = 2;
      internalIp = "${wgIpPrefix}.${toString internalIndex}";
      wgPublicKey = "bWTTesse8keIrCO8MWmXFhhHcvwmn+s+DY2nHFi+tmw=";
      cores = 2;
    };
    orianne = rec {
      kind = "server";
      ipv4 = "89.168.38.231";
      internalIndex = 3;
      internalIp = "${wgIpPrefix}.${toString internalIndex}";
      wgPublicKey = "Gu3XXcxqxQDy+N1yFZ7fbJMpJWKOBJKeF95doHmQMT0=";
      cores = 4;
    };
  };
  machines = {
    inherit all wgIpPrefix;
    laptops = filterAttrs (_: { kind, ... }: kind == "laptop") all;
    servers = filterAttrs (_: { kind, ... }: kind == "server") all;
  };

  ## The special arguments that we need to propagate throughout the whole
  ## codebase and all the modules, specialised for the given machine.
  ##
  specialArgsFor = name: {
    inherit inputs;
    machines = machines // {
      this = machines.all.${name};
      otherLaptops = filterAttrs (otherName: _: otherName != name) machines.laptops;
      otherServers = filterAttrs (otherName: _: otherName != name) machines.servers;
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

        nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);

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

  nixops4ComponentFor = name: providers: {
    type = providers.local.exec;
    imports = [ inputs.nixops4-nixos.modules.nixops4Component.nixos ];
    ssh = {
      host = machines.all.${name}.ipv4 or "${name}.niols.fr";
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
    ./anastasia
    ./helga
    ./orianne
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
  nixops4.members =
    mapAttrs (
      name: _:
      { providers, ... }:
      {
        providers.local = inputs.nixops4.modules.nixops4Provider.local;
        members.${name} = nixops4ComponentFor name providers;
      }
    ) machines.servers
    // {
      default =
        { providers, ... }:
        {
          providers.local = inputs.nixops4.modules.nixops4Provider.local;
          members = mapAttrs (name: _: nixops4ComponentFor name providers) machines.servers;
        };
    };
}
