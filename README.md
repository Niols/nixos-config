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