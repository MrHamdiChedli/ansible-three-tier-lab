#!/usr/bin/env bash
# Runs the playbook again: on an already configured stack, Ansible must change nothing.
set -euo pipefail

output=$(vagrant provision ctrl 2>&1) || { echo "$output"; echo "FAIL: the playbook failed"; exit 1; }
recap=$(echo "$output" | grep -E '^\s*(ctrl: )?\s*(db|web1|web2|lb)\s+: ok=')
echo "$recap"

if echo "$recap" | grep -qvE 'changed=0 .*failed=0'; then
  echo "FAIL: the second run changed something"
  exit 1
fi
echo "PASS: second run changed nothing"
