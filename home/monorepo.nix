{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;

  monorepoNix = "git/ahrefs/monorepo";
  monorepoOpam = "git/ahrefs/monorepo-opam";

  ahrefsAdminOpam =
    name:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        "$HOME"/${monorepoOpam}/bin/admin "$@"
      '';
    };
  ahrefsAdminNix =
    name:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        cd "$HOME"/${monorepoNix}
        nix develop .#.devShells.x86_64-linux.default --command bin/admin "$@"
      '';
    };

in
{
  config = mkIf config.x_niols.isWork {
    home.file."${monorepoNix}/.envrc".text = ''
      ## NOTE: there is also `source_env` but it interpret eg. watch_dir relative
      ## to the sourced file's location.
      . ./nix/envrc.sample
    '';
    home.file."${monorepoOpam}/.envrc".text = ''
      eval $(opam env)
    '';

    ## ~/.local/bin for python-based utilities, eg. semgrep.
    home.sessionPath = [ "$HOME/.local/bin" ];

    home.packages =
      if config.x_niols.isGraphical then
        [
          (ahrefsAdminNix "admin")
          (ahrefsAdminNix "admin-nix")
        ]
      else
        [
          ## NOTE: admin via opam is the default for now, because via Nix we pay
          ## the cost of evaluating the flake. Possibly we can speed this up,
          ## but more importantly I think we should avoid relying on a flake as
          ## the entry point.
          (ahrefsAdminOpam "admin")
          (ahrefsAdminOpam "admin-opam")
          (ahrefsAdminNix "admin-nix")
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
