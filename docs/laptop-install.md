# Laptop installation

The following steps have been tested on a ThinkPad X1 Carbon Gen 9 and another
Gen 13 in September 2025.

1. Boot into the USB stick.

2. (Optional) Set up WiFi:
   ```console
   $ sudo systemctl start wpa_supplicant.service
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

3. Clone this repository, go in it, check out the machine-specific branch if
   there is one, and spin the installation-specific Shell environment.
   ```console
   $ git clone https://github.com/niols/nixos-config
   $ cd nixos-config
   $ git checkout <machine>
   $ nix --extra-experimental-features 'nix-command flakes' develop .#install
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
      $ vi nixos/<machine>.nix
      ```

   3. Commit and push those changes. Beware NOT to push the private key.
      ```console
      $ git config user.name <name>
      $ git config user.email <email>
      $ git add keys
      $ git commit --message='Add <machine> public key'
      $ git add nixos/<machine>.nix
      $ git commit --message='Add <machine> WiFi interface'
      $ git push
      ```
      If the repository is hosted on GitHub, pushing with credentials will not
      be possible. A solution is to log in with `gh` and
      [a personal token](https://github.com/settings/tokens):
      ```console
      $ gh auth login
      ? Where do you use GitHub? GitHub.com
      ? What is your preferred protocol for Git operations on this host? HTTPS
      ? Authenticate Git with your GitHub credentials? Yes
      ? How would you like to authenticate GiHub CLI? Paste an authentication token
      Tip: you can generate a Personal Access Token here https://github.com/settings/tokens
      The minimum required scopes are 'repo', 'read:org", 'workflow'.
      ? Paste your authentication token: ***************
      ```
      A classic personal token is easier to create and shorter to copy. Make
      sure it has the required scopes above.

   4. On another machine, pull the new public key, update `secrets/secrets.nix`
      to add the new machine wherever necessary, potentially adding secrets. An
      easy method is to look where other laptops are used an mimmick them. As of
      September 2025, this involves creating secrets for Syncthing. Rekey the
      old secrets, commit and push.
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

5. Run `disko` to format the disk.
   ```console
   $ sudo disko --mode destroy,format,mount --flake .#<configuration>
   ```
   Be careful: `disko` will target the disk labels (eg. `/dev/sdX`) mentioned in
   that configuration. However, the configuration's labels are from the target's
   perspective, and that might not be how they are seen from the installation
   medium! In my case, it works by luck, because the installation medium is a
   USB stick at `/dev/sda` while the target disk is an SSD at `/dev/nvme0n1`.

6. Run `nixos-install` to install the full system.
   ```console
   $ sudo nixos-install --flake .#<configuration>
   ```

7. If this is a new target machine, do not forget to add the private host key in
   the right place:
   ```console
   $ sudo chmod 600 ssh_host_ed25519_key
   $ sudo chmod 644 ssh_host_ed25519_key.pub
   $ sudo chown root:root ssh_host_ed25519_key*
   $ sudo mv ssh_host_ed25519_key* /mnt/etc/ssh/
   ```

8. Reboot and see [Laptop installation — what to do afterwards](./laptop-after-install.md).

### Notes on `disko-install`

Can be ran with:

``` console
$ disko-install --mode format --flake .#<configuration> --disk main /dev/<device>
```

#### on the `--disk` argument

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
