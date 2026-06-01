{ lib, pkgs, ... }:

let
  inherit (lib) mkOption types;

in
{
  options.x_niols.commonPackages = mkOption {
    description = ''
      Packages that are shared between Home and NixOS configurations. They
      should be imported with `home.packages` or `environment.systemPackages`
      depending on the context.
    '';
    default = [ ];
    type = with types; listOf package;
  };

  config = {
    ## NOTE: For nixpkgs.config.allowUnfreePredicate, see file
    ## pkgs.nix at the root of the repository.

    ## We want Vim available everywhere as a good default editor. For proper
    ## IDE, we still use Emacs with Evil.
    programs.vim = {
      enable = true;
      defaultEditor = true;
    };

    x_niols.commonPackages = with pkgs; [
      bat
      bc
      btop
      calc
      dig
      entr
      fd
      git
      git-lfs
      ghostscript # for `gs`, which `imagemagick` uses for PDF manipulation
      htop
      httpie
      imagemagick
      jq
      jless
      killall
      lsd
      nix-output-monitor
      pdfgrep # superseeded by ripgrep-all?
      pdftk
      ripgrep
      ripgrep-all
      (callPackage ./packages/rnix.nix { })
      tmux
      unrar
      unzip
      wget
      yamllint
      yq
    ];

    ## LSD aliases and some more. On HM, they can be obtained with
    ## `programs.lsd.enable = true`, but that will not work on non-HM NixOS
    ## machines. On NixOS, the `l` alias is defined by default, but this will
    ## not work on HM-only machines. So we handle everything by hand here:
    programs.bash.shellAliases = {
      l = "${pkgs.lsd}/bin/lsd -lah";
      ls = "${pkgs.lsd}/bin/lsd";
      ll = "${pkgs.lsd}/bin/lsd -l";
      la = "${pkgs.lsd}/bin/lsd -A";
      lt = "${pkgs.lsd}/bin/lsd --tree";
      lla = "${pkgs.lsd}/bin/lsd -lA";
      llt = "${pkgs.lsd}/bin/lsd -l --tree";
    };
  };
}
