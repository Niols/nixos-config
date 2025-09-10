# About Steam

### About controllers not being seen by Steam

#### Make sure the udev rules are correct

Valve maintains udev rules for various devices. See
[github:ValveSoftware/steam-devices/master/60-steam-input.rules] and check that
we have the appropriate rules for the device in question.

[github:ValveSoftware/steam-devices/master/60-steam-input.rules]: https://github.com/ValveSoftware/steam-devices/blob/master/60-steam-input.rules

#### Bluetooth: make sure the device is bonded

I have encountered the problem of a Nintendo Switch Pro Controller that would
appear in my Bluetooth devices, but not be seen by Steam. In fact, it was deeper
than that, it would not even register in the [HIDRAW API] at all. The reason was
that the Bluetooth device was paired, trusted and connected, _but not bonded_,
which some device require. The solution was to remove the device and connect
again, but using `bluetoothctl` instead of the GUI:

```console
$ bluetoothctl
> remove <mac>
> scan on
> devices
> pair <mac>
> trust <mac>
> connect <mac>
> info <mac>   # check that this shows "Bonded: yes"
```

[HIDRAW API]: https://docs.kernel.org/hid/hidraw.html
