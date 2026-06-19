{
  keys,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    concatStringsSep
    mapAttrsToList
    toFile
    ;

  authKeys = toFile "uptermd-authorized-keys" (
    concatStringsSep "\n" (mapAttrsToList (_: key: key) keys.niols)
  );

in
{
  config = mkIf (config.x_niols.thisMachinesName == "orianne") {
    services.uptermd = {
      enable = true;
      openFirewall = true;
      extraFlags = [
        "--authorized-keys"
        authKeys
      ];
    };
  };
}
