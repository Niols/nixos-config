{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "garbage-collect" ''
      set -euC

      ## Cache `sudo` password so that we don't have to enter it later on.
      sudo true

      printf 'Remove old Home Manager generations...\n\e[37m'
      ${pkgs.home-manager}/bin/home-manager expire-generations now
      printf '\e[0mdone.\n'

      ## Remove all the `.direnv/flake-profile-*-link` files that are not the
      ## one pointed by `.direnv/flake-profile`.
      ##
      printf 'Remove old flake direnvs...\n\e[37m'
      find                                                                   \
          ~                                                                  \
          -type l                                                            \
          -regex '.*/.direnv/flake-profile-[0-9]*-link'                      \
          -exec sh -c 'a={}; b=''${a%-[0-9]*-link}; ! [ "$a" -ef "$b" ]' ';' \
          -print                                                             \
          -delete
      printf '\e[0mdone.\n'

      ## Remove all the `.direnv/flake-inputs` directories.
      printf 'Remove flake inputs...\n\e[37m'
      find                                                                   \
          ~                                                                  \
          -type d                                                            \
          -regex '.*/.direnv/flake-inputs'                                   \
          -print                                                             \
          -exec rm -Rf '{}' +
      printf '\e[0mdone.\n'

      printf 'Call Nix garbage collection...\n\e[37m'
      sudo nix-collect-garbage -d
      printf '\e[0mdone.\n'

      printf 'Removing old Docker images and containers...\n\e[37m'
      docker system prune --all --force
      printf '\e[0mdone.\n'

      printf 'Emptying wastebasket...\n'
      du -sh "''${XDG_DATA_HOME:-$HOME/.local/share}"/Trash
      printf '\e[37m'
      find "''${XDG_DATA_HOME:-$HOME/.local/share}"/Trash/files -type f -print -delete
      printf '\e[0m'
      du -sh "''${XDG_DATA_HOME:-$HOME/.local/share}"/Trash
      printf 'done.\n'
    '')
  ];
}
