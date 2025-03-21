Niols's NixOS Configuration/s
=============================

Installing NixOS
----------------

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

### e2-micro

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

borg list <repo>
borg list <repo>::<archive>
borg export-tar <repo>::<archive> output.tar
borg extract <repo>::<archive> <path>

borg list ssh://u363090@hester.niols.fr:23/backups/syncthing
borg list ssh://u363090@hester.niols.fr:23/backups/syncthing::siegfried-syncthing-2025-01-23T06:00:00 output.tar
