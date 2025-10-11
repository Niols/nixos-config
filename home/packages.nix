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
      home.packages = [ (pkgs.callPackage ../rebuild.nix { }) ] ++ config.x_niols.commonPackages;

      ## Run the OPAM hook if it exists. This can be shared between all
      ## sessions; we do not however enforce the existence of OPAM.
      programs.bash.profileExtra = ''
        if command -v opam >/dev/null; then eval $(opam env); fi
      '';
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

      ## Start Nextcloud automatically on startup. NOTE: There is also
      ## `services.nextcloud.enable`, but it has been causing issues with
      ## Nextcloud forgetting its configuration, so we prefer this.
      xdg.autostart = {
        enable = true;
        entries = [
          "${pkgs.nextcloud-client}/share/applications/com.nextcloud.desktopclient.nextcloud.desktop"
        ];
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

    ## Work development tools considered available by default
    (mkIf config.x_niols.isWork {
      home.packages = with pkgs; [
        gnumake
      ];
    })

    ## Work desktop software
    (mkIf (config.x_niols.isWork && !config.x_niols.isHeadless) {
      home.packages = with pkgs; [
        slack
        zoom-us
      ];
    })
  ];
}
