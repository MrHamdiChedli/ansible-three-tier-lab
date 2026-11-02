#!/usr/bin/env bash
# Installs Ansible on the control node, then runs the playbook against the 4 managed nodes.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [ ! -x /opt/ansible/bin/ansible-playbook ]; then
  apt-get update -qq
  apt-get install -y -qq python3-venv
  python3 -m venv /opt/ansible
  /opt/ansible/bin/pip install --quiet --disable-pip-version-check "ansible-core>=2.17,<2.18"
fi

# Vagrant created one SSH key per node; copy them with the strict permissions SSH requires.
install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh/nodes
for node in db web1 web2 lb; do
  install -m 600 -o vagrant -g vagrant \
    "/vagrant/.vagrant/machines/$node/virtualbox/private_key" "/home/vagrant/.ssh/nodes/$node"
done

cd /vagrant/ansible
run_as_vagrant() { sudo -u vagrant env PATH="/opt/ansible/bin:$PATH" DB_PASSWORD="$DB_PASSWORD" "$@"; }
run_as_vagrant ansible-galaxy collection install --upgrade -r requirements.yml > /dev/null
run_as_vagrant ansible-playbook site.yml
