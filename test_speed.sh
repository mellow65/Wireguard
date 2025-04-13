#!/bin/bash

# test_speed.sh

URL="http://10.10.0.1:8080/largefile.bin"
DEST="largefile.bin"

echo "Starting download from $URL ..."
curl -o "$DEST" "$URL" --progress-meter -w "\nDownload complete\nAverage speed: %{speed_download} bytes/sec\n" | \
  awk '
    /Average speed:/ {
      speed_bytes = $3
      speed_mbps = (speed_bytes * 8) / 1000000
      printf "Average speed: %.2f Mb/s\n", speed_mbps
    }
  '
