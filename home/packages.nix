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
      home.packages = [ (pkgs.callPackage ../rebuild.nix { }) ];

      ## Run the OPAM hook if it exists. This can be shared between all
      ## sessions; we do not however enforce the existence of OPAM.
      programs.bash.bashrcExtra = ''
        if [ -r ~/.opam/opam-init/init.sh ]; then
          . ~/.opam/opam-init/init.sh >/dev/null 2>&1 || true
        fi
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

    {
      ## FIXME: Some things like this would deserve to be shared between `nixos/`
      ## and `home/`, so probably we need something `_common` at the root too?
      ##
      ## FIXME: We shouldn't be setting things in `nixpkgs` because we are using
      ## `useGlobalPkgs` in the NixOS configurations. Figure it out.
      ##
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (pkgs.lib.getName pkg) [
          "slack"
          "zoom"
        ];
    }

    ## Development tools considered available by default
    (mkIf config.x_niols.isWork {
      home.packages = with pkgs; [
        gnumake
      ];
    })

    ## Desktop software for work
    (mkIf (config.x_niols.isWork && !config.x_niols.isHeadless) {
      home.packages = with pkgs; [
        slack
        zoom-us
      ];
    })
  ];
}
