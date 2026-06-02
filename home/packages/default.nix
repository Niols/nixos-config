{ config, pkgs, ... }:

let
  inherit (pkgs)
    callPackage
    emacsWithPackagesFromUsePackage
    ;

  lilypondMode = pkgs.emacsPackages.trivialBuild {
    pname = "lilypond-mode";
    version = pkgs.lilypond.version;
    src = "${pkgs.lilypond}/share/emacs/site-lisp";
  };

in

{
  imports = [
    ./garbage-collect.nix
    ./graphical.nix
    ./ocaml.nix
    ./work.nix
  ];

  home.packages = [
    (callPackage ../../rebuild.nix { })
    pkgs.opencode
  ]
  ++ config.x_niols.commonPackages;

  programs.emacs = {
    enable = true;
    package = emacsWithPackagesFromUsePackage {
      config = ./emacs.el;
      extraEmacsPackages = _epkgs: [
        lilypondMode
      ];
    };
  };
  xdg.configFile."emacs/init.el".source = ./emacs.el;
  xdg.configFile."emacs/early-init.el".text = ''
    ;; Disable GC during init. It will be re-enabled by gcmh - see main config.
    (setq gc-cons-threshold most-positive-fixnum)
    (setq package-enable-at-startup nil)
  '';

  ## Run the OPAM hook if it exists. This can be shared between all
  ## sessions; we do not however enforce the existence of OPAM.
  programs.bash.profileExtra = ''
    if command -v opam >/dev/null; then eval $(opam env); fi
  '';
}
