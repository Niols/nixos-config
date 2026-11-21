# Nebula

Mesh of machines with discovery, so they share a common internal network. I used
to do this with WireGuard but it handled poorly that several machines would be
roaming (eg. laptops + homelab). Nebula handles this perfectly fine with the
notion of lighthouses, namely machines that are accessible reliably and will
help others connect together. It also handles falling back on the local network,
eg. between laptops and the homelab.

## (Re-)generating the CA

For 1 year = 8760 hours:

```
nebula-cert ca -name mesh -duration 8760h0m0s
```

This creates two files, `ca.crt`, which can be distributed to all machines, and
`ca.key`, which should be kept as protected as possible and only used to enrol a
new machine.

## Enrolling a new machine

```
nebula-cert sign -ca-crt ./ca.crt -ca-key ./ca.key -name <name> -networks <internalIpCidr>
```

As of November 2026, internal IPs in CIDR are `10.187.94.<index>/24`.
