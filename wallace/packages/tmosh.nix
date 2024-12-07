{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "tmosh";
  src = ./.; # or anything; this is unused

  installPhase = ''
    ############################################################################
    ## Binaries

    mkdir -p $out/bin

    cat <<'EOF' > $out/bin/tmosh
      #!/bin/sh
      exec ${pkgs.mosh}/bin/mosh "$@" -- \
        tmux new -s tmosh_$(date +'%Y-%m-%d_%H-%M-%S')_$RANDOM
    EOF
    chmod +x $out/bin/tmosh

    cat <<'EOF' > $out/bin/tssh
      #!/bin/sh
      exec ${pkgs.openssh}/bin/ssh "$@" -- \
        tmux new -s tmosh_$(date +'%Y-%m-%d_%H-%M-%S')_$RANDOM
    EOF
    chmod +x $out/bin/tssh

    ############################################################################
    ## Bash completions

    mkdir -p $out/share/bash-completion/completions

    cat <<-EOF > $out/share/bash-completion/completions/tmosh
      __load_completion mosh
      complete -o nospace -F _mosh tmosh
    EOF
    chmod +x $out/share/bash-completion/completions/tmosh

    cat <<-EOF > $out/share/bash-completion/completions/tssh
      __load_completion mosh
      complete -o nospace -F _mosh tssh
    EOF
    chmod +x $out/share/bash-completion/completions/tmosh
  '';
}
