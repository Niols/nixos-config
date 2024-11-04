{ pkgs, ... }:
with pkgs;
[ opam ]
++ (with ocamlPackages; [
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
])
