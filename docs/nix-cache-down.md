# When the Nix cache is down

There is always this annoying situation when the Nix cache is down where
`nixops4 apply <target>` fails with:

```
nixops| warning: error: unable to download 'https://nix-cache.niols.fr/nixos-config/v81i2j8wirf5dfsym8pja3iakqidyx1b.narinfo': HTTP error 502
nixops|
nixops|        response body:
nixops|
nixops|        <html>
nixops|        <head><title>502 Bad Gateway</title></head>
nixops|        <body>
nixops|        <center><h1>502 Bad Gateway</h1></center>
nixops|        <hr><center>nginx</center>
nixops|        </body>
nixops|        </html>; retrying in 2448 ms
nixops| Nix crashed. This is a bug. Please report this at https://github.com/NixOS/nix/issues with the following information included:
[...]
```

On 26 May, I found a way around it, but I messed up with many things and it is
unclear which one helped:

- Removed `nix-cache.niols.fr/nixos-config` from `/etc/nix/nix.conf` and `systemctl restart nix-daemon`
- Same but on the target machine (this one is the one that got it working)
- Same for `~/.config/nix/nix.conf` on local machine
- Run `nixops4 apply` with `NIX_CONFIG="substituters = https://cache.nixos.org"`
- Removed `~/.local/share/nix/trusted-settings.json`
- Made sure there was no `.#nixConfig` that would include them.

I need to check again which ones were necessary. The one on the target machine
was crucial, but I don't really understand why it was even necessary.
