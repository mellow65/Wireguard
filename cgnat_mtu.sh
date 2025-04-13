#!/bin/bash

# This script attempts to find the optimal MTU for a CGNAT connection.

HOST="$1"

if [ -z "$HOST" ]; then
  echo "Usage: $0 <wireguard_peer_ip>"
  exit 1
fi

echo "🔍 Testing MTU through WireGuard tunnel to HOST..."


# Defaults
#HOST="1.1.1.1" # Target host for MTU testing (Cloudflare's DNS)
CGNAT_OVERHEAD=20 # Estimated overhead in bytes for CGNAT (adjust if necessary)
START_MTU=1500 # Starting MTU value for Ethernet
MIN_MTU=1200 # Minimum MTU value to test

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
