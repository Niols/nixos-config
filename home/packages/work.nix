{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkMerge mkIf;

in
{
  config = mkMerge [
    ## Work development tools considered available by default
    (mkIf config.x_niols.isWork {
      home.packages = with pkgs; [
        gnumake
      ];
    })

    ## Work desktop software
    (mkIf (config.x_niols.isWork && !config.x_niols.isHeadless) {
      home.packages = with pkgs; [
        firefox
        slack
        zoom-us
      ];
    })
  ];
}
