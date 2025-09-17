{ pkgs, ... }:

{
  programs.emacs.enable = true;

  home.packages = (
    with pkgs;
    [
      cmake # necessary for Emacs's `vterm`
      libtool # necessary for Emacs's `vterm`
      nodejs # necessary for Emacs's `copilot`
      python3 # needed by TreeMacs
      (aspellWithDicts (
        dicts: with dicts; [
          fr
          uk
        ]
      ))
      vim # useful when Emacs is broken/not set-up yet
    ]
  );

  home.file.".config/doom/config.el".source = ./config.el;
  home.file.".config/doom/custom.el".source = ./custom.el;
  home.file.".config/doom/init.el".source = ./init.el;
  home.file.".config/doom/packages.el".source = ./packages.el;
}
