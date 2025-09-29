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
  keys = import ../keys/keys.nix;

  commonModule =
    { config, ... }:
    {
      options.x_niols.agePublicKey = lib.mkOption {
        description = ''
          The public key that will allow decrypting secrets. It will be used
          to filter Age secrets and only keep the relevant ones.
        '';
      };

      config.age.secrets = concatMapAttrs (
        name: secret:
        optionalAttrs (elem config.x_niols.agePublicKey secret.publicKeys) ({
          ${removeSuffix ".age" name}.file = ./. + "/${name}";
        })
      ) secrets;
    };

in
{
  flake = {
    inherit secrets;

    nixosModules.secrets =
      { config, ... }:
      {
        imports = [
          inputs.agenix.nixosModules.default
          commonModule
        ];
        x_niols.agePublicKey = keys.machines.${config.x_niols.thisDevicesNameLower};
      };

  };
}
