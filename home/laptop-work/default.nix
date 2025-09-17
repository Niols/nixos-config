{ pkgs, ... }:

{
  imports = [ ../_common/laptop ];

  home.username = "work";
  home.homeDirectory = "/home/work";

  home.file.".face".source = ./face.jpg;

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
    slack
    zoom-us
  ];

  programs.ssh.matchBlocks."*" = {
    identitiesOnly = true;
    identityFile = "~/.ssh/id_ahrefs";
  };
}
