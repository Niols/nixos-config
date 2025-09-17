{ pkgs, ... }:

## TODO: Split packages in categories, such as “admin utils” (fd, rg, htop), IDE
## (Emacs, with all its packages) and “fancy desktop stuff” (GIMP, Inkscape),
## etc. Use that to easily install on different machines, and share between Home
## Manager and NixOS configurations.

{
  home.packages = with pkgs; [
    ## Necessary for i3; I much prefer running it standalone.
    rofimoji

    ## Fix "error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files"
    ## see https://github.com/nix-community/home-manager/issues/3113
    dconf

    gnupg
    pinentry

    ripgrep # provides `rg`
  ];
}
