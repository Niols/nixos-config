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
      ## Have both pre-commit and pre-push hooks. This is the default for now,
      ## but pre-commit might stop being enabled by default in the future.
      export AHREFS_PRECOMMIT_CHECKS=TRUE
      export AHREFS_PREPUSH_CHECKS=TRUE
    '';

    ## ~/.local/bin for python-based utilities, eg. semgrep.
    home.sessionPath = [
      "$HOME/${monorepo}/_build/install/default/bin"
      "$HOME/${monorepo}/bin"
      "$HOME/.local/bin"
    ];

    home.sessionVariables = {
      ## Max parallelism of the `admin` command. My SSH agent does not seem to
      ## support 1200. Maybe there is a nice middleground that can be found, but
      ## I'd rather be safe than sorry.
      AHREFS_ADMIN_MAX_P = 200;
    };
  };
}
