{
  config,
  lib,
  pkgs,
  machines,
  ...
}:

let
  inherit (builtins)
    toFile
    ;
  inherit (lib)
    mkMerge
    mkIf
    concatStringsSep
    concatMapAttrs
    concatMapStringsSep
    optional
    genAttrs'
    ;
  keys = import ../keys/keys.nix;

in
{
  config = mkMerge [
    (mkIf (config.home.x_niols.xdgRuntimeDir != null && config.x_niols.isGraphical) {
      ## Pick up on gcr-ssh-agent statically. It would be cleaner to add this to
      ## something at runtime (eg. .bashrc) but then graphical programs (eg.
      ## Emacs) would not pick it up. gcr-ssh-agent is started on login by the
      ## NixOS configuration. See `nixos/_common/laptop/default.nix` (as of 28
      ## Nov 2025).
      ##
      ## https://joshtronic.com/2024/03/10/gnome-keyring-disables-ssh-agent/
      ##
      home.sessionVariables.SSH_AUTH_SOCK = "${config.home.x_niols.xdgRuntimeDir}/gcr/ssh";
    })

    (mkIf config.x_niols.isHeadless {
      ## On headless environments (servers), pick up the SSH agent from a
      ## deterministic location. This is meant to be used in conjunction with
      ## `keep-agent-alive` on the client side, which maintains a persistent SSH
      ## connection with agent forwarding and symlinks the agent socket here.
      home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.ssh/auth.sock";

      ## Every SSH session with agent forwarding symlinks its agent socket to the
      ## deterministic path above. This way, `keep-agent-alive` keeps it fresh,
      ## but a regular `ssh -A` also updates it.
      home.file.".ssh/rc" = {
        executable = true;
        text = ''
          #!/bin/sh
          if [ -n "$SSH_AUTH_SOCK" ]; then
            ln -sf "$SSH_AUTH_SOCK" ~/.ssh/auth.sock
          fi
        '';
      };
    })

    {
      programs.ssh = {
        enable = true;
        ## NOTE: Do not enable forward agent here, but rather on a host-by-host basis.
        extraOptionOverrides.AddKeysToAgent = "yes";
        ## NOTE: We don't need the default configuration, which is deprecated
        ## anyway, but we need the catch-all match block to be defined for
        ## `programs.ssh.extraConfig` to work, so we create it manually.
        enableDefaultConfig = false;
        matchBlocks."*" = { };
      };
    }

    {
      programs.ssh.matchBlocks =
        (concatMapAttrs (
          server: meta:
          ## For each server, we generate two blocks, one for the hostnames and
          ## one for the IPs. This ensures that we can connect to the IPs
          ## directly and that will still pick up on our configuration.
          let
            hosts = [
              server
              "${server}.niols.fr"
            ];
            ips =
              optional (meta ? ipv4) meta.ipv4
              ++ optional (meta ? ipv6) meta.ipv6
              ++ optional (meta ? internalIpv4) meta.internalIpv4
              ++ optional (meta ? internalIpv6) meta.internalIpv6;
            makeMatchBlock = hosts: {
              match = "Host ${concatStringsSep "," hosts}";
              user = "root";
              identitiesOnly = true;
              identityFile = "~/.ssh/id_niols";
              forwardAgent = true; # those are our machines, we trust them
              userKnownHostsFile = toFile "${server}-known_hosts" (
                concatMapStringsSep "\n" (ip: "${ip} ${keys.machines.${server}}") ips
              );
            };
          in
          {
            "${server}-hosts" = makeMatchBlock hosts // {
              hostname = meta.ipv4 or meta.ipv6 or meta.internalIpv4 or meta.internalIpv6;
            };
            "${server}-ips" = makeMatchBlock ips;
          }
        ) machines.servers)

        // {
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
    }

    ## Work-specific SSH config stuff
    ##
    (mkIf config.x_niols.isWork {
      programs.ssh = {
        ## NOTE: With pkgs.openssh and Ahrefs's configuration, I get GSS API
        ## errors. https://github.com/NixOS/nixops/issues/395 suggested to
        ## instead use `pkgs.opensshWithKerberos`.
        package = pkgs.opensshWithKerberos;

        ## The following configuration require that the correct symbolic link
        ## has been set up from `~/.ssh` into the right place in the Ahrefs
        ## monorepo.
        includes = [ "~/.ssh/ahrefs/config" ];
        matchBlocks.hop.user = "nicolas.jeannerod";

        ## Ahrefs's machines qualify as “weak” crypto from my modern SSH's POV, so
        ## we disable the warning for now. TODO: re-enable once Ahrefs moves on.
        extraConfig = "WarnWeakCrypto no";
      };
    })

    (mkIf (config.x_niols.isWork && config.x_niols.isGraphical) (
      let
        nspawnVariants = [
          "sg"
          "sgtrixie"
          "uk"
          "uktrixie"
          "us"
          "ustrixie"
        ];
        nspawnDefault = "uk";
        includeFor = variant: {
          extraOptions.Include = "~/.ssh/ahrefs/per-user/spawnbox-devbox-${variant}-nicolasjeannerod";
        };
        ## Mosh aliases go through the `mosh` wrapper which disables agent
        ## forwarding and starts `keep-agent-alive` as a systemd service.
        aliasFor = variant: "mosh --port 29700:29799 nspawn-${variant} -- tmux new-session";
      in
      {
        ## Set up the link to `nspawn-*` and a shorthand to start Mosh directly on
        ## the nspawn in question.
        programs.ssh.matchBlocks = {
          nspawn = includeFor nspawnDefault;
        }
        // (genAttrs' nspawnVariants (variant: {
          name = "nspawn-${variant}";
          value = includeFor variant;
        }));
        programs.bash.shellAliases = {
          mosh-nspawn = aliasFor nspawnDefault;
        }
        // (genAttrs' nspawnVariants (variant: {
          name = "mosh-nspawn-${variant}";
          value = aliasFor variant;
        }));
      }
    ))

    ## Add `keep-agent-alive`, a utility and systemd user service to maintain a
    ## persistent SSH connection with agent forwarding to a server. On the server
    ## side, the agent socket is symlinked to `~/.ssh/auth.sock` so that other
    ## sessions (eg. Mosh) can pick it up via `home.sessionVariables`. The service
    ## is a template unit: `systemctl --user start keep-agent-alive@<server>`.
    (mkIf config.x_niols.isWork (
      let
        sshPackage =
          if config.programs.ssh.package != null then config.programs.ssh.package else pkgs.openssh;
        keep-agent-alive = pkgs.writeShellApplication {
          name = "keep-agent-alive";
          runtimeInputs = [
            pkgs.autossh
            sshPackage
          ];
          text = ''
            if [ $# -ne 1 ]; then
              echo "Usage: keep-agent-alive <server>" >&2
              exit 1
            fi
            server="$1"
            echo "Keeping SSH agent alive on $server..."
            export AUTOSSH_PATH="${sshPackage}/bin/ssh"
            # shellcheck disable=SC2016
            exec autossh \
              -M 0 \
              -o "ServerAliveInterval 30" \
              -o "ServerAliveCountMax 3" \
              -o "ExitOnForwardFailure yes" \
              -A "$server" -- \
              'echo "Agent forwarding established ($(date +"%F %T"))." && exec sleep infinity'
          '';
        };
      in
      {
        home.packages = [ keep-agent-alive ];
        systemd.user.services."keep-agent-alive@" = {
          Unit.Description = "Keep SSH agent alive on %i";
          Service = {
            ExecStart = "${keep-agent-alive}/bin/keep-agent-alive %i";
            Environment = "SSH_AUTH_SOCK=${config.home.sessionVariables.SSH_AUTH_SOCK}";
          };
        };
      }
    ))

    ## Add `mosh` wrapper that disables agent forwarding and starts the
    ## `keep-agent-alive` systemd service in the background before connecting.
    {
      home.packages =
        let
          sshPackage =
            if config.programs.ssh.package != null then config.programs.ssh.package else pkgs.openssh;
        in
        [
          (pkgs.writeShellApplication {
            name = "mosh";
            text = ''
              ## Extract server name from arguments to start keep-agent-alive service.
              server=""
              skip_next=false
              for arg in "$@"; do
                if [ "$skip_next" = true ]; then
                  skip_next=false
                  continue
                fi
                case "$arg" in
                  --ssh|--predict|--port|--bind-server|--server|--family|--experimental-remote-ip)
                    skip_next=true ;;
                  --ssh=*|--predict=*|--port=*|--bind-server=*|--server=*|--family=*|--experimental-remote-ip=*)
                    ;;
                  --)
                    break ;;
                  -*)
                    ;;
                  *)
                    server="$arg"
                    break ;;
                esac
              done
              if [ -n "$server" ]; then
                systemctl --user start "keep-agent-alive@$server" 2>/dev/null &
              fi
              exec ${pkgs.mosh}/bin/mosh --ssh '${sshPackage}/bin/ssh -o ForwardAgent=no' "$@"
            '';
          })
        ];
    }
  ];
}
