{ self, inputs, ... }:

{
  imports = [
    ## NixOS configurations
    ./helga
    ./orianne
    ./siegfried
    ./wallace
    ./gromit

    ## NixOps4
    inputs.nixops4.modules.flake.default
    { options.flake.nixops4Resources = inputs.nixpkgs.lib.mkOption { }; }
  ];

  flake.machines = [
    "helga"
    "orianne"
    "siegfried"
    "wallace"
    "gromit"
  ];

  flake.nixosConfigurations =
    let
      inherit (builtins) map listToAttrs;
    in
    listToAttrs (
      map (machine: {
        name = machine;
        value = inputs.nixpkgs.lib.nixosSystem {
          modules = [
            self.nixosModules.keys
            self.nixosModules.secrets
            self.nixosModules.${machine}
          ];
          specialArgs = { inherit inputs; };
        };
      }) self.machines
    );

  nixops4Deployments =
    let
      inherit (builtins) mapAttrs;
    in
    mapAttrs (machine: makeResource: nixops4Inputs: {
      providers.local = inputs.nixops4.modules.nixops4Provider.local;
      resources.${machine} = makeResource nixops4Inputs;
    }) self.nixops4Resources
    // {
      default = nixops4Inputs: {
        providers.local = inputs.nixops4.modules.nixops4Provider.local;
        resources = mapAttrs (_: makeResource: makeResource nixops4Inputs) self.nixops4Resources;
      };
    };
}
