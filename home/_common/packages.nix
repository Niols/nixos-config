{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkMerge mkIf;

in
{
  config = mkMerge [
    {
      home.packages = with pkgs; [
        gnupg # ?
        pinentry # ?
        ripgrep # provides `rg`
      ];
      programs.lsd.enable = true;
    }

    ## Packages that are only ever used on my personal laptops. They should not
    ## clutter work's environment, (and that eliminates the temptation to have
    ## Signal or Thunderbird running)!
    (mkIf (!config.x_niols.isHeadless && !config.x_niols.isWork) {
      home.packages = with pkgs; [
        audacity
        element-desktop
        gnucash
        inkscape
        ledger-live-desktop
        libreoffice
        lilypond
        picard
        signal-desktop
        thunderbird
        vlc
      ];
      services.nextcloud-client = {
        enable = true;
        startInBackground = true;
      };
    })

    ## Personal OCaml-specific configuration.
    (mkIf (!config.x_niols.isWork) {
      home.packages = [
        pkgs.opam
      ]
      ++ (with pkgs.ocamlPackages; [
        dune_3
        merlin
        ocaml
        ocaml-lsp
        ocp-indent
        odoc
        ppx_deriving
        ppx_deriving_yojson
        utop
        visitors
        yojson
      ]);
    })
  ];
}
