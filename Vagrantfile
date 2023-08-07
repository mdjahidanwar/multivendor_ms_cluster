require 'yaml'
cnf = YAML::load(File.open('manifest.yml'))

instances = cnf['instances']
box = cnf['box']
provider = cnf['provider']
name_prefix = cnf['name_prefix']
name_suffix = cnf['name_suffix']
ip_prefix = cnf['ip_prefix']
storage_devices = cnf['storage_devices']
disk_size = cnf['disk_size']
memory = cnf['memory']
cpus = cnf['cpus']
path = cnf['path']

Vagrant.configure("2") do |config|
  instances.times do |i|
    node_id = "#{name_prefix}#{i}"
    config.vm.define node_id do |node|
      node.vm.box = "#{box}"
      node.vm.hostname = "#{node_id}#{name_suffix}"
      #node.ssh.username = "admin"
      #node.ssh.private_key_path = "~/.ssh/id_rsa"
      node.ssh.forward_agent = true

      #node.vm.network  "public_network", bridge: "bridge0", ip: "#{ip_prefix}#{i}"
      node.vm.network  "public_network",bridge: "Intel(R) 82579LM Gigabit Network Connection", ip: "#{ip_prefix}#{i}"
      node.vm.provider "#{provider}" do |vm|
        vm.memory = "#{memory}"
        vm.cpus = "#{cpus}"
        #next two lines are for the ssh bug
        #vm.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
        #vm.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
        if "#{provider}" === "libvirt"
          storage_devices.times do |j|
            vm.storage :file, :size => "#{disk_size}" 
          end
        end
      end
      node.vm.provision "shell", path: "#{path}", args: "#{name_prefix}, #{ip_prefix}, #{instances}"
    end
  end
end