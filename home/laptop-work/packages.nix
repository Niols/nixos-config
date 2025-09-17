{ pkgs, ... }:

{
  ## FIXME: Some things like this would deserve to be shared between `nixos/`
  ## and `home/`, so probably we need something `_common` at the root too?
  ##
  ## FIXME: We shouldn't be setting things in `nixpkgs` because we are using
  ## `useGlobalPkgs` in the NixOS configurations. Figure it out.
  ##
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "slack"
      "zoom"
    ];

  home.packages = with pkgs; [
    ## Development tools considered available by default
    gnumake

    ## Desktop software
    slack
    zoom-us
  ];
}
