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
in
{
  flake = {
    inherit secrets;

    nixosModules.secrets = (
      { config, ... }:
      {
        imports = [ inputs.agenix.nixosModules.default ];

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
      }
    );
  };
}
