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

    ## Set up Attic for authentication to private substituters. This can contain
    ## sensitive tokens, and we do not trust standalone installations with this,
    ## because they exist on machines that we don't control.
    (mkIf (osConfig != null) {
      ## FIXME: Get Agenix secrets working for this on HM.
      # xdg.configFile."attic/config.toml".source = config.age.secrets.attic-client-config.path;
    })

    {
      programs.nix-index.enable = true;
      programs.nix-index.symlinkToCacheHome = true;
      programs.nix-index-database.comma.enable = true;
    }
  ];
}
