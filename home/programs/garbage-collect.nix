{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "garbage-collect" ''
      set -euC

      printf 'Remove old Home Manager generations...\n'
      ${pkgs.home-manager}/bin/home-manager expire-generations now
      printf 'done.\n'

      ## Remove all the `.direnv/flake-profile-*-link` files that are not the
      ## one pointed by `.direnv/flake-profile`.
      ##
      printf 'Remove old flake direnvs...\n'
      find                                                                   \
          ~                                                                  \
          -type l                                                            \
          -regex '.*/.direnv/flake-profile-[0-9]*-link'                      \
          -exec sh -c 'a={}; b=''${a%-[0-9]*-link}; ! [ "$a" -ef "$b" ]' ';' \
          -print                                                             \
          -delete
      printf 'done.\n'

      printf 'Call Nix garbage collection...\n'
      sudo nix-collect-garbage -d
      printf 'done.\n'

      printf 'Removing old Docker images and containers...\n'
      docker system prune --all
      printf 'done.\n'

      printf 'Emptying wastebasket...\n'
      du -sh "''${XDG_DATA_HOME:-~/.local/share}"/Trash
      find "''${XDG_DATA_HOME:-~/.local/share}"/Trash -type f -print -delete
      printf 'done.\n'
    '')
  ];
}
