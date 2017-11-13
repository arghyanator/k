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
    bash 'Create Node Certs' do 
        user 'root'
        cwd  "/master/share/#{node[:hostname]}"
        code <<-EOH
          /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -hostname=#{node[:hostname]},#{node[:ip]} -profile=kubernetes-argh /master/share/#{node[:hostname]}/#{node[:hostname]}-csr.json | /usr/local/bin/cfssljson -bare #{node[:hostname]}
        EOH
        flags "-x"
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
    bash 'Create kubeconfig files for Kubelet' do 
        user 'root'
        cwd  "/master/share/#{node[:hostname]}"
        code <<-EOH
          /usr/local/bin/kubectl config set-cluster kubernetes-argh --certificate-authority=/master/share/CA/ca.pem --embed-certs=true --server=https://#{k8smaster_vip_ip}:6443 --kubeconfig=/master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig
          /usr/local/bin/kubectl config set-credentials system:node:#{node[:hostname]} --client-certificate=/master/share/#{node[:hostname]}/#{node[:hostname]}.pem --client-key=/master/share/#{node[:hostname]}/#{node[:hostname]}-key.pem --embed-certs=true --kubeconfig=/master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig
          /usr/local/bin/kubectl config set-context default --cluster=kubernetes-argh --user=system:node:#{node[:hostname]} --kubeconfig=/master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig
          /usr/local/bin/kubectl config use-context default --kubeconfig=/master/share/#{node[:hostname]}/#{node[:hostname]}.kubeconfig
        EOH
        flags "-x"
    end

    ##Create the kube-proxy config files (doesnt have to be for each node)
    bash 'Create config files for kube-proxy' do 
        user 'root'
        cwd  "/master/share/#{node[:hostname]}"
        code <<-EOH
          /usr/local/bin/kubectl config set-cluster kubernetes-argh --certificate-authority=/master/share/CA/ca.pem --embed-certs=true --server=https://#{k8smaster_vip_ip}:6443 --kubeconfig=/master/share/#{node[:hostname]}/kube-proxy.kubeconfig
          /usr/local/bin/kubectl config set-credentials kube-proxy --client-certificate=/master/share/proxy/kube-proxy.pem --client-key=/master/share/proxy/kube-proxy-key.pem --embed-certs=true --kubeconfig=/master/share/#{node[:hostname]}/kube-proxy.kubeconfig
          /usr/local/bin/kubectl config set-context default --cluster=kubernetes-argh --user=kube-proxy --kubeconfig=/master/share/#{node[:hostname]}/kube-proxy.kubeconfig
          /usr/local/bin/kubectl config use-context default --kubeconfig=/master/share/#{node[:hostname]}/kube-proxy.kubeconfig
        EOH
        flags "-x"
    end
end

