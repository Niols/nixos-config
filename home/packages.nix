{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ## Necessary for i3; I much prefer running it standalone.
    rofimoji

    ## Fix "error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files"
    ## see https://github.com/nix-community/home-manager/issues/3113
    dconf

    ripgrep # provides `rg`
    fd # alternative to `find` needed by Doom Emacs

    emacs
    cmake # necessary for Emacs's `vterm`
    libtool # necessary for Emacs's `vterm`
    nodejs # necessary for Emacs's `copilot`
    python3 # needed by TreeMacs
  ];
}
