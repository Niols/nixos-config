# ZFS

A lot of ZFS-related Disko options only ever have an impact during initial
installation, and changing them later will have no effect. We still set them in
our configuration for documentation purposes, but one needs to also apply the
change manually to ZFS. This document describes how to apply modifications to an
existing ZFS. It is not meant as a ZFS cheatsheet but really as a ZFS+disko
cheatsheet.

## Format a disk how disko would do it

Add it to the configuration and push the configuration to some branch, then run `disko --dry-run`. For instance:

```console
# disko --dry-run --mode format,mount --flake github:niols/nixos-config/<branch>#anastasia
disko version 1.13.0
/nix/store/<hash>-disko-format-mount/bin/disko-format-mount
```

This outputs a path to the script that disko would run. Reading it shows
the exact commands that disko would run for each disk, which one can then
run themselves. As of November 2026, this looks like:

```console
# blkid "/dev/disk/by-id/<disk id>"
/dev/disk/by-id/<disk id>: PTUUID="<uuid>" PTTYPE="gpt"

# sgdisk --clear "/dev/disk/by-id/<disk id>"
The operation has completed successfully.

# sgdisk --align-end --new=1:0:-0 --partition-guid="1:R" --change-name="1:<some name>" --typecode=1:8300 --attributes=1:=:0 "/dev/disk/by-id/<disk id>"
The operation has completed successfully.

# partprobe "/dev/disk/by-id/<disk id>"

# udevadm trigger --subsystem-match=block

# udevadm settle --timeout 120
```

`sgdisk` comes from `gptfdisk` and `partprobe` from (among others) `busybox`.

Then proceed to attaching the new disks to their ZFS pool (see below).

## Add or remove a dataset to/from an existing pool

```console
# zfs create -o mountpoint=legacy <pool>/<dataset>
# zfs destroy <pool>/<dataset>
```

Then redeploy the machine to actually make the directory. This does not contain
the actual mountpoint, because that is only for the mounting systemd unit, not
for ZFS.

## Add a disk to an existing pool:

```
# zpool attach <zpool> <vdev> /dev/disk/by-id/<disk id>-part1
```

where:

- `zpool` is the name of the pool, eg. `important`
- `vdev` is an existing device in the pool to resilver from, typically an
  already-plugged-in, healthy disk
- Mind the `-part1`. Without it, we give the whole disk to ZFS, which will then
  reformat it in its own way, which would disalign reality and disko.

The attach command returns immediately (~15s) but the resilver happens in the
background and can take hours. Check with `zpool status important`. For
instance:

```console
# zpool status important
  pool: important
 state: DEGRADED
status: One or more devices is currently being resilvered.  The pool will
        continue to function, possibly in a degraded state.
action: Wait for the resilver to complete.
  scan: resilver in progress since Fri Nov 13 10:30:03 2026
        418G / 580G scanned at 17.4G/s, 1.58G / 580G issued at 67.4M/s
        1.56G resilvered, 0.27% done, 02:26:34 to go
config:

        NAME              STATE     READ WRITE CKSUM
        important         DEGRADED     0     0     0
          mirror-0        DEGRADED     0     0     0
            <disk A>      ONLINE       0     0     0
            <disk B>      UNAVAIL      0     0     0  was /dev/disk/by-id/...
            <disk C>      ONLINE       0     0     0  (resilvering)

errors: No known data errors
```

Alternatively, `-w` can be passed to make the `attach` command wait until
resilvering is finished.

## Remove a disk from an existing pool

```console
# zpool detach <zpool> <disk id>
```

If the disk is being replaced, it is preferable to wait until the resilvering of
the new disk is done before detaching this one; otherwise, the pool will
consider itself healthy (even with just one disk!) even though we are in an
unsafe situation.
