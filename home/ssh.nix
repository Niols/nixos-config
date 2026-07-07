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

  remoteSshAuthSock = home: "${home}/.ssh/auth.sock";

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
      home.sessionVariables.SSH_AUTH_SOCK = remoteSshAuthSock config.home.homeDirectory;

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
        settings."*" = { };
      };
    }

    {
      programs.ssh.settings =
        (concatMapAttrs (
          server: meta:
          let
            fqdn = "${server}.niols.fr";
            ips = optional (meta ? ipv4) meta.ipv4 ++ optional (meta ? ipv6) meta.ipv6;
          in
          {
            ${server} = {
              header = "Host ${
                concatStringsSep " " (
                  ips
                  ++ [
                    server
                    fqdn
                  ]
                )
              }";
              User = "root";
              IdentitiesOnly = true;
              IdentityFile = "~/.ssh/id_niols";
              ForwardAgent = true; # those are our machines, we trust them
              UserKnownHostsFile = toFile "${server}-known_hosts" (
                concatMapStringsSep "\n" (ip: "${ip} ${keys.machines.${server}}") (ips ++ [ fqdn ])
              );
            };

            "${server}-short" = {
              header = "Host ${server}";
              HostName = fqdn;
            };
          }
        ) machines.servers)

        // {
          hester = {
            HostName = "hester.niols.fr";
            Port = 23;
            User = "u363090";
          };

          ## Mions
          nasgul = {
            HostName = "nasgul.jeannerod.me";
            Port = 40022;
            User = "niols";
          };
          gimli = {
            HostName = "192.168.1.11";
            User = "root";
            PubkeyAuthentication = "no";
            PreferredAuthentications = "password";
          };

          ## Youth Branch VPS
          vpsyb = {
            HostName = "137.74.166.97";
            User = "root";
            PubkeyAuthentication = "no";
            PreferredAuthentications = "password";
          };

          ## For things on localhost, we should not check the host's key, and we
          ## should just not keep the keys at all.
          localhost = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
          "*.localhost" = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
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
        settings.hop.User = "nicolas.jeannerod";

        ## Ahrefs's machines qualify as “weak” crypto from my modern SSH's POV, so
        ## we disable the warning for now. TODO: re-enable once Ahrefs moves on.
        settings."*".WarnWeakCrypto = "no";
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
        nspawnDefault = "uktrixie";
        includeFor = variant: {
          Include = "~/.ssh/ahrefs/per-user/spawnbox-devbox-${variant}-nicolasjeannerod";
        };
        ## Nspawn aliases go through the `mosh` wrapper which disables agent
        ## forwarding and starts `keep-agent-alive` as a systemd service.
        aliasFor = variant: "mosh --port 29700:29799 nspawn-${variant} -- tmux new-session";
      in
      {
        ## Set up the link to `nspawn-*` and a shorthand to start Mosh directly on
        ## the nspawn in question.

        programs.ssh.settings = {
          nspawn = includeFor nspawnDefault;
        }
        // (genAttrs' nspawnVariants (variant: {
          name = "nspawn-${variant}";
          value = includeFor variant;
        }));

        programs.bash.shellAliases = {
          nspawn = aliasFor nspawnDefault;
        }
        // (genAttrs' nspawnVariants (variant: {
          name = "nspawn-${variant}";
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
          runtimeInputs = [ sshPackage ];
          text = ''
            if [ $# -ne 1 ]; then
              echo "Usage: keep-agent-alive <server>" >&2
              exit 1
            fi
            server="$1"
            echo "Establishing agent forwarding with $server..."
            "${sshPackage}/bin/ssh" \
              -o ServerAliveInterval=10 \
              -o ServerAliveCountMax=2 \
              -o ForwardAgent=yes \
              -o ExitOnForwardFailure=yes \
              "$server" -- \
              'echo "Agent forwarding established." && while true; do
                 sleep 10
                 [ -e "${remoteSshAuthSock "."}" ] || { echo "Lost auth socket."; exit 88; }
               done'
          '';
          ## NOTE: In the previous script, we crucially use `remoteSshAuthSock`
          ## and not `config.home.sessionVariables.SSH_AUTH_SOCK`, because the
          ## latter would be interpreted on the graphical machine.
        };
      in
      {
        home.packages = [ keep-agent-alive ];
        systemd.user.services."keep-agent-alive@" = {
          Unit.Description = "Keep SSH agent alive on %i";
          Service = {
            ExecStart = "${keep-agent-alive}/bin/keep-agent-alive %i";
            Environment = "SSH_AUTH_SOCK=${config.home.sessionVariables.SSH_AUTH_SOCK}"; # forward SSH_AUTH_SOCK into the service
            Restart = "always"; # restart no matter what
            RestartSec = "1sec"; # wait at least 1 second before retrying
            RestartMaxDelaySec = "1min"; # don't wait more than 1 minute before retrying
            RestartSteps = "4"; # number of steps to back off from RestartSec to RestartMaxDelaySec
          };
          Unit.StartLimitIntervalSec = "0"; # prevent systemd from exiting if too many failures occur in the same time window
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
