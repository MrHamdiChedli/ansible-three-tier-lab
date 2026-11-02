#!/usr/bin/env bash
# Checks the whole stack from outside, then stops web1 and checks the service survives.
set -euo pipefail

LB_URL="${1:-http://192.168.56.10}"
fail() { echo "FAIL: $1"; exit 1; }

hits() {
  for _ in $(seq 1 "$1"); do
    curl -fsS --max-time 5 "$LB_URL/" || fail "request to $LB_URL/ failed"
    echo
  done
}
served_by() { grep -o '"served_by":"[^"]*"' | sort -u | wc -l | tr -d ' '; }

echo "1. Health check through the load balancer"
curl -fsS --max-time 5 "$LB_URL/healthz" > /dev/null || fail "/healthz is not healthy"

echo "2. Traffic reaches both web servers"
[ "$(hits 10 | served_by)" = "2" ] || fail "expected 2 servers to answer"

echo "3. The counter is shared through the database"
first=$(hits 1 | grep -o '"visits":[0-9]*' | cut -d: -f2)
second=$(hits 1 | grep -o '"visits":[0-9]*' | cut -d: -f2)
[ "$second" -gt "$first" ] || fail "counter did not increase ($first then $second)"

echo "4. The web servers are not reachable directly"
if curl -fsS --max-time 3 "http://192.168.56.11:8000/" > /dev/null 2>&1; then
  fail "web1 answered without going through the load balancer"
fi

echo "5. Failover: stop web1, every request must still succeed"
vagrant ssh web1 -c "sudo systemctl stop app" > /dev/null 2>&1
trap 'vagrant ssh web1 -c "sudo systemctl start app" > /dev/null 2>&1' EXIT
[ "$(hits 10 | served_by)" = "1" ] || fail "expected only web2 to answer"

echo "PASS: all checks succeeded"
