{
  self,
  inputs,
  lib,
  ...
}:

let
  inherit (inputs.nixpkgs.lib)
    mapAttrs
    nixosSystem
    ;

  machines = import ./machines.nix;

  inherit
    (import ./nixosModuleFor.nix {
      inherit
        self
        inputs
        lib
        machines
        ;
    })
    specialArgsFor
    nixosModuleFor
    ;

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
    ./helga
    ./orianne
    ./siegfried
    ./gromit.nix

    ## NixOps4
    inputs.nixops4.modules.flake.default
  ];

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
