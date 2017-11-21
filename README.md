Kubernetes cluster on VirtualBox and Vagrant 
============================================

Spin up VirtualBox VM and install Etcd, haproxy and Kubernetes using Chef and Vagrant

__Reference:__ https://github.com/kelseyhightower/kubernetes-the-hard-way

But...I made it the really really Hard Way...

__Min Host Requirements:__ 16GB of RAM (good luck trying it with 8GB!!!)

Install Virtual Box on MAC:
---------------------------
http://download.virtualbox.org/virtualbox/5.1.30/VirtualBox-5.1.30-118389-OSX.dmg

Install Vagrant:
----------------
https://releases.hashicorp.com/vagrant/2.0.0/vagrant_2.0.0_x86_64.dmg
 

Install Ubuntu/Xenial 16.04 Virtual VM using Vagrant:
------------------------------------------------------
```
$ mkdir my_etcd
$ cd my_etcd
$ vagrant init
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.

$ vagrant box add ubuntu/xenial64
==> box: Loading metadata for box 'ubuntu/xenial64'
    box: URL: https://vagrantcloud.com/ubuntu/xenial64
==> box: Adding box 'ubuntu/xenial64' (v20171011.0.0) for provider: virtualbox
    box: Downloading: https://vagrantcloud.com/ubuntu/boxes/xenial64/versions/20171011.0.0/providers/virtualbox.box
==> box: Successfully added box 'ubuntu/xenial64' (v20171011.0.0) for 'virtualbox'!
```
Check if Vagrant Box was downloaded
```
$ vagrant box list
ubuntu/xenial64 (virtualbox, 20171011.0.0)
```

Modify Vagrantfile to add Chef Cookbooks (For all the nodes):
-------------------------------------------------------------
```
$ egrep -v "^$|^#| #" Vagrantfile 
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
      
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
    etcd1.vm.synced_folder ".", "/vagrant", disabled: true
    etcd1.vm.synced_folder "./master_share", "/master/share"
    etcd1.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    etcd1.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_etcd"
  
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
    etcd2.vm.synced_folder ".", "/vagrant", disabled: true
    etcd2.vm.synced_folder "./master_share", "/master/share"
    etcd2.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    etcd2.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_etcd"
  
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
    etcd3.vm.synced_folder ".", "/vagrant", disabled: true
    etcd3.vm.synced_folder "./master_share", "/master/share"
    etcd3.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    etcd3.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_etcd"
  
    end
  end  
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
    haproxy1.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    haproxy1.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_haproxy_keepalived"
  
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
    haproxy2.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    haproxy2.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_haproxy_keepalived"
  
    end
  end
  config.vm.define :k8smaster1 do |k8smaster1|
    k8smaster1.vm.box = "ubuntu/xenial64"
    k8smaster1.vm.hostname = "k8smaster1"
    k8smaster1.vm.network :private_network, ip: "192.168.56.231"
    k8smaster1.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "2048"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    k8smaster1.vm.synced_folder ".", "/vagrant", disabled: true
    k8smaster1.vm.synced_folder "./master_share", "/master/share"
    k8smaster1.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    k8smaster1.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_kubernetes_master"
  
    end
  end
  config.vm.define :k8smaster2 do |k8smaster2|
    k8smaster2.vm.box = "ubuntu/xenial64"
    k8smaster2.vm.hostname = "k8smaster2"
    k8smaster2.vm.network :private_network, ip: "192.168.56.232"
    k8smaster2.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "2048"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    k8smaster2.vm.synced_folder ".", "/vagrant", disabled: true
    k8smaster2.vm.synced_folder "./master_share", "/master/share"
    k8smaster2.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    k8smaster2.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_kubernetes_master"
  
    end
  end
  config.vm.define :k8smaster3 do |k8smaster3|
    k8smaster3.vm.box = "ubuntu/xenial64"
    k8smaster3.vm.hostname = "k8smaster3"
    k8smaster3.vm.network :private_network, ip: "192.168.56.233"
    k8smaster3.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "2048"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    k8smaster3.vm.synced_folder ".", "/vagrant", disabled: true
    k8smaster3.vm.synced_folder "./master_share", "/master/share"
    k8smaster3.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    k8smaster3.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_kubernetes_master"
  
    end
  end
  config.vm.define :k8sslave1 do |k8sslave1|
    k8sslave1.vm.box = "ubuntu/xenial64"
    k8sslave1.vm.hostname = "k8sslave1"
    k8sslave1.vm.network :private_network, ip: "192.168.56.235"
    k8sslave1.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "2048"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.gui = true
    end
    k8sslave1.vm.synced_folder ".", "/vagrant", disabled: true
    k8sslave1.vm.synced_folder "./master_share", "/master/share"
    k8sslave1.vm.provision "shell", inline: "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 13.2.20"
    k8sslave1.vm.provision "chef_zero" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.data_bags_path = "data_bags"
      chef.nodes_path = "cookbooks/nodes"
  
      chef.add_recipe "install_kubernetes_slave"
  
    end
  end
end


```

