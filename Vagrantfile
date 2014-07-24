require 'yaml'

yml = YAML.load_file("puppet/hieradata/commons.yaml")
nodes=yml['nodes']
nodes.select {|key,value| value['state'] == 1}.each do |key, value|
  Vagrant.configure("2") do |config|
    config.vm.box = key
    hostname = key
    addr = value['addr']
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"
    config.vm.synced_folder '.', "/usr/local/src/test-es/", :create => 'true'

    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    config.vm.define key do |key|
      key.vm.hostname = hostname
      key.vm.network :private_network, ip: addr
      key.vm.provider :virtualbox do |v, override|
        v.customize ["modifyvm", :id, "--memory", 4096]
        v.customize ["modifyvm", :id, "--cpus", 2]
      end
      key.vm.provision :shell, :path => 'shell/initial-setup.sh', :args => '/vagrant/shell'
      key.vm.provision :shell, :path => 'shell/update-puppet.sh', :args => '/vagrant/shell'
      key.vm.provision :shell, :path => 'shell/librarian-puppet-vagrant.sh', :args => '/vagrant/shell'
      key.vm.provision :puppet do |puppet|
        puppet.manifests_path = "puppet/manifests"
        # puppet.module_path    = "puppet/modules"
        puppet.hiera_config_path = "puppet/hiera.yaml"
        puppet.manifest_file = "base.pp"
        puppet.facter = {
          "host_environment" => "Vagrant",
          "vm_type" => "vagrant",
          "enable_marvel_agent" => false
        }
        puppet.options = "--verbose"
      end
    end
  end
end
