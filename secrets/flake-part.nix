{
  inputs,
  lib,
  ...
}:

let
  inherit (builtins) elem;
  inherit (lib.attrsets) concatMapAttrs optionalAttrs;
  inherit (lib.strings) removeSuffix;

  secrets = import ./secrets.nix;

  commonModule =
    { config, ... }:
    {
      ## FIXME: rename
      options.x_niols.hostPublicKey = lib.mkOption {
        description = ''
          The host public key of the machine. It is used in particular
          to filter Age secrets and only keep the relevant ones.
        '';
      };

      config.age.secrets = concatMapAttrs (
        name: secret:
        optionalAttrs (elem config.x_niols.hostPublicKey secret.publicKeys) ({
          ${removeSuffix ".age" name}.file = ./. + "/${name}";
        })
      ) secrets;
    };

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
        config.age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_age" ];
        config.x_niols.hostPublicKey = (import ../keys/keys.nix).home-manager;
      };
  };
}
