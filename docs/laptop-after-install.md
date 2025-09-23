# Laptop installation — what to do afterwards

- Check that all the services are running correctly:
  ```console
  $ systemctl status
  ```

- Set up this Git repository. Because we do not yet have the GPG and SSH keys,
  this will have to be as read-only for now:
  ```console
  $ git clone https://github.com/niols/nixos-config.git ~/.config/nixos
  $ cd ~/.config/nixos
  $ git checkout <machine>
  ```
  It should now be possible to run `rebuild --update` whenever another machine
  adds things to the configuration. It will fail when trying to add a tag to
  the repository, but that is of little impact.

- Set up Signal. This is easy via the phone and will allow using the other
  devices to send passwords in a secure way, before the new laptop is fully
  connected to the password manager and able to make Git commits.

- Set up Syncthing. Start `syncthingtray`, accept to “Start guided setup”, make
  sure to “Configure Syncthing Tray for currently running Syncthing instance”.
  Get the device's id, and add it to the common configuration. Rebuild the new
  device, _but also one of the other devices_! Syncing should start syncing
  everything.

- Set up the password manager `keepassxc`, once the `Organiser` Syncthing folder
  has been synced. Most of the settings should be installed with this configuration.
  In Browser Integration, however, make sure that Firefox is checked.

- Set up Firefox. This will automatically install the right add-ons and bring
  back the bookmarks. Nothing else to do.

- Set up Nextcloud. This is straightforward once Firefox is set up.

- Set up Autorandr. The default fingerprint is `0000` which will never work. Run
  `autorandr --fingerprint`, find the fingerprint for the display, and set
  `services.autorandr.x_niols.thisLaptopsFingerprint`.

- (REVIEW: obsolete?) Transfer GPG keys. On a machine that has the keys:
  ```console
  $ gpg --list-secret-keys
  $ gpg --export-secret-keys --armor <key-id>
  ```
  Then move the keys in a safe way between machines, and on the new machine:
  ```console
  $ gpg --import <key-file>
  ```

- Transfer SSH keys. You just need to copy the key files — typically in `~/.ssh`
  — to the new machine. They are already in a text-compatible format. Make sure
  that the private key has restrictive permissions:
  ```console
  $ chmod 600 ~/.ssh/id_niols
  ```

- Set up Git repositories. With the SSH and GPG key, everything should work fine
  immediately: cloning, committing, etc. Do not forget to update the URL of the
  NixOS configuration repository to now use SSH:
  ```console
  $ cd ~/.config/nixos
  $ git remote set-url origin git@github.com:niols/nixos-config.git
  $ git remote -v
  origin	git@github.com:niols/nixos-config.git (fetch)
  origin	git@github.com:niols/nixos-config.git (push)
  ```

- If using the unencrypted `/opt` for video games, set up Steam. Create a
  directory `/opt/steam` and make sure that the user has permission on this
  directory. Start Steam, log in, and go into the configuration, in the
  “Storage” tab. Add `/opt/steam` as a “drive”. Try installing a game and check
  that the choice appears to install it there. While you're at it, disable the
  Steam overlay. Also see [About Steam](./steam.md).

- Set up Thunderbird. This should be straightforward if the Autoconfig mechanism
  is set correctly for Niols Mail.

- Set up Doom Emacs. Check first that `~/.config/doom` has been installed correctly
  by Home Manager.
  ```console
  $ git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
  $ ~/.config/emacs/bin/doom install
  $ ~/.config/emacs/bin/doom sync
  ```
  Check [the official repository] for more up-to-date information. Then set up
  Forge, by creating a file `~/.netrc` containing, a minima:
  ```
  machine api.github.com
  login niols^forge
  password <redacted>
  ```
  The easiest is to copy it from another machine. See [the documentation of
  Forge] for more details.

[the official repository]: https://github.com/doomemacs/doomemacs
[the documentation of Forge]: https://magit.vc/manual/forge/Setup-for-Githubcom.html
