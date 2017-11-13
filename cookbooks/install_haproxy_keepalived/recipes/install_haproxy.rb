#
# Cookbook Name:: install_haproxy_keepalived
# Recipe:: install_haproxy
#
# Arghyanator
#
# This cookbook installs HAProxy, KeepAlived and common packages for Ubuntu 16.04 platform

case node["platform"]
when "ubuntu"
   # Update APT repos
    apt_update 'Update the apt cache daily' do
        frequency 86_400
        action :periodic
    end
	# Install HAProxy binaries - version 1.7.9 compiled from source
    # Install liblua required for Haproxy first
    package "liblua5.3-0" do 
            options "-q -y"
            action :install
    end
    cookbook_file "/tmp/haproxy_1.7.9-1ubuntu0.1_amd64.deb" do
	   	source "haproxy_1.7.9-1ubuntu0.1_amd64.deb"
	   	mode '0644'
	end
    #Create the haproxy user/group
    group 'haproxy' do
        action :create
    end
    user 'haproxy' do 
        action :create 
        shell '/bin/false'
        gid 'haproxy' 
        comment 'This account is for running haproxy' 
        system true 
        manage_home false 
    end

    #Create the haproxy socket folder
    directory '/run/haproxy' do
        owner 'haproxy'
        group 'haproxy'
        mode '0755'
        action :create
    end

    #Install haproxy from deb package
    dpkg_package "haproxy" do 
        source "/tmp/haproxy_1.7.9-1ubuntu0.1_amd64.deb"
        action :install
    end 


    # Install Keepalived packages
    package "keepalived" do 
            options "-q -y"
            action :install
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
	
    ruby_block "adding HAProxy hostname to /etc/hosts" do
            block do
                    fe1 = Chef::Util::FileEdit.new("/etc/hosts")
                    fe1.insert_line_if_no_match(/^#{node['ip']} #{node['hostname']}/,
                           "#{node['ip']} #{node['hostname']}")
                    fe1.write_file
            end
    end

	# Kernel Tuning for HAProxy - network parameters
	ruby_block "adding HAPRoxy kernel tuning sysctl" do
  		block do
    			fe2 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe2.insert_line_if_no_match(/# for HAProxy/,
                               "# for HAProxy")
    			fe2.write_file
    			fe3 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe3.insert_line_if_no_match(/^net\.ipv4\.ip_nonlocal_bind = 1/,
                               "net.ipv4.ip_nonlocal_bind = 1")
    			fe3.write_file
    			fe4 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe4.insert_line_if_no_match(/# Increase local port binding numbers/,
                               "# Increase local port binding numbers")
    			fe4.write_file
    			fe5 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe5.insert_line_if_no_match(/net\.ipv4\.ip_local_port_range = 10000 65024/,
                               "net.ipv4.ip_local_port_range = 10000 65024")
    			fe5.write_file
    			fe6 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe6.insert_line_if_no_match(/# Defend againsts SYN FLOOD attacks/,
                               "# Defend againsts SYN FLOOD attacks")
    			fe6.write_file
    			fe7 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe7.insert_line_if_no_match(/net\.ipv4\.tcp_max_syn_backlog = 60000/,
                               "net.ipv4.tcp_max_syn_backlog = 60000")
    			fe7.write_file
    			fe8 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe8.insert_line_if_no_match(/# Quickly reuse TCP sockets \(instead of waiting in TIME_WAIT after disconnect\)/,
                               "# Quickly reuse TCP sockets (instead of waiting in TIME_WAIT after disconnect)")
    			fe8.write_file
    			fe9 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe9.insert_line_if_no_match(/net\.ipv4\.tcp_tw_reuse = 1/,
                               "net.ipv4.tcp_tw_reuse = 1")
    			fe9.write_file
    			fe10 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe10.insert_line_if_no_match(/# Increase number of Socket max connections/,
                               "# Increase number of Socket max connections")
    			fe10.write_file
    			fe11 = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    			fe11.insert_line_if_no_match(/net\.core\.somaxconn = 1024/,
                               "net.core.somaxconn = 1024")
    			fe11.write_file
  		end
		notifies :run, "execute[sysctl -p]", :immediately
	end
	

	# Load sysctl parameters on Ubuntu	
	execute "sysctl -p" do
		command "sysctl -p"
		action :nothing
	end	

    #Create HAProxy Config files for K8sMaster API endpoint
    ##Get kubernetes Master nodes info from Chef Data bag
    k8smaster_info = Chef::DataBagItem.load("kubernetes", "K8sMaster_configs")
    k8smaster_nodeid1 = k8smaster_info["nodeid1"]
    k8smaster_nodeid2 = k8smaster_info["nodeid2"]
    k8smaster_nodeid3 = k8smaster_info["nodeid3"]
    k8smaster_nodeid1_ip = k8smaster_info["nodeid1_ip"]
    k8smaster_nodeid2_ip = k8smaster_info["nodeid2_ip"]
    k8smaster_nodeid3_ip = k8smaster_info["nodeid3_ip"]
    k8smaster_vip_ip = k8smaster_info["vip_ip"]
    ##Set the Haproxy configurations using chef template file
    ##Copy /etc/haproxy/haproxy.cfg - Haproxy configuration template file    
    template '/etc/haproxy/haproxy.cfg' do
    source 'haproxy.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables(
            :k8smaster_vip_ip => "#{k8smaster_vip_ip}",
            :k8smaster_nodeid1 => "#{k8smaster_nodeid1}",
            :k8smaster_nodeid2 => "#{k8smaster_nodeid2}",
            :k8smaster_nodeid3 => "#{k8smaster_nodeid3}",
            :k8smaster_nodeid1_ip => "#{k8smaster_nodeid1_ip}",
            :k8smaster_nodeid2_ip => "#{k8smaster_nodeid2_ip}",
            :k8smaster_nodeid3_ip => "#{k8smaster_nodeid3_ip}"
    )
    notifies :restart, 'service[haproxy]', :immediately
    end
    #Start Haproxy service
    service "haproxy" do
        action :nothing
    end


	# Configure KeepAlived
	# Get information from Data Bag
    node_info = Chef::DataBagItem.load("haproxy", "haproxy_keepalived")
    keepalived_nodeid1 = node_info["nodeid1"]
    keepalived_nodeid2 = node_info["nodeid2"]
    keepalived_nodeid1_ip = node_info["nodeid1_ip"]
    keepalived_nodeid2_ip = node_info["nodeid2_ip"]
    keepalived_vip_ip = node_info["vip_ip"]
    keepalived_interface = node_info["interface"]
    if node[:hostname] == "#{keepalived_nodeid1}"
        keepalived_node_priority = "101"
        nodeid_ip = "#{keepalived_nodeid1_ip}"
        peer_nodeid_ip = "#{keepalived_nodeid2_ip}"
    else
        keepalived_node_priority = "100"
        nodeid_ip = "#{keepalived_nodeid2_ip}"
        peer_nodeid_ip = "#{keepalived_nodeid1_ip}"
    end

    # Copy /etc/keepalived/keepalived.conf - KeepAlived configuration template file    
    template '/etc/keepalived/keepalived.conf' do
    source 'keepalived.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables(
            :keepalived_vip_ip => "#{keepalived_vip_ip}",
            :keepalived_interface => "#{keepalived_interface}",
            :keepalived_node_priority => "#{keepalived_node_priority}",
            :nodeid_ip => "#{nodeid_ip}",
            :peer_nodeid_ip => "#{peer_nodeid_ip}"
    )
    notifies :restart, 'service[keepalived]', :immediately
    end

    service "keepalived" do
        action :nothing
    end

end

