#
# Cookbook Name:: install_kubernetes_slave
# Recipe:: install_k8sslave
#
# Arghyanator
#
# This cookbook installs Kubernetes slave nodes on Ubuntu 16.04 platform

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

    ##Get POD number for node pod networking
    ### by stripping out the alphabets from hostname and using slave number as podnum
    podnum = "#{node[:hostname]}".tr('k8sslave', '')

    # Create the Node (slave) Certificate / Credentials folder on shared host folder (shared accross all K8s VMs)
    ##Delete any pre-existing node directory first
    directory "/master/share/#{node[:hostname]}" do
        recursive true
        action :delete
    end
    ##Now create the node directory
    directory "/master/share/#{node[:hostname]}" do
        mode '0755'
        owner 'root'
        group 'root'
        action :create
        recursive true
    end

    #Copy the JSON files required to create Admin Certs to Admin folder
    template "/master/share/#{node[:hostname]}/#{node[:hostname]}-csr.json" do
    source 'k8sworker-csr.erb'
    owner 'root'
    group 'root'
    mode '0644'
    end

    #Create the Node CERT files
    ruby_block "Create Node Certs" do
        block do
            %x[cd /master/share/#{node[:hostname]}; /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -hostname=#{node[:hostname]},#{node[:ip]} -profile=kubernetes-argh /master/share/#{node[:hostname]}/#{node[:hostname]}-csr.json | /usr/local/bin/cfssljson -bare #{node[:hostname]}]
        end
        action :run
    end

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

    ##Create the kubeconfig files for kubelet for each slave node
    ruby_block "Create kubeconfig files for Kubelet" do
        block do
            %x[cd /master/share/#{node[:hostname]}; /usr/local/bin/kubectl config set-cluster kubernetes-argh --certificate-authority=/master/share/CA/ca.pem --embed-certs=true --server=https://#{k8smaster_vip_ip}:6443 --kubeconfig=/master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig]
            %x[cd /master/share/#{node[:hostname]}; /usr/local/bin/kubectl config set-credentials system:node:#{node[:hostname]} --client-certificate=/master/share/#{node[:hostname]}/#{node[:hostname]}.pem --client-key=/master/share/#{node[:hostname]}/#{node[:hostname]}-key.pem --embed-certs=true --kubeconfig=/master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig]
            %x[cd /master/share/#{node[:hostname]}; /usr/local/bin/kubectl config set-context default --cluster=kubernetes-argh --user=system:node:#{node[:hostname]} --kubeconfig=/master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig]
            %x[cd /master/share/#{node[:hostname]}; /usr/local/bin/kubectl config use-context default --kubeconfig=/master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig]
        end
        action :run
    end

    ##Install Worker software
    package %w(socat)  do
        action :nothing
    end

    ##Make the required folders
    ###First Delete if old data or folder exists
    %w{/etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes}.each do |dir|
        directory "#{dir}" do
            recursive true
            action :delete
        end
    end
    ##Then create the directories
    %w{/etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes}.each do |dir|
        directory "#{dir}" do
            mode '0755'
            owner 'root'
            group 'root'
            action :create
            recursive true
        end
    end

    ##Download the software
    remote_file '/tmp/cni-plugins-amd64-v0.6.0.tgz' do
        source 'https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
    end

    remote_file '/tmp/cri-containerd-1.0.0-alpha.0.tar.gz' do
        source 'https://github.com/kubernetes-incubator/cri-containerd/releases/download/v1.0.0-alpha.0/cri-containerd-1.0.0-alpha.0.tar.gz'
        owner 'root'
        group 'root'
        mode '0644'
        action :create
    end

    ruby_block "extract CNI plugins" do
        block do
            %x[tar -xvf /tmp/cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/]
            %x[tar -xvf /tmp/cri-containerd-1.0.0-alpha.0.tar.gz -C /]
        end
        action :run
    end

    %w(kube-proxy kubelet).each do |remfile|
        remote_file "/usr/local/bin/#{remfile}" do
            source "https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/#{remfile}"
            owner 'root'
            group 'root'
            mode '0755'
            action :create
        end
    end

    ##Create the worker internal networking bridge   
    template '/etc/cni/net.d/10-bridge.conf' do
    source '10-bridge.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables(
            :podnum => "#{podnum}"
    )
    end

    cookbook_file "/etc/cni/net.d/99-loopback.conf" do
        source "99-loopback.conf"
        mode '0644'
    end

    ##Copy the worker SSL cert and key to kublet folder
    ruby_block "copy kubelet, slave worker keys and kubeconfig files" do
        block do
            %x[cp /master/share/#{node[:hostname]}/#{node[:hostname]}-key.pem /var/lib/kubelet/#{node[:hostname]}-key.pem]
            %x[cp /master/share/#{node[:hostname]}/#{node[:hostname]}.pem /var/lib/kubelet/#{node[:hostname]}.pem]
            %x[cp /master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig /var/lib/kubelet/#{node[:hostname]}.kubeconfig]
        end
        action :run
    end
    
    ##Copy the CA cert to kubernetes folder
    file '/var/lib/kubernetes/ca.pem' do
        content IO.read('/master/share/CA/ca.pem')
        action :create
    end

    ##Create the kubelet systemctl service file   
    template '/etc/systemd/system/kubelet.service' do
    source 'kubelet_service.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables(
            :podnum => "#{podnum}"
    )
    end

    ##Copy the kube-proxy kubeconfig file 
    file '/var/lib/kube-proxy/kube-proxy.kubeconfig' do
        content IO.read('/master/share/proxy/kube-proxy.kubeconfig')
        action :create
    end
    ##Create the kube-proxy systemctl service file
    cookbook_file "/etc/systemd/system/kube-proxy.service" do
        source "kube-proxy.service"
        mode '0644'
    end

    ##Reload Systemd to load the 2 new services
    ruby_block "Reload systemd" do
        block do
            %x[systemctl daemon-reload]
        end
        action :run
    end

    ##Enable and start the new services
    %w{containerd cri-containerd kubelet kube-proxy}.each do |kubeservice|
        service "#{kubeservice}" do
            provider Chef::Provider::Service::Systemd
            action [ :enable, :start ]
            #retries 3
        end
    end

end

