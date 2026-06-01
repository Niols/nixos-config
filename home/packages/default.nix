{ config, pkgs, ... }:

{
  imports = [
    ./garbage-collect.nix
    ./graphical.nix
    ./ocaml.nix
    ./work.nix
  ];

  home.packages = [
    (pkgs.callPackage ../../rebuild.nix { })
    (pkgs.emacsWithPackagesFromUsePackage { config = ./emacs.el; })
    pkgs.opencode
  ]
  ++ config.x_niols.commonPackages;

  ## Inject Emacs init file
  xdg.configFile."emacs/init.el".source = ./emacs.el;

  ## Run the OPAM hook if it exists. This can be shared between all
  ## sessions; we do not however enforce the existence of OPAM.
  programs.bash.profileExtra = ''
    if command -v opam >/dev/null; then eval $(opam env); fi
  '';
}
