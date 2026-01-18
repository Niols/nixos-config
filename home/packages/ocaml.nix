{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf;

in
{
  ## Default OCaml configuration with some often used packages. We do not make
  ## it available on our headless work environment where OCaml and OPAM come
  ## from somewhere else, and we want to avoid version issues with OPAM.
  ##
  config = mkIf (!config.x_niols.isWork || (config.x_niols.isWork && !config.x_niols.isHeadless)) {
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
