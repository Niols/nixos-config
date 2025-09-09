Niols's NixOS Configuration/s
=============================

Installing NixOS
----------------

### Installing on a ThinkPad X1 Carbon Gen 9

1. Boot into the USB stick.

2. (Optional) Set up WiFi:
   ```console
   $ sudo systemctl start wpa_supplicant
   $ wpa_cli
   [...]
   Selected interface 'wlp0s20f3'
   Interactive mode
   > scan
   OK
   [...]
   > scan_results
   bssid / frequency / signal level / flags / ssid
   4a:ed:00:1b:60:54     5220     -41     [WPA-PSK+SAE-CCMP][ESS]     Name of hotspot
   [...]
   > add_network
   0
   [...]
   > set_network 0 ssid "<SSID>"
   OK
   > set_network 0 psk "<PASSPHRASE>"
   OK
   > enable_network 0
   OK
   [...]
   > quit
   ```

3. Clone this repository and go in it.
   ```console
   $ git clone https://github.com/niols/nixos-config
   $ cd nixos-config
   $ nix --extra-experimental-features 'nix-command flakes' develop
   [...]
   ```

4. If this is a new target machine:

   1. Generate a new SSH host key pair, add the public key to the repository:
      ```console
      $ ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N ''
      Generating public/private ed25519 key pair.
      [...]
      $ cp ssh_host_ed25519_key.pub keys/machines/<machine>.pub
      ```

   2. Figure out the interface names and set `x_niols.thisLaptopsWifiInterface`
      accordingly.
      ```console
      $ ip link
      [...]
      2. wlp0s20f3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu [...]
      [...]
      $ vi <machine>/default.nix
      ```

   3. Figure out the display fingerprint and set
      `services.autorandr.x_niols.thisLaptopsFingerprint` accordingly.
      ```console
      $ autorandr --fingerprint
      eDP-1 00fffff[...]
      $ autorandr --fingerprint | grep eDP-1 | cut -d ' ' -f 2 >> <machine>/default.nix
      $ vi <machine>/default.nix
      ```

   4. Commit and push those changes:
      ```console
      $ git commit -am 'Add <machine> specifics'
      $ git push
      ```

   5. On another machine, pull the new public key, update `secrets/secrets.nix`
      to add the new machine wherever necessary, then rekey, commit and push.
      ```console
      $ git pull
      $ cd secrets && agenix --rekey
      $ git add secrets
      $ git commit -m 'Rekey secrets'
      $ git push
      ```
      Back on the target machine, pull.
      ```console
      $ git pull
      ```

5. Run `disko` to format the disk. ```console $ disko --mode
   destroy,format,mount --flake .#<configuration> ``` Be careful: `disko` will
   target the disk labels (eg. `/dev/sdX`) mentioned in that configuration.
   However, the configuration's labels are from the target's perspective, and
   that might not be how they are seen from the installation medium! In my case,
   it works by luck, because the installation medium is a USB stick at
   `/dev/sda` while the target disk is an SSD at `/dev/nvme0n1`.

6. Run `nixos-install` to install the full system.
   ```console
   $ nixos-install --flake .#<configuration>
   ```

7. If this is a new target machine, do not forget to add the private host key in
   the right place:
   ```console
   $ mv ssh_host_ed25519_key* /mnt/etc/ssh/
   ```

#### Notes on `disko-install`

Can be ran with:

``` console
$ disko-install --mode format --flake .#<configuration> --disk main /dev/<device>
```

##### on the `--disk` argument

The `--disk main /dev/<device>` argument might seem silly considering that this
information is available in the configuration, but it is necessary. Without it,
you get the (confusing) error:

```
error:
Failed assertions:
- You must set the option 'boot.loader.grub.devices' or 'boot.loader.grub.mirroredBoots' to make the system bootable.
```

The reason behind it behind it being mandatory is that the configuration's
labels are from the target's perspective, and that might not be how they are
seen from the installation medium. `disko-install` avoids you lucking out by
requiring that you pass this argument.

I wish `disko` had a similar easy way to override disks. There is a `--arg`
argument, but I don't really understand how it works. Relevant issue:
https://github.com/nix-community/disko/issues/999

##### on “no space left on device”

In the early days, when I tried to use `disko-install`, I ran into:

```
error (ignored): error: writing to file: No space left on device
error:
       - writing file '/nix/store/<some derivation>/<some path>'

       error: writing to file: No space left on device
/nix/store/<some disko path>/bin/.disko-install-wrapped: line 234: artifacts[1]: unbound variable
```

Contrary to one might expect, `disko-install` first builds the configuration,
and then formats, mounts, and copies the configuration. This means that, in
comparison to `disko` + `nixos-install`, it can fail on big configurations,
depending on the installation medium. Indeed, `nixos-install`, in this scenario,
will be able to use the target disk's Nix store directly, while `disko-install`
on a USB stick will be limited by whatever ramfs has been provided for its
`/nix/store`. Relevant issue: https://github.com/nix-community/disko/issues/942

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
