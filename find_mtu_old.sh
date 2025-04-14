#!/bin/bash

TARGET_IP="$1"

if [ -z "$TARGET_IP" ]; then
  echo "Usage: $0 <wireguard_peer_ip>"
  exit 1
fi

echo "🔍 Testing MTU through WireGuard tunnel to $TARGET_IP..."

MIN=1200
MAX=1500
WORKING=0

while [ $MIN -le $MAX ]; do
  MID=$(( (MIN + MAX) / 2 ))
  PAYLOAD=$((MID - 28))  # ICMP + IP header
  if ping -c 1 -W 1 -M do -s "$PAYLOAD" "$TARGET_IP" &> /dev/null; then
    WORKING=$MID
    MIN=$((MID + 1))
  else
    MAX=$((MID - 1))
  fi
done

echo "✅ Highest working MTU through VPN: $WORKING"

# Suggest MTU for wg0 (WireGuard has about 60 bytes of overhead)
RECOMMENDED=$((WORKING - 60))
echo "🔧 Suggested WireGuard MTU setting: $RECOMMENDED"
