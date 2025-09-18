{
  inputs,
  pkgs,
  lib,
  ...
}:

# let
#   doom = pkgs.runCommand "doom" {
#     buildInputs = with pkgs; [ emacs ];
#   } ''
#     echo DOOOOOM
#     set +x
#     cp -R ${inputs.doomemacs} emacs
#     chmod -R u+w emacs
#     emacs/bin/doom install --force --install --doomdir ./.
#     emacs/bin/doom sync --force --doomdir ./.
#     mv emacs $out
#   '';

#   in
{
  programs.emacs.enable = true;

  home.packages = (
    with pkgs;
    [
      cmake # necessary for Emacs's `vterm`
      libtool # necessary for Emacs's `vterm`
      nerd-fonts.symbols-only
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

  ## FIXME: Detect when Doom has not been updated.
  ## FIXME: Detect when ~/.config/emacs is not under our control.
  home.activation.doom = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # rm -Rf "$HOME"/.config/emacs
    # cp -R ''${doom} "$HOME"/.config/emacs
    # chmod -R u+w "$HOME/.config/emacs

    echo Bumping Emacs folder
    rm -Rf "$HOME"/.config/emacs
    cp -R ${inputs.doomemacs} "$HOME"/.config/emacs
    chmod -R u+w "$HOME"/.config/emacs
    echo Instaling Doom
    "$HOME"/.config/emacs/bin/doom install --force --install
    echo Syncing Doom with config
    "$HOME"/.config/emacs/bin/doom sync --force
  '';

  ## Enable true color/24-bit color support. This makes Emacs pretty in the
  ## terminal (otherwise it is okay-ish but not really usable). However, this
  ## might break some terminals that do not have support for it.
  sessionVariables.TERM = "xterm-direct";
}
