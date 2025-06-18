{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "rnix";
  src = ./.; # or anything; this is unused

  installPhase = ''
    ############################################################################
    ## Binaries

    mkdir -p $out/bin

    cat <<'EOF' > $out/bin/rnix
      #!/bin/sh
      exec ${pkgs.nix}/bin/nix \
        --builders '@/etc/nix/machines' \
        "$@"
    EOF
    chmod +x $out/bin/rnix

    cat <<'EOF' > $out/bin/rrnix
      #!/bin/sh
      exec ${pkgs.nix}/bin/nix \
        --builders '@/etc/nix/machines' --max-jobs 0 \
        "$@"
    EOF
    chmod +x $out/bin/rrnix

    cat <<'EOF' > $out/bin/rnom
      #!/bin/sh
      exec ${pkgs.nix-output-monitor}/bin/nom \
        --builders '@/etc/nix/machines' \
        "$@"
    EOF
    chmod +x $out/bin/rnom

    cat <<'EOF' > $out/bin/rrnom
      #!/bin/sh
      exec ${pkgs.nix-output-monitor}/bin/nom \
        --builders '@/etc/nix/machines' --max-jobs 0 \
        "$@"
    EOF
    chmod +x $out/bin/rrnom

    ############################################################################
    ## Bash completions

    mkdir -p $out/share/bash-completion/completions

    cat <<-EOF > $out/share/bash-completion/completions/rnix
      __load_completion nix
      complete -F _complete_nix rnix
    EOF
    chmod +x $out/share/bash-completion/completions/rnix

    cat <<-EOF > $out/share/bash-completion/completions/rrnix
      __load_completion nix
      complete -F _complete_nix rrnix
    EOF
    chmod +x $out/share/bash-completion/completions/rrnix

    cat <<-EOF > $out/share/bash-completion/completions/rnom
      __load_completion nix
      complete -F _complete_nix rnom
    EOF
    chmod +x $out/share/bash-completion/completions/rnom

    cat <<-EOF > $out/share/bash-completion/completions/rrnom
      __load_completion nix
      complete -F _complete_nix rrnom
    EOF
    chmod +x $out/share/bash-completion/completions/rrnom
  '';
}
