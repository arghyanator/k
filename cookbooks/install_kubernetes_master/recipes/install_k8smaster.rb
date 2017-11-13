#
# Cookbook Name:: install_kubernetes_master
# Recipe:: install_k8smaster
#
# Arghyanator
#
# This cookbook installs Kubernetes master nodes on Ubuntu 16.04 platform

case node["platform"]
when "ubuntu"
   # Update apt repos
    apt_update 'Update the apt cache daily' do
        frequency 86_400
        action :periodic
    end
	# Install CloudFlare SSL packages CFSSL and CFSSLJSON
    remote_file '/usr/local/bin/cfssl' do
        source 'https://pkg.cfssl.org/R1.2/cfssl_linux-amd64'
        owner 'root'
        group 'root'
        mode '0755'
        action :create
    end
    remote_file '/usr/local/bin/cfssljson' do
        source 'https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64'
        owner 'root'
        group 'root'
        mode '0755'
        action :create
    end

    # Install Kubectl utility
    remote_file '/usr/local/bin/kubectl' do
        source 'https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kubectl'
        owner 'root'
        group 'root'
        mode '0755'
        action :create
    end

    # Verify CFSSL and Kubectl commands
    bash 'Verify CFSSL and Kubectl' do 
        user 'root'
        cwd  '/tmp'
        code <<-EOH
          /usr/local/bin/cfssl version
          /usr/local/bin/kubectl version --client
        EOH
        flags "-x"
    end

    # Set Node Hostname and IP address variables using ruby block
    ruby_block "sethostandip" do
        block do
            Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
            command = 'hostname'
            command_out = shell_out(command)
            node.set['hostname'] = command_out.stdout
            command2 = 'hostname -I |awk \'{printf"%s", $2}\''
            command2_out = shell_out(command2)
            node.set['ip'] = command2_out.stdout
        end
        action :create
    end

    ###ONLY RUN ON FIRST MASTER NODE
    ###=============================
    # Create the CA directory on the Host which is shared accross Vbox VMs
    ##Delete any pre-existing CA directory first
    directory '/master/share/CA' do
        recursive true
        action :delete
        only_if {node.hostname == 'k8smaster1'}
    end
    ##Now create the CA directory
    %w{CA}.each do |dir|
        directory "/master/share/#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
            only_if {node.hostname == 'k8smaster1'}
        end
    end

    #Copy the JSON files required to create CA Certs to CA folder
    cookbook_file '/master/share/CA/ca-config.json' do
        source 'ca-config.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
        only_if {node.hostname == 'k8smaster1'}
    end
    cookbook_file '/master/share/CA/ca-csr.json' do
        source 'ca-csr.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
        only_if {node.hostname == 'k8smaster1'}
    end

    #Create the CA CERT files and Data Encryption key
    bash 'Create CA Certs' do 
        user 'root'
        cwd  '/master/share/CA'
        code <<-EOH
          /usr/local/bin/cfssl gencert -initca ca-csr.json | /usr/local/bin/cfssljson -bare ca
          head -c 32 /dev/urandom | base64 >/usr/share/CA/key
        EOH
        flags "-x"
        only_if {node.hostname == 'k8smaster1'}
    end

    # Create the Admin Certificate / Credentials folder on shared host folder (shared accross all K8s VMs)
    ##Delete any pre-existing admin directory first
    directory '/master/share/admin' do
        recursive true
        action :delete
        only_if {node.hostname == 'k8smaster1'}
    end
    ##Now create the admin directory
    %w{admin}.each do |dir|
        directory "/master/share/#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
            only_if {node.hostname == 'k8smaster1'}
        end
    end

    #Copy the JSON files required to create Admin Certs to Admin folder
    cookbook_file '/master/share/admin/admin-csr.json' do
        source 'admin-csr.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
        only_if {node.hostname == 'k8smaster1'}
    end

    #Create the Admin CERT files
    bash 'Create Admin user Certs' do 
        user 'root'
        cwd  '/master/share/admin'
        code <<-EOH
          /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -profile=kubernetes-argh admin-csr.json | /usr/local/bin/cfssljson -bare admin
        EOH
        flags "-x"
        only_if {node.hostname == 'k8smaster1'}
    end

    # Create the Kube-Proxy Certificate folder on shared host folder (shared accross all K8s VMs)
    ##Delete any pre-existing proxy directory first
    directory '/master/share/proxy' do
        recursive true
        action :delete
        only_if {node.hostname == 'k8smaster1'}
    end
    ##Now create the proxy directory
    %w{proxy}.each do |dir|
        directory "/master/share/#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
            only_if {node.hostname == 'k8smaster1'}
        end
    end
    #Copy the JSON files required to create Kube-Proxy Certs to Proxy folder
    cookbook_file '/master/share/proxy/kube-proxy-csr.json' do
        source 'kube-proxy-csr.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
        only_if {node.hostname == 'k8smaster1'}
    end
    #Create the Kube-proxy CERT files
    bash 'Create Proxy Certs' do 
        user 'root'
        cwd  '/master/share/proxy'
        code <<-EOH
          /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -profile=kubernetes-argh kube-proxy-csr.json | /usr/local/bin/cfssljson -bare kube-proxy
        EOH
        flags "-x"
        only_if {node.hostname == 'k8smaster1'}
    end

    #Set up Kubernetes API Certs
    ##Get Kubernetes API VIP information from Chef data bag
    ##Get kubernetes Master nodes info from Chef Data bag
    k8smaster_info = Chef::DataBagItem.load("kubernetes", "K8sMaster_configs")
    k8smaster_nodeid1 = k8smaster_info["nodeid1"]
    k8smaster_nodeid2 = k8smaster_info["nodeid2"]
    k8smaster_nodeid3 = k8smaster_info["nodeid3"]
    k8smaster_nodeid1_ip = k8smaster_info["nodeid1_ip"]
    k8smaster_nodeid2_ip = k8smaster_info["nodeid2_ip"]
    k8smaster_nodeid3_ip = k8smaster_info["nodeid3_ip"]
    k8smaster_vip_ip = k8smaster_info["vip_ip"]
    ##Delete any pre-existing API directory first
    directory '/master/share/API' do
        recursive true
        action :delete
        only_if {node.hostname == 'k8smaster1'}
    end
    ##Now create the API directory
    %w{API}.each do |dir|
        directory "/master/share/#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
            only_if {node.hostname == 'k8smaster1'}
        end
    end
    #Copy the JSON files required to create API Certs to API folder
    cookbook_file '/master/share/API/kubernetes-csr.json' do
        source 'kubernetes-csr.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
        only_if {node.hostname == 'k8smaster1'}
    end
    #Create the API CERT files
    bash 'Create API Certs' do 
        user 'root'
        cwd  '/master/share/API'
        code <<-EOH
          /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -hostname=#{k8smaster_nodeid1},#{k8smaster_nodeid2},#{k8smaster_nodeid3},#{k8smaster_nodeid1_ip},#{k8smaster_nodeid2_ip},#{k8smaster_nodeid3_ip},#{k8smaster_vip_ip},127.0.0.1,kubernetes.default -profile=kubernetes-argh kubernetes-csr.json | /usr/local/bin/cfssljson -bare kubernetes
        EOH
        flags "-x"
        only_if {node.hostname == 'k8smaster1'}
    end

    #Read Data envryption key created earlier on Master1
    execute 'read_encryption_key' do
        command lazy {
          encryption_key = IO.read('/master/share/CA/key').strip
        }
        sensitive true
    end
    # create the encryption config yaml    
    template '/master/share/CA/encryption-config.yaml' do
    source 'encryption-config.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables(
            :encryption_key => "#{encryption_key}"
    )
    only_if {node.hostname == 'k8smaster1'}
    end

end



