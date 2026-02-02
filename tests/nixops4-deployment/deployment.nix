{
  inputs,
  lib,
  providers,
  ...
}:

let
  inherit (import ./constants.nix) targetMachines pathToRoot pathFromRoot;
in

{
  providers = {
    inherit (inputs.nixops4.modules.nixops4Provider) local;
  };

  resources = lib.genAttrs targetMachines (nodeName: {
    type = providers.local.exec;

    imports = [
      inputs.nixops4-nixos.modules.nixops4Resource.nixos
      ../common/targetResource.nix
    ];

    _module.args = { inherit inputs; };

    inherit nodeName pathToRoot pathFromRoot;

    nixos.module =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.${nodeName} ];
      };
  });
}
