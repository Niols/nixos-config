{ self, inputs, ... }:

let
  inherit (builtins) map mapAttrs listToAttrs;

in

{
  imports = [
    ## NixOS configurations
    ./ahlaya.nix
    ./helga
    ./orianne
    ./siegfried
    ./wallace.nix
    ./gromit.nix

    ## NixOps4
    inputs.nixops4.modules.flake.default
    { options.flake.nixops4Resources = inputs.nixpkgs.lib.mkOption { }; }
  ];

  flake.machines = [
    "ahlaya"
    "helga"
    "orianne"
    "siegfried"
    "wallace"
    "gromit"
  ];

  flake.nixosConfigurations = listToAttrs (
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
      ## A NixOps4 resource module that injects the necessary dependencies into
      ## the NixOS configuration. This looks awfully like the call to
      ## `nixosSystem` above, and that is normal. REVIEW: Maybe we can actually
      ## factorise both of these call sites.
      nixosDepsInjectionModule = {
        nixos.module.imports = [
          self.nixosModules.keys
          self.nixosModules.secrets
        ];
        nixos.specialArgs = { inherit inputs; };
      };
    in
    mapAttrs (
      machine: makeResource:
      ## NOTE: We need to “use” the argument `providers`, otherwise NixOps4
      ## fails with: “error: function '<deployment>' called without required
      ## argument 'providers'”. However, deadnix does not like this, so we
      ## have to inform it that this is OK.
      ##
      # deadnix: skip
      nixops4Inputs@{ providers, ... }:
      {
        providers.local = inputs.nixops4.modules.nixops4Provider.local;
        resources.${machine}.imports = [
          (makeResource nixops4Inputs)
          nixosDepsInjectionModule
        ];
      }
    ) self.nixops4Resources
    // {
      default =
        ## NOTE: We need to “use” the argument `providers`, otherwise NixOps4
        ## fails with: “error: function '<deployment>' called without required
        ## argument 'providers'”. However, deadnix does not like this, so we
        ## have to inform it that this is OK.
        ##
        # deadnix: skip
        nixops4Inputs@{ providers, ... }:
        {
          providers.local = inputs.nixops4.modules.nixops4Provider.local;
          resources = mapAttrs (_: makeResource: {
            imports = [
              (makeResource nixops4Inputs)
              nixosDepsInjectionModule
            ];
          }) self.nixops4Resources;
        };
    };
}
