## Syncthing

Syncthing requires a key/cert pair to identify a device. This key pair can be
generated with:

``` console
$ openssl ecparam -genkey -name secp384r1 -out key.pem
$ openssl req -new -x509 -key key.pem -out cert.pem -subj "/CN=syncthing"
```

See https://docs.syncthing.net/dev/device-ids.html for more information
