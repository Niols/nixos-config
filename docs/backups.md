# Backups

## Don't forget the `.well-known`

Some services (eg. Matrix) rely on a `.well-known` file at the root of the
`niols.fr` web pages. Restarting these services requires checking that
`niols.fr` is up and that the `.well-known` files are up to date.

## Create a new Borg backup repository

1. Create a repokey, eg a 64-character-long random string:
   ``` console
   $ tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo
   AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
   ```

2. Create an SSH key pair:
   ``` console
   $ ssh-keygen -t ed25519 -C '' -N '' -f hester-<service>-backup-identity
   ```

3. Add the repokey and the private key as secrets in Agenix:
   ``` console
   $ cd secrets
   $ emacs -nw secrets.nix
   $ agenix -e hester-<service>-backup-repokey.age
   $ agenix -e hester-<service>-backup-identity.age
   ```

4. Make Hester aware of the public key:
   ``` console
   ssh-copy-id -sfi hester-<service>-backup-identity.pub hester
   ```

5. Initialise the backup repository:
   ``` console
   $ borg init --encryption repokey ssh://u363090@hester.niols.fr:23/./backups/<service>
   ```
   Use as “passphrase” the repokey chosen above.

6. Check that everything works fine, by running, _on the server_:
   ``` console
   $ borg list ssh://u363090@hester.niols.fr:23/./backups/<service>
   Enter passphrase for key ssh://u363090@hester.niols.fr:23/./backups/<service>:
   $ systemctl start borgbackup-job-<service>.service
   $ journalctl --no-pager --lines 3 --unit borgbackup-job-<service>.service
   Apr 22 14:32:09 <machine> systemd[1]: Started BorgBackup job <service>.
   Apr 22 14:32:18 <machine> systemd[1]: borgbackup-job-<service>.service: Deactivated successfully.
   Apr 22 14:32:18 <machine> systemd[1]: borgbackup-job-<service>.service: Consumed 4.778s CPU time, 67M memory peak, 28.9M read from disk, 1.1M written to disk, 145.9K incoming IP traffic, 18.7M outgoing IP traffic.
   $ borg list ssh://u363090@hester.niols.fr:23/./backups/<service>
   Enter passphrase for key ssh://u363090@hester.niols.fr:23/./backups/<service>:
   <machine>-<service>-2025-04-22T14:32:09  Tue, 2025-04-22 16:32:12 [aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa]
   ```
   The first command, `borg list`, is not just here to be pretty, and will in
   fact serve to establish the connection between the server and Hester, such
   that they can check each other's keys in the future.

## Restore Borg backups

Borg CLI excerpts:

``` console
$ borg list <repo>
$ borg list <repo>::<archive>
$ borg export-tar <repo>::<archive> output.tar
$ borg extract <repo>::<archive> <path>
```

Example restore workflow:

``` console
$ borg list ssh://u363090@hester.niols.fr:23/./backups/syncthing
$ borg list ssh://u363090@hester.niols.fr:23/./backups/syncthing::siegfried-syncthing-2025-01-23T06:00:00
$ mkdir where-to-restore
$ cd where-to-restore
$ borg extract ssh://u363090@hester.niols.fr:23/./backups/syncthing::siegfried-syncthing-2025-01-23T06:00:00
$ ls
```

## Restore a Postgres backup

Typically, the backup lives in `/var/backup/postgres`. It is probably
compressed:

``` console
$ gunzip the-backup.sql.gz
```

Import it in Postgres. If restoring on a machine that does not have the service
yet, you might have to create the role first. Creating it only with `LOGIN`
means it is the Unix user that will have access.

```console
$ sudo -u postgres psql
postgres=# CREATE ROLE "the-role" WITH LOGIN;
$ sudo -u postgres psql < the-backup.sql
```
