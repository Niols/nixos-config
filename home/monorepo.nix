{ config, lib, ... }:

let
  inherit (lib) mkIf;

  monorepo = "git/ahrefs/monorepo";

in
{
  config = mkIf config.x_niols.isWork {
    home.file."${monorepo}/.envrc".text = "eval $(opam env)";

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

      ## Have both pre-commit and pre-push hooks. This is the default for now,
      ## but pre-commit might stop being enabled by default in the future.
      AHREFS_PRECOMMIT_CHECKS = "TRUE";
      AHREFS_PREPUSH_CHECKS = "TRUE";

      ## Use in-house devhooks rather than pre-commit, see:
      ## https://ahrefs.slack.com/archives/C8SH6JK62/p1779008144833829
      AHREFS_GITHOOKS_DEVHOOKS = "TRUE";

      ## More variables for debugging purposes. It doesn't make much sense to
      ## activate them via Nix, so they are more here for documentation.
      #AHREFS_PREPUSH_TRACE = "TRUE";
      #AHREFS_PREPUSH_DEBUG = "TRUE";
    };
  };
}
