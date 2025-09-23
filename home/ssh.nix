{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkMerge mkIf;

in

{
  config = mkMerge [
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        extraOptionOverrides.AddKeysToAgent = "yes";
      };

      ## We don't actually use GPG much, but we like the GPG Agent and it has
      ## good integration with Emacs, so we use this as our SSH Agent.
      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        enableBashIntegration = true;
        enableSshSupport = true; # for SSH agent
        enableExtraSocket = true; # for agent forwarding
        ## Pinentry configuration
        pinentry.package = pkgs.pinentry-gtk2; # REVIEW: pinentry-curses for headless systems?
        extraConfig = ''
          allow-emacs-pinentry
          allow-loopback-pinentry
        '';
      };
    }

    ## Personal stuff
    (mkIf (!config.x_niols.isWork) {
      programs.ssh.matchBlocks = {
        ## My machines
        ##
        ## TODO: This part should be generated (except Hester), and we should
        ## generate a `userKnownHostsFile` based on the keys in the `keys/`
        ## directory.
        helga = {
          host = "helga";
          hostname = "helga.niols.fr";
          user = "root";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_niols";
        };
        orianne = {
          host = "orianne";
          hostname = "orianne.niols.fr";
          user = "root";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_niols";
        };
        siegfried = {
          host = "siegfried";
          hostname = "siegfried.niols.fr";
          user = "root";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_niols";
        };
        hester = {
          host = "hester";
          user = "u363090";
          hostname = "hester.niols.fr";
          port = 23;
        };

        ## Mions
        nasgul = {
          host = "nasgul";
          hostname = "nasgul.jeannerod.me";
          port = 40022;
          user = "niols";
        };
        gimli = {
          user = "root";
          hostname = "192.168.1.11";
          extraOptions.PubkeyAuthentication = "no";
          extraOptions.PreferredAuthentications = "password";
        };

        ## Youth Branch VPS
        vpsyb = {
          host = "vpsyb";
          user = "root";
          hostname = "137.74.166.97";
          extraOptions.PubkeyAuthentication = "no";
          extraOptions.PreferredAuthentications = "password";
        };

        ## For things on localhost, we should not check the host's key, and we
        ## should just not keep the keys at all.
        localhost = {
          host = "localhost";
          extraOptions.StrictHostKeyChecking = "no";
          extraOptions.UserKnownHostsFile = "/dev/null";
        };
        localhost_star = {
          host = "*.localhost";
          extraOptions.StrictHostKeyChecking = "no";
          extraOptions.UserKnownHostsFile = "/dev/null";
        };
      };
    })

    ## NOTE: A lot of things in the following configuration require the the
    ## correct symbolic link has been set up from `~/.ssh` into the right place
    ## on the Ahrefs monorepo.

    ## Work stuff
    (mkIf config.x_niols.isWork {
      programs.ssh = {
        ## NOTE: With pkgs.openssh and Ahrefs's configuration, I get GSS API
        ## errors. https://github.com/NixOS/nixops/issues/395 suggested to
        ## instead use `pkgs.opensshWithKerberos`.
        package = pkgs.opensshWithKerberos;
        includes = [ "~/.ssh/ahrefs/config" ];
        matchBlocks.hop.user = "nicolas.jeannerod";
      };
    })

    ## Work stuff, but only on laptop
    (mkIf (config.x_niols.isWork && !config.x_niols.isHeadless) {
      programs.ssh = {
        matchBlocks = {
          nspawn.extraOptions.Include = "~/.ssh/ahrefs/per-user/spawnbox-devbox-uk-nicolasjeannerod";
          ## Only the laptop has my personal identity files.
          "github.com".identityFile = "~/.ssh/id_niols";
          "*" = {
            identitiesOnly = true;
            identityFile = "~/.ssh/id_ahrefs";
          };
        };
      };
    })

    ## Add mosh to the packages, as well as `tmosh` (mosh+tmux) and `tssh`
    ## (ssh+tmux).
    {
      home.packages = [
        pkgs.mosh
        (
          let
            sshPackage =
              if config.programs.ssh.package != null then config.programs.ssh.package else pkgs.openssh;
          in
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
                exec ${sshPackage}/bin/ssh "$@" -- \
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
        )
      ];
    }
  ];
}
