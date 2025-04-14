#!/bin/bash

# This script attempts to find the optimal MTU for a CGNAT or a VPN connection.

# Prompt user for HOST
read -p "Enter IP or domain to ping (e.g., 1.1.1.1, VPS Wireguard IP: 10.10.0.1, VPN host name: us8240.nordvpn.com): " HOST
HOST="${HOST:-1.1.1.1}"  # Default to 1.1.1.1 if empty

# Prompt user for CGNAT overhead
read -p "Enter an overhead in bytes (CGNAT can be upto 20, wireguard upto 60, recomend one at a time): " CGNAT_OVERHEAD
CGNAT_OVERHEAD="${CGNAT_OVERHEAD:-20}"  # Default to 20 if empty

echo "🔍 Testing MTU to $HOST..."
echo "🌐 Byte Overhead set to $CGNAT_OVERHEAD bytes"

# Defaults
START_MTU=1500 # Starting MTU value for Ethernet
MIN_MTU=1200   # Minimum MTU value to test


echo "Starting MTU optimization with $CGNAT_OVERHEAD overhead, change in script if wanted"

# Adjust MTU based on CGNAT overhead
CALCULATED_MTU=$((START_MTU))

# Function to test MTU
test_mtu() {
  local mtu=$1
  if ping -c 2 -M do -s $((mtu - 28)) "$HOST" &>/dev/null; then
    return 0 # Success
  else
    return 1 # Failure
  fi
}

# Perform binary search to find the best MTU
optimal_mtu=$CALCULATED_MTU
while [ $optimal_mtu -ge $MIN_MTU ]; do
  echo "Testing MTU: $optimal_mtu"
  if test_mtu "$optimal_mtu"; then
    echo "MTU $optimal_mtu is valid."
    break
  else
    echo "MTU $optimal_mtu is too high, reducing..."
    optimal_mtu=$((optimal_mtu - 2))
  fi
done

if [ $optimal_mtu -lt $MIN_MTU ]; then
  echo "Failed to find a valid MTU above the minimum threshold ($MIN_MTU)."
  exit 1
fi

echo "Optimal MTU without fragmentation: $optimal_mtu"
recommended_mtu=$((optimal_mtu - CGNAT_OVERHEAD)) # Subtract CGNAT and other protocol overheads
echo "Recommended MTU for WireGuard: $recommended_mtu"

# Display results
echo "Optimization complete."
echo "  Target Host: $HOST"
echo "  CGNAT Overhead: $CGNAT_OVERHEAD bytes"
echo "  Found Optimal MTU: $optimal_mtu"
echo "  Recommended MTU for CGNAT: $recommended_mtu"

exit 0
