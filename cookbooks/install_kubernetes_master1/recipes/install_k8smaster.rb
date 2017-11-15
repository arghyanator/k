#
# Cookbook Name:: install_kubernetes_master1
# Recipe:: install_k8smaster
#
# Arghyanator
#
# This cookbook installs Kubernetes master nodes on Ubuntu 16.04 platform
# We want most steps to run during execute phase of chef-client run so everything is a ruby_block execute

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
    ruby_block "Verify CFSSL and Kubectl" do
        block do
            Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
            %x[/usr/local/bin/cfssl version]
            %x[/usr/local/bin/kubectl version --client]
        end
        action :run
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
    end.run_action(:run)

    ###ONLY RUN ON FIRST MASTER NODE
    ###=============================
    # Create the CA directory on the Host which is shared accross Vbox VMs
    ##Delete any pre-existing CA directory first
    directory '/master/share/CA' do
        recursive true
        action :delete
    end
    ##Now create the CA directory
    %w{CA}.each do |dir|
        directory "/master/share/#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
        end
    end

    #Copy the JSON files required to create CA Certs to CA folder
    cookbook_file '/master/share/CA/ca-config.json' do
        source 'ca-config.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
    end
    cookbook_file '/master/share/CA/ca-csr.json' do
        source 'ca-csr.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
    end

    #Create the CA CERT files 
    ruby_block "Create CA Certs" do
        block do
            %x[cd /master/share/CA; /usr/local/bin/cfssl gencert -initca ca-csr.json | /usr/local/bin/cfssljson -bare ca]
        end
        action :run
    end

    # Create the Admin Certificate / Credentials folder on shared host folder (shared accross all K8s VMs)
    ##Delete any pre-existing admin directory first
    directory '/master/share/admin' do
        recursive true
        action :delete
    end
    ##Now create the admin directory
    %w{admin}.each do |dir|
        directory "/master/share/#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
        end
    end

    #Copy the JSON files required to create Admin Certs to Admin folder
    cookbook_file '/master/share/admin/admin-csr.json' do
        source 'admin-csr.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
    end

    #Create the Admin CERT files
    ruby_block "Create Admin Certs" do
        block do
            %x[cd /master/share/admin; /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -profile=kubernetes-argh admin-csr.json | /usr/local/bin/cfssljson -bare admin]
        end
        action :run
    end

    # Create the Kube-Proxy Certificate folder on shared host folder (shared accross all K8s VMs)
    ##Delete any pre-existing proxy directory first
    directory '/master/share/proxy' do
        recursive true
        action :delete
    end
    ##Now create the proxy directory
    %w{proxy}.each do |dir|
        directory "/master/share/#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
        end
    end
    #Copy the JSON files required to create Kube-Proxy Certs to Proxy folder
    cookbook_file '/master/share/proxy/kube-proxy-csr.json' do
        source 'kube-proxy-csr.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
    end
    #Create the Kube-proxy CERT files
    ruby_block "Create Kube-Proxy Certs" do
        block do
            %x[cd /master/share/proxy; /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -profile=kubernetes-argh kube-proxy-csr.json | /usr/local/bin/cfssljson -bare kube-proxy]
        end
        action :run
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
    etcd1_ip = k8smaster_info["etcd1"]
    etcd2_ip = k8smaster_info["etcd2"]
    etcd3_ip = k8smaster_info["etcd3"]
    ##Delete any pre-existing API directory first
    directory '/master/share/API' do
        recursive true
        action :delete
    end
    ##Now create the API directory
    %w{API}.each do |dir|
        directory "/master/share/#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
        end
    end
    #Copy the JSON files required to create API Certs to API folder
    cookbook_file '/master/share/API/kubernetes-csr.json' do
        source 'kubernetes-csr.json'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
    end
    #Create the API CERT files
    ruby_block "Create API Certs" do
        block do
            %x[cd /master/share/API; /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -hostname=#{k8smaster_nodeid1},#{k8smaster_nodeid2},#{k8smaster_nodeid3},#{k8smaster_nodeid1_ip},#{k8smaster_nodeid2_ip},#{k8smaster_nodeid3_ip},#{k8smaster_vip_ip},127.0.0.1,kubernetes.default -profile=kubernetes-argh kubernetes-csr.json | /usr/local/bin/cfssljson -bare kubernetes]
        end
        action :run
    end
    
    # copy the encryption config yaml 
    cookbook_file '/master/share/CA/encryption-config.yaml' do
        source 'encryption-config.yaml'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
    end

    #Bootstrap Kubernetes master nodes
    ##Install Kubernetes controller binaries
    remote_file "/usr/local/bin/kube-apiserver" do
        source "https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kube-apiserver"
        owner 'root'
        group 'root'
        mode 0755
    end
    remote_file "/usr/local/bin/kube-controller-manager" do
        source "https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kube-controller-manager"
        owner 'root'
        group 'root'
        mode 0755
    end
    remote_file "/usr/local/bin/kube-scheduler" do
        source "https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kube-scheduler"
        owner 'root'
        group 'root'
        mode 0755
    end

    ##Configure API server
    ##Copy the certs to kubernetes daemon folder
    directory '/var/lib/kubernetes' do
        recursive true
        action :create
    end
    ruby_block "Create API Certs" do
        block do
            %x[cp /master/share/CA/ca.pem /var/lib/kubernetes/ca.pem]
            %x[cp /master/share/CA/ca-key.pem /var/lib/kubernetes/ca-key.pem]
            %x[cp /master/share/CA/encryption-config.yaml /var/lib/kubernetes/encryption-config.yaml]
            %x[cp /master/share/API/kubernetes-key.pem /var/lib/kubernetes/kubernetes-key.pem]
            %x[cp /master/share/API/kubernetes.pem /var/lib/kubernetes/kubernetes.pem]
        end
        action :run
    end


    ##Create API server systemd file   
    template '/etc/systemd/system/kube-apiserver.service' do
    source 'kube-apiserver.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables(
            :etcd1_ip => "#{etcd1_ip}",
            :etcd2_ip => "#{etcd2_ip}",
            :etcd3_ip => "#{etcd3_ip}"
    )
    end

    ##Create controller-manager systemd file 
    ##(static file, but still using chef template file for future flexibility)
    template '/etc/systemd/system/kube-controller-manager.service' do
    source 'kube-controller-manager.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables(
    )
    end

    ##Create scheduler systemd file 
    ##(static file, but still using chef template file for future flexibility)
    template '/etc/systemd/system/kube-scheduler.service' do
    source 'kube-scheduler.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables(
    )
    end

    ##Reload Systemd to load the 3 new service
    ruby_block "Reload systemd" do
        block do
            %x[systemctl daemon-reload]
        end
        action :run
    end

    ##Enable and start the 3 new services
    %w{kube-apiserver kube-controller-manager kube-scheduler}.each do |kubeservice|
        service "#{kubeservice}" do
            provider Chef::Provider::Service::Systemd
            action [ :enable, :start ]
            #retries 3
        end
    end
end



