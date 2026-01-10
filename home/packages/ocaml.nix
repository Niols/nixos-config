{ pkgs, ... }:

{
  ## Default OCaml configuration with some often used packages.
  ##
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
}
