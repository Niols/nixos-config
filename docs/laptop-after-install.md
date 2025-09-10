# Laptop installation — what to do afterwards

- Check that all the services are running correctly:
  ```console
  $ systemctl status
  ```

- Set up Signal. This is easy via the phone and will allow using the other
  devices to send passwords in a secure way, before the new laptop is fully
  connected to the password manager and able to make Git commits.

- Set up Syncthing. Start `syncthingtray`, accept to “Start guided setup”, make
  sure to “Configure Syncthing Tray for currently running Syncthing instance”.
  Get the device's id, and add it to the other devices' configuration. Syncing
  should start.

- Check access to the password manager `keepassxc`, once the `Organiser`
  Syncthing folder has been synced.

- Set up Firefox. This will automatically install the right add-ons and bring
  back the bookmarks. Nothing else to do.

- Set up Nextcloud. This is straightforward once Firefox is set up.

- Set up Autorandr. The default fingerprint is `0000` which will never work. Run
  `autorandr --fingerprint`, find the fingerprint for the display, and set
  `services.autorandr.x_niols.thisLaptopsFingerprint`.

- Transfer GPG and SSH keys. ???

- If using the unencrypted `/opt` for video games, set up Steam. Create a
  directory `/opt/steam` and make sure that the user has permission on this
  directory. Start Steam, log in, and go into the configuration, in the
  “Storage” tab. Add `/opt/steam` as a “drive”. Try installing a game and check
  that the choice appears to install it there. While you're at it, disable the
  Steam overlay. See [About Steam](./steam.md).

- Set up Thunderbird. ???

- Set up Doom Emacs. ??? (unless we push Doom into the Nix configuration)
