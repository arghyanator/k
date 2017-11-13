VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
      
  # config.vm.synced_folder ".", "/vagrant", id: "vagrant-root", disabled: true
  #
  # ETCD Cluster
  # ============
  #
    config.vm.define :etcd1 do |etcd1|
    etcd1.vm.box = "ubuntu/xenial64"
    etcd1.vm.hostname = "etcd1"
    etcd1.vm.network :private_network, ip: "192.168.56.201"
    etcd1.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    etcd1.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    etcd1.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      #chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_etcd"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end

  config.vm.define :etcd2 do |etcd2|
    etcd2.vm.box = "ubuntu/xenial64"
    etcd2.vm.hostname = "etcd2"
    etcd2.vm.network :private_network, ip: "192.168.56.202"
    etcd2.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    etcd2.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    etcd2.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      #chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_etcd"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end

  config.vm.define :etcd3 do |etcd3|
    etcd3.vm.box = "ubuntu/xenial64"
    etcd3.vm.hostname = "etcd3"
    etcd3.vm.network :private_network, ip: "192.168.56.203"
    etcd3.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    etcd3.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    etcd3.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      #chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_etcd"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end  

  # Configire HA HAProxy with KeepAlived
  # ====================================

  config.vm.define :haproxy1 do |haproxy1|
    haproxy1.vm.box = "ubuntu/xenial64"
    haproxy1.vm.hostname = "haproxy1"
    haproxy1.vm.network :private_network, ip: "192.168.56.211"
    haproxy1.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    haproxy1.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    haproxy1.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_haproxy_keepalived"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end

  config.vm.define :haproxy2 do |haproxy2|
    haproxy2.vm.box = "ubuntu/xenial64"
    haproxy2.vm.hostname = "haproxy2"
    haproxy2.vm.network :private_network, ip: "192.168.56.212"
    haproxy2.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    haproxy2.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    haproxy2.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_haproxy_keepalived"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end

  # Configure Kubernetes Master
  # ===========================
  config.vm.define :k8smaster1 do |k8smaster1|
    k8smaster1.vm.box = "ubuntu/xenial64"
    k8smaster1.vm.hostname = "k8smaster1"
    k8smaster1.vm.network :private_network, ip: "192.168.56.231"
    k8smaster1.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # Disable the default /vagrant folder in VBox VMs
    k8smaster1.vm.synced_folder ".", "/vagrant", disabled: true
    # Create our own Synced Folder
    k8smaster1.vm.synced_folder "./master_share", "/master/share"
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    k8smaster1.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    k8smaster1.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_kubernetes_master"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end
  config.vm.define :k8smaster2 do |k8smaster2|
    k8smaster2.vm.box = "ubuntu/xenial64"
    k8smaster2.vm.hostname = "k8smaster2"
    k8smaster2.vm.network :private_network, ip: "192.168.56.232"
    k8smaster2.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # Disable the default /vagrant folder in VBox VMs
    k8smaster2.vm.synced_folder ".", "/vagrant", disabled: true
    # Create our own Synced Folder
    k8smaster2.vm.synced_folder "./master_share", "/master/share"
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    k8smaster2.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    k8smaster2.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_kubernetes_master"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end
  config.vm.define :k8smaster3 do |k8smaster3|
    k8smaster3.vm.box = "ubuntu/xenial64"
    k8smaster3.vm.hostname = "k8smaster3"
    k8smaster3.vm.network :private_network, ip: "192.168.56.233"
    k8smaster3.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # Disable the default /vagrant folder in VBox VMs
    k8smaster3.vm.synced_folder ".", "/vagrant", disabled: true
    # Create our own Synced Folder
    k8smaster3.vm.synced_folder "./master_share", "/master/share"
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    k8smaster3.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    k8smaster3.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_kubernetes_master"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end

  # Configure Kubernetes Worker
  # ===========================
  config.vm.define :k8sslave1 do |k8sslave1|
    k8sslave1.vm.box = "ubuntu/xenial64"
    k8sslave1.vm.hostname = "k8sslave1"
    k8sslave1.vm.network :private_network, ip: "192.168.56.235"
    k8sslave1.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    # Disable the default /vagrant folder in VBox VMs
    k8sslave1.vm.synced_folder ".", "/vagrant", disabled: true
    # Create our own Synced Folder
    k8sslave1.vm.synced_folder "./master_share", "/master/share"
    # config.vm.synced_folder "vagrant/chef-repo", "/home/ubuntu/chef-repo"
    # Install Chef-client inside Vbox guest VM
    k8sslave1.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    # Use chef provisioning
    k8sslave1.vm.provision "chef_zero" do |chef|
      # Specify the local paths where Chef data is stored
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
      #chef.roles_path = "roles"
  
      # Add a recipe
      chef.add_recipe "install_kubernetes_slave"
  
      # Or maybe a role
      #chef.add_role "web"
    end
  end
end

