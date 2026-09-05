# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Box no oficial para Ubuntu 26.04 (devel)
  config.vm.box = "alvistack/devel-26.04"

  # Red privada para pruebas
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "8192"
    vb.cpus = 4
    vb.name = "moodle-dev"
  end

  # Ajustes de hardware
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Provision con Ansible usando inventario YAML
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/site.yml"
    ansible.inventory_path = "inventory/staging/hosts.yml"
    ansible.become = true
    ansible.ask_vault_pass = true
    ansible.verbose = "v"
    ansible.extra_vars = {
      dominio_web: "moodle.local",
      dominio_correo: "mail.local",
      ip_publica: "192.168.56.10",
      admin_user: "mario",
      admin_ssh_port: 6022,
    }
  end

  config.vm.post_up_message = "Servidor de pruebas listo. Accede a https://moodle.local (añade al hosts) o IP 192.168.56.10"
end
