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

On the **target machine**, remove `nix-cache.niols.fr/nixos-config` from
`/etc/nix/nix.conf` and `systemctl restart nix-daemon`.

On the deployer, run:

```
NIX_CONFIG="substituters = https://cache.nixos.org" nixops4 apply <args>
```
