# Wireguard
I live behind a CGNAT internet and have no chance a public IP.  My real world answer to this was using a VPS as a way to get a public IP.  With NGINX Proxy Manager doing the SSL signitures and to forward any requests to an IP and port. 

I had been using tailscale, and quite frankly it worked great, but I wanted to try doing my own wireguard VPN, so I did my best to set some scripts to be repeatable.


This is a wireguard installer
```bash
wget https://raw.githubusercontent.com/mellow65/Wireguard/refs/heads/main/wg-install.sh -O wg_install.sh && bash wg_install.sh
```

Client side, copy config file to /etc/wireguard/wg0.conf


Bring up wg0
```bash
wg-quick up wg0
systemctl enable wg-quick@wg0
```

Stop wg0
```bash
wg-quick down wg0
```

Show status
```bash
wg show
```

This is a MTU Checker over VPN
```bash
wget https://raw.githubusercontent.com/mellow65/Wireguard/refs/heads/main/find_mtu.sh -O find_mtu.sh && bash find_mtu.sh
```

```bash
./bash find_mtu.sh
```


I had issues running IPERF over the VPN connection so I migraded over setting up a http server just so I could move a file over the VPN connection and see what kind of speed I was able to get.  This is only a one way trip, if you want to check the other direction reverse the setup.

On VPS side.
```bash
fallocate -l 0.2G largefile.bin  #makes a 0.2G file we're going to use as our test file.
python3 -m http.server 8080 --bind 10.10.0.1 #enter the IP of the wireguard, if using my scipt it should be 10.10.0.1
```


On Home server
```bash
wget https://raw.githubusercontent.com/mellow65/Wireguard/refs/heads/main/test_speed.sh -O test_speed.sh && bash test_speed.sh
```




