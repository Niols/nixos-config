Niols's NixOS Configuration/s
=============================

Installing NixOS
----------------

### Installing on an OVH's “Bare Metal Cloud” dedicated instance

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

I used an VM.Standard.A1.Flex instance. For this one, I followed [the tutorial
from blog.korfuri.fr] referencing the same [kexec configuration by
@cleverca22][cleverca22-kexec]

[the tutorial from blog.korfuri.fr]: https://web.archive.org/web/20230322224448/https://blog.korfuri.fr/posts/2022/08/nixos-on-an-oracle-free-tier-ampere-machine/

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
