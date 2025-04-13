# Wireguard
A semi standard install of wireguard so I could get access to my home lab.  


This is a wireguard installer
```bash
wget https://raw.githubusercontent.com/mellow65/Debian-11-Unifi/refs/heads/main/wg-install.sh -O wg-install.sh && bash wg-install.sh
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


This is a MTU Checker over VPN
```bash
wget https://raw.githubusercontent.com/mellow65/Debian-11-Unifi/refs/heads/main/find_mtu.sh -O find_mtu.sh && bash find_mtu.sh 10.10.0.1
```

```bash
./bash find_mtu.sh 10.10.0.1
```
