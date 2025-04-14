# Wireguard
I live behind a CGNAT internet and have no chance a public IP.  My real world answer to this was using a VPS as a way to get a public IP.  With NGINX Proxy Manager doing the SSL signitures and to forward any requests to an IP and port. 

I had been using tailscale, and quite frankly it worked great, but I wanted to try doing my own wireguard VPN, so I did my best to set some scripts to be repeatable.
 


This is a wireguard installer
```bash
wget https://raw.githubusercontent.com/mellow65/Wireguard/refs/heads/main/wg-install.sh -O wg-install.sh && bash wg-install.sh
```

Client side, copy config file to /etc/wireguard/wg0.conf


Bring up wg0
```bash
wg-quick up wg0
```

Stop wg0
```bash
wg-quick down wg0
```

Start wg0 on boot
```bash
systemctl enable wg-quick@wg0
```

Show status
```bash
wg show
```

```bash
fallocate -l 1G bigtestfile.bin
```

```bash
python3 -m http.server 8080 --bind 10.10.0.1
```

```bash
./test-speed.sh 10.10.0.1
```



This is a MTU Checker over VPN
```bash
wget https://raw.githubusercontent.com/mellow65/Wireguard/refs/heads/main/find_mtu.sh -O find_mtu.sh && bash find_mtu.sh
```

```bash
./bash find_mtu.sh
```
