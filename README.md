Niols's NixOS Configuration/s
=============================

Setting up Home on another machine
----------------------------------

On a Nix-enabled machine, replace `<home>` in the following command and go:

```
$ git clone git@github.com:niols/nixos-config ~/.config/nixos
$ nix --extra-experimental-features 'nix-command flakes' run ~/.config/nixos#home-manager -- --extra-experimental-features 'nix-command flakes' switch --impure --flake ~/.config/nixos#<home>
```

TODO: Make a `switch` command, similar to `rebuild`.

Nix should preferrably be installed via the package manager, provided the
packaged version is recent enough. Otherwise, one can follow [the instructions
on nixos.org](https://nixos.org/download/), eg.:
```console
$ sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100  4267  100  4267    0     0  13180      0 --:--:-- --:--:-- --:--:-- 13180
[...]
Installation finished!  To ensure that the necessary environment
variables are set, either log in again, or type

    . <home>/.nix-profile/etc/profile.d/nix.sh

in your shell.
```

Installing NixOS
----------------

### Installing on a laptop

See [Laptop installation](./docs/laptop-install.md).

### On an OVH's “Bare Metal Cloud” dedicated instance

/!\ I never managed to reproduce this.

Here is the protocol I followed successfuly to install my OVH “Bare Metal Cloud”
(ex-Kimsufi) instance in March 2023:

1. From the default Debian system installed automatically by OVH, follow the
   NixOS wiki page on [installing on a server with a different
   filesystem][install-server]. In particular, use [@cleverca22's kexec
   configuration][cleverca22-kexec].

2. Once rebooted to a NixOS in RAM, follow the NixOS manual's instructions for
   [installation with manual partitioning][install-manual].

3. Create an appropriate server configuration. I did some things manually but I
   also got inspired by [@jonringer's server configuration][jonringer-config].
   One must not forget the instructions from the first link about networking.

[install-server]: https://web.archive.org/web/20230322224506/https://nixos.wiki/wiki/Install_NixOS_on_a_Server_With_a_Different_Filesystem
[cleverca22-kexec]: https://github.com/cleverca22/nix-tests/tree/2ba968302208ff0c17d555317c11fd3f06e947e2/kexec
[install-manual]: https://web.archive.org/web/20230325142657/https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-partitioning
[jonringer-config]: https://github.com/jonringer/server-configuration/blob/6c0e8b85dfd99c40bb72c5825bbf259a85d9f18d/configuration.nix

### Installing on a Hetzner Cloud machine

#### CX22

I did not manage to reproduce the instructions for Oracle VM.Standard.A1.Flex,
using the tutorial and commit hash `ccf0985677903aff729794180bdaf4b390f35023` of
the [nix-tests] repository.

However, it looks like [nixos-infect] did a fine job, but I had to restart the
machine a few times? Unsure, because I also made a mess of my AAAA DNS record
and that caused some very slow commands that looked like things were broken.

### Installing on an Oracle Cloud machine

#### VM.Standard.A1.Flex

For this one, I followed [the tutorial from blog.korfuri.fr] referencing the
same [kexec configuration by @cleverca22][cleverca22-kexec]

[the tutorial from blog.korfuri.fr]: https://web.archive.org/web/20230322224448/https://blog.korfuri.fr/posts/2022/08/nixos-on-an-oracle-free-tier-ampere-machine/

#### VM.Standard.E2.1.Micro

I first installed a regular Ubuntu 22.04 on the machine and set up my SSH key,
all via the Oracle Cloud web interface. I then used [nixos-infect] to transform
it into a NixOS machine, which worked like a charm.

```
curl https://raw.githubusercontent.com/elitak/nixos-infect/c9419eb629f03b7abcc0322340b6aaefb4eb2b60/nixos-infect \
    | NIX_CHANNEL=nixos-22.11 bash -x
```

[nixos-infect]: https://github.com/elitak/nixos-infect

From the infected machine, I then get the SSH host keys, update the secrets to
contain a password for the users, and then clone the configuration in
`/etc/nixos` and rebuild.

Because these machines have little memory, it is good to add swap. One could do
that in a clean way with a partition. However, because we rely on
[nixos-infect], this is not really doable. It is however easy to add eg. 4GB of
swap with NixOS in `hardware-configuration.nix`:

```
swapDevices = [ { device = "/var/lib/swapfile"; size = 4*1024; } ];
```

It can also be interesting to add a zramSwap.

Confirmed in August 2023.

### Installing on a Google Cloud machine

#### t2a-standard-4

See Oracle's VM.Standard.A1.Flex above.

#### e2-micro

See Oracle's VM.Standard.E2.1.Micro above.

How to use
----------

### About the flake input `secrets`

The flake input `secrets`:

```nix
secrets.url = "github:niols/nixos-secrets";
secrets.flake = false;
```

is a private repository. If it is in the cache of the machine, then
there is no need to do anything special. If it is not (the very first
time or whenever one updates the lock file), then one needs to give
Nix access to private repositories on GitHub. This can be done via an
access token, with eg.:

```
sudo nixos-rebuild switch --option access-tokens github.com=ghp_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

The configuration builds fine without the secrets, so one can also just override
that input and give an empty directory. For instance, the CI runs:

```
nix build \
    .#nixosConfigurations.<name>.config.system.build.toplevel \
    --override-input secrets $(mktemp -d)
```

Backups
-------

### Don't forget the `.well-known`

Some services (eg. Matrix) rely on a `.well-known` file at the root of the
`niols.fr` web pages. Restarting these services requires checking that
`niols.fr` is up and that the `.well-known` files are up to date.

### Create a new Borg backup repository

1. Create a repokey, eg a 64-character-long random string:
   ``` console
   $ tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo
   AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
   ```

2. Create an SSH key pair:
   ``` console
   $ ssh-keygen -t ed25519 -C '' -N '' -f hester-<service>-backup-identity
   ```

3. Add the repokey and the private key as secrets in Agenix:
   ``` console
   $ cd secrets
   $ emacs -nw secrets.nix
   $ agenix -e hester-<service>-backup-repokey.age
   $ agenix -e hester-<service>-backup-identity.age
   ```

4. Make Hester aware of the public key:
   ``` console
   ssh-copy-id -sfi hester-<service>-backup-identity.pub hester
   ```

5. Initialise the backup repository:
   ``` console
   $ borg init --encryption repokey ssh://u363090@hester.niols.fr:23/./backups/<service>
   ```
   Use as “passphrase” the repokey chosen above.

6. Check that everything works fine:
   ``` console
   $ borg list ssh://u363090@hester.niols.fr:23/./backups/<service>
   Enter passphrase for key ssh://u363090@hester.niols.fr:23/./backups/<service>:
   $ systemctl start borgbackup-job-<service>.service
   $ journalctl --no-pager --lines 3 --unit borgbackup-job-<service>.service
   Apr 22 14:32:09 <machine> systemd[1]: Started BorgBackup job <service>.
   Apr 22 14:32:18 <machine> systemd[1]: borgbackup-job-<service>.service: Deactivated successfully.
   Apr 22 14:32:18 <machine> systemd[1]: borgbackup-job-<service>.service: Consumed 4.778s CPU time, 67M memory peak, 28.9M read from disk, 1.1M written to disk, 145.9K incoming IP traffic, 18.7M outgoing IP traffic.
   $ borg list ssh://u363090@hester.niols.fr:23/./backups/<service>
   Enter passphrase for key ssh://u363090@hester.niols.fr:23/./backups/<service>:
   <machine>-<service>-2025-04-22T14:32:09  Tue, 2025-04-22 16:32:12 [aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa]
   ```

### Restore Borg backups

Borg CLI excerpts:

``` console
$ borg list <repo>
$ borg list <repo>::<archive>
$ borg export-tar <repo>::<archive> output.tar
$ borg extract <repo>::<archive> <path>
```

Example restore workflow:

``` console
$ borg list ssh://u363090@hester.niols.fr:23/./backups/syncthing
$ borg list ssh://u363090@hester.niols.fr:23/./backups/syncthing::siegfried-syncthing-2025-01-23T06:00:00
$ mkdir where-to-restore
$ cd where-to-restore
$ borg extract ssh://u363090@hester.niols.fr:23/./backups/syncthing::siegfried-syncthing-2025-01-23T06:00:00
$ ls
```

### Restore a Postgres backup

Typically, the backup lives in `/var/backup/postgres`. It is probably
compressed:

``` console
$ gunzip the-backup.sql.gz
```

Import it in Postgres. If restoring on a machine that does not have the service
yet, you might have to create the role first. Creating it only with `LOGIN`
means it is the Unix user that will have access.

```console
$ sudo -u postgres psql
postgres=# CREATE ROLE "the-role" WITH LOGIN;
$ sudo -u postgres psql < the-backup.sql
```

## Syncthing

Syncthing requires a key/cert pair to identify a device. This key pair can be
generated with:

``` console
$ openssl ecparam -genkey -name secp384r1 -out key.pem
$ openssl req -new -x509 -key key.pem -out cert.pem -subj "/CN=syncthing"
```

See https://docs.syncthing.net/dev/device-ids.html for more information
