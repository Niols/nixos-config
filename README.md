Niols's NixOS Configuration/s
=============================

Installing
----------

- [Laptop installation](./docs/laptop-install.md) and [what do to afterwards](./docs/laptop-after-install.md)
- [Server installation](./docs/server-install.md)
- [Standalone Home installation](./docs/home-install.md)

Documentation
-------------

- [Backups](./docs/backups.md)
- [Disko](./docs/disko.md)
- [Steam](./docs/steam.md)
- [Syncthing](./docs/syncthing.md)
- [Xfce](./docs/xfce.md)

Organisation
------------

- [`flake.nix`](./flake.nix) is the entry point of these configurations. The
  flake defines outputs for the NixOS and Home configurations, NixOps4
  deployments, and checks.

- [`home/`](./home) contains my core Home configuration module. All homes are
  based on this configuration, with some variations depending on high-level
  options, (eg. `x_niols.isHeadless` or `x_niols.isWork`).

- [`nixos/`](./nixos) contains my NixOS confguration modules, for both laptops
  and servers. [`nixos/flake-part.nix`](./nixos/flake-part.nix) injects the
  correct high-level options to specialise the configuration as needed.

- [`common/`](./common) contains a module shared by both Home and NixOS
  configurations, for instance to define my list of core packages.

- [`secrets/`](./secrets) contains the Agenix-encrypted secrets that get my
  world to run. [`secrets/secrets.nix`](./secrets/secrets.nix) maps secrets to
  machines, and [`secrets/flake-part.nix`](./secrets/flake-part.nix) defines the
  NixOS and Home modules injecting them in my configurations.

- [`keys/`](./keys) contains the public key of my various devices. This is used,
  among other things, for secrets management.
