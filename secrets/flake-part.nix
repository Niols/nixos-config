{
  inputs,
  lib,
  ...
}:

let
  inherit (lib)
    removeSuffix
    mapAttrs'
    ;

  secrets = import ./secrets.nix;

  ## Inject all secrets into the configuration. This does not mean that the
  ## client machine will be able to decrypt them; this is rather defined in
  ## secrets.nix.
  commonModule.age.secrets = mapAttrs' (name: _: {
    name = removeSuffix ".age" name;
    value.file = ./. + "/${name}";
  }) secrets;

in
{
  flake = {
    inherit secrets;

    nixosModules.secrets.imports = [
      inputs.agenix.nixosModules.default
      commonModule
    ];

    homeModules.secrets =
      { config, ... }:
      {
        imports = [
          inputs.agenix.homeManagerModules.default
          commonModule
        ];
        age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_hm_age" ];
      };
  };
}
