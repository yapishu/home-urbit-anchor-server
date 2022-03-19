# WireGuard anchor server

This Docker container runs a Wireguard server that listens for a webhook to generate a new peer configuration. 

The webhook parses a JSON payload for a `name` and a `pubkey`, which it uses to append a peer entry to `wg0.conf` and restart the interface, then generates a peer configuration file in a volume at `/mnt/conf`.

To test (localhost address for testing from inside the container):

```
curl -H "Content-Type: application/json" -d "{\"name\":\"testuser\",\"pubkey\":\"GpfbBvrn+ctTqV4anuvjZw9C04cSnRX2kRUx3AunuX8=\"}" -X PUT http://127.0.0.1:9000/hooks/new-peer
```
