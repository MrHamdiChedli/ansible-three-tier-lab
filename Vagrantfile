require "securerandom"

# The DB password is generated once and stays out of Git (see .gitignore).
SECRET_FILE = File.join(__dir__, ".db_password")
File.write(SECRET_FILE, SecureRandom.hex(16)) unless File.exist?(SECRET_FILE)
DB_PASSWORD = File.read(SECRET_FILE).strip

# Managed nodes boot as plain Ubuntu: Ansible configures everything.
NODES = [
  { name: "db",   ip: "192.168.56.20", memory: 1024 },
  { name: "web1", ip: "192.168.56.11", memory: 512 },
  { name: "web2", ip: "192.168.56.12", memory: 512 },
  { name: "lb",   ip: "192.168.56.10", memory: 512 },
]

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.boot_timeout = 600

  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.cpus = 1
  end

  NODES.each do |node|
    config.vm.define node[:name] do |machine|
      machine.vm.hostname = node[:name]
      machine.vm.network "private_network", ip: node[:ip]
      machine.vm.provider("virtualbox") { |vb| vb.memory = node[:memory] }
    end
  end

  # The control node is defined last so the others already exist when it runs Ansible.
  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "192.168.56.5"
    ctrl.vm.provider("virtualbox") { |vb| vb.memory = 1024 }
    # Ansible ignores ansible.cfg in a world-writable folder, which is the default for shared folders.
    ctrl.vm.synced_folder ".", "/vagrant", mount_options: ["dmode=755", "fmode=644"]
    ctrl.vm.provision "shell", path: "bootstrap/ctrl.sh", env: { "DB_PASSWORD" => DB_PASSWORD }
  end
end
