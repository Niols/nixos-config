{ config, lib, ... }:

let
  inherit (lib) mkIf;

  monorepo = "git/ahrefs/monorepo";

in
{
  config = mkIf config.x_niols.isWork {
    home.file."${monorepo}/.envrc".text = ''
      eval $(opam env)

      ## https://ahrefs.slack.com/archives/C01NT4U32JD/p1763978422745349?thread_ts=1763441475.049519&cid=C01NT4U32JD
      export AHREFS_PRE_COMMIT_CHECK_RULAH=true
    '';

    home.sessionPath = [
      "$HOME/${monorepo}/_build/install/default/bin"
      "$HOME/${monorepo}/bin"
    ];
  };
}
