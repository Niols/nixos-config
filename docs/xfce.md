# Xfce

## Translating Xfce configuration into Home Manager's `xfconf.settings`

```console
$ for chan in $(xfconf-query -l | tail -n +2); do for prop in $(xfconf-query -c $chan -l); do printf '%s\t%s\t%s\n' $chan $prop "$(xfconf-query -c $chan -p $prop)"; done; done > before.txt
[...change settings in the interface...]
$ for chan in $(xfconf-query -l | tail -n +2); do for prop in $(xfconf-query -c $chan -l); do printf '%s\t%s\t%s\n' $chan $prop "$(xfconf-query -c $chan -p $prop)"; done; done > after.txt
$ diff before.txt after.txt
[...]
```
