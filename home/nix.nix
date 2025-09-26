{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkMerge;

in
{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.nix-index-database.homeModules.nix-index
  ];

  config = mkMerge [
    (mkIf config.x_niols.isStandalone {
      ## This is the default in NixOS configurations. However, in Home
      ## configurations, this instructs HM to generate the configuration.
      nix.package = pkgs.nix;
    })

    ## For authentication to private substituters, see the `nix-netrc` secret.
    ## We do not trust standalone installations with this, because they most
    ## likely exist on machines that we don't control.
    (mkIf (!config.x_niols.isStandalone) {
      age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_age" ];
      age.secrets.nix-netrc.file = ../secrets/nix-netrc.age;
      nix.settings.netrc-file = config.age.secrets.nix-netrc.path;
    })

    {
      programs.nix-index.enable = true;
      programs.nix-index.symlinkToCacheHome = true;
      programs.nix-index-database.comma.enable = true;
    }
  ];
}