Create the VirtualBox HostOnly Network for VMs
----------------------------------------------
![HostOnly_network](https://github.com/arghyanator/k/blob/master/HostOnly_networks.png)
![HostOnly_network_subnet](https://github.com/arghyanator/k/blob/master/HostOnly_networks_subnet.png)

Boot up VMs and Install software using Vagrant
-----------------------------------------------
__Note__: Dont forget to create the nodes folder in which Vagrant will create the chef node JSONs and master_share folder which is mounted on all VMs to share files.
```
$ mkdir cookbooks/nodes
$ mkdir master_share
```

__Also,__ create the Data Encryption Key and using that key create the encryption-config.yaml file for master install cookbook
```
$ head -c 32 /dev/urandom | base64 
```
Finally...
```
$ vagrant up 
```
Chef configuration
------------------
```
$ tree cookbooks/
cookbooks/
├── install_etcd
│   ├── files
│   │   ├── ca-config.json
│   │   ├── ca-csr.json
│   │   ├── check_etcd.sh
│   │   └── kubernetes-csr.json
│   ├── recipes
│   │   ├── default.rb
│   │   ├── install_ca_etcd_k8s.rb
│   │   └── install_etcd.rb
│   └── templates
│       ├── etcd_conf.erb
│       └── etcd_service.erb
├── install_haproxy_keepalived
│   ├── files
│   │   ├── haproxy
│   │   └── haproxy_1.7.9-1ubuntu0.1_amd64.deb
│   ├── recipes
│   │   ├── default.rb
│   │   └── install_haproxy.rb
│   └── templates
│       ├── haproxy.erb
│       └── keepalived.erb
├── install_kubernetes_master
│   ├── files
│   │   ├── admin-csr.json
│   │   ├── encryption-config.yaml
│   │   ├── kube-proxy-csr.json
│   │   ├── rbac.authorization.k8s.io.yaml
│   │   └── rbac.authorization.k8s.yaml
│   ├── recipes
│   │   ├── default.rb
│   │   └── install_k8smaster.rb
│   └── templates
│       ├── encryption-config.erb
│       ├── k8sworker-crs.erb
│       ├── kube-apiserver.erb
│       ├── kube-controller-manager.erb
│       └── kube-scheduler.erb
├── install_kubernetes_slave
│   ├── files
│   │   ├── 99-loopback.conf
│   │   └── kube-proxy.service
│   ├── recipes
│   │   ├── default.rb
│   │   └── install_k8sslave.rb
│   └── templates
│       ├── 10-bridge.erb
│       ├── k8sworker-csr.erb
│       └── kubelet_service.erb
└── nodes
    ├── etcd1.json
    ├── etcd2.json
    ├── etcd3.json
    ├── haproxy1.json
    ├── haproxy2.json
    ├── k8smaster1.json
    ├── k8smaster2.json
    ├── k8smaster3.json
    └── k8sslave1.json

$ tree data_bags/
data_bags/
├── haproxy
│   └── haproxy_keepalived.json
└── kubernetes
    └── K8sMaster_configs.json

````
Destroy VirtualBox VM
---------------------
```
$ vagrant destroy -f
```
