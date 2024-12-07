{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "tmosh";
  src = ./.; # or anything; this is unused
  installPhase = ''
    mkdir -p $out/bin
    cat <<'EOF' > $out/bin/tmosh
      #!/bin/sh
      exec ${pkgs.mosh}/bin/mosh "$@" -- \
        tmux new -s tmosh_$(date +'%Y-%m-%d_%H-%M-%S')_$RANDOM
    EOF
    chmod +x $out/bin/tmosh
    mkdir -p $out/share/bash-completion/completions
    cat <<-EOF > $out/share/bash-completion/completions/tmosh
      #!/bin/sh
      source ${pkgs.mosh}/share/bash-completion/completions/mosh
      complete -o nospace -F _mosh tmosh
    EOF
    chmod +x $out/share/bash-completion/completions/tmosh
  '';
}
