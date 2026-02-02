{
  inputs,
  lib,
  providers,
  ...
}:

{
  providers = {
    inherit (inputs.nixops4.modules.nixops4Provider) local;
  };

  resources = lib.genAttrs [ "hello" "cowsay" ] (nodeName: {
    type = providers.local.exec;

    imports = [
      inputs.nixops4-nixos.modules.nixops4Resource.nixos
      ./targetResource.nix
    ];

    _module.args = { inherit inputs; };

    inherit nodeName;

    nixos.module =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.${nodeName} ];
      };
  });
}
