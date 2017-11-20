#
# Cookbook Name:: install_install_etcd
# Recipe:: install_etcd_CA_certs
#
# Arghyanator
#
# This cookbook sets up a CA and CA Certs for a 3-node cluster

# We want most steps to run during execute phase of chef-client run so everything is a ruby_block execute

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

#Run CA and CA cert recipe only on 1st ETCD node
#For the nodes that follow - we will just consume these certs
###=============================
case node["hostname"]
when "etcd1"
	##Generate the CA and Certs
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
            %x[cd /master/share/API; /usr/local/bin/cfssl gencert -ca=/master/share/CA/ca.pem -ca-key=/master/share/CA/ca-key.pem -config=/master/share/CA/ca-config.json -hostname=#{k8smaster_nodeid1},#{k8smaster_nodeid2},#{k8smaster_nodeid3},#{k8smaster_nodeid1_ip},#{k8smaster_nodeid2_ip},#{k8smaster_nodeid3_ip},#{k8smaster_vip_ip},#{etcd1_ip},#{etcd2_ip},#{etcd3_ip},127.0.0.1,kubernetes.default -profile=kubernetes-argh kubernetes-csr.json | /usr/local/bin/cfssljson -bare kubernetes]
        end
        action :run
    end

end
