#!/usr/bin/env bash
# Exercise the client's actual environment. Do not add --insecure or a test CA.
# Usage: bash checks/emudhra-tls.sh [curl-binary]
set -euo pipefail

curl_bin=${1:-curl}
failed=0

request() {
  "$curl_bin" -q --silent --show-error --connect-timeout 5 --max-time 20 \
    --output /dev/null "https://$1/"
}

if request emudhra.we-have-a-problem.com; then
  echo "PASS: valid HTTPS control"
else
  echo "FAIL: valid HTTPS control; rejection tests alone cannot establish protection" >&2
  exit 1
fi

for kind in dv ov ev; do
  for generation in g3b g3c; do
    for route in '' '-aaa'; do
      host="${kind}-${generation}${route}-emudhra.we-have-a-problem.com"
      if request "$host"; then
        echo "FAIL: accepted compromised chain: $host" >&2
        failed=1
      else
        status=$?
        if [ "$status" -eq 60 ]; then
          echo "PASS: certificate rejected: $host"
        else
          echo "FAIL: inconclusive error $status: $host" >&2
          failed=1
        fi
      fi
    done
  done
done

exit "$failed"
