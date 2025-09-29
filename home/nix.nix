{
  osConfig,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkMerge;

in
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  config = mkMerge [
    (mkIf (osConfig == null) {
      ## This is the default in NixOS configurations. However, in Home
      ## configurations, this instructs HM to generate the configuration.
      nix.package = pkgs.nix;
    })

    {
      programs.nix-index.enable = true;
      programs.nix-index.symlinkToCacheHome = true;
      programs.nix-index-database.comma.enable = true;
    }
  ];
}
