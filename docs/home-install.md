Standalone Home installation
----------------------------

On a Nix-enabled machine, replace `<home>` in the following command and go:

```console
$ nix --extra-experimental-features 'nix-command flakes' run github:niols/nixos-config#rebuild -- --home-profile <home>
```

This will clone the configuration in `~/.config/nixos`, build it and enable it
with `home-manager`, add a tag to the repository. After that, `rebuild -u` is
enough to pull updates — the script will remember which home profile to pick.

### Installing Nix

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

### Setting up SSH keys and Agenix

If the home in question uses Agenix (which it probably does), you will need to
copy the right identity onto the machine; without it, the rebuild will fail.

Similarly, the correct SSH keys should be copied in the right way. For some of
them, copying the public key and relying on agent forwarding should be enough.
For others, they should be scp'd.
