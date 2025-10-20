{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;

in
{
  ## Personal OCaml-specific configuration.
  config = mkIf (!config.x_niols.isWork) {
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
  };
}
