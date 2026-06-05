{ config, pkgs, ... }:

let
  inherit (pkgs)
    callPackage
    emacsWithPackagesFromUsePackage
    ;

  cramMode = pkgs.emacsPackages.trivialBuild rec {
    pname = "cram-mode";
    version = "73026b4b9c8b74326186095dbb3ef7bdf9d4925b";
    src = pkgs.fetchurl {
      url = "https://gist.github.com/mikeshulman/ab124d5db7aaa9330ff6457649b05f3a/raw/${version}/cram-mode.el";
      hash = "sha256-E4Rim1jaVyWtCTIBQr/dKowAdsliND7C4kjz8MZXLSk=";
    };
  };

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
        cramMode
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
