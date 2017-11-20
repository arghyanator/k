#
# Cookbook Name:: install_install_etcd
# Recipe:: install_etcd
#
# Arghyanator
#
# This cookbook installs etcd on a 3-node cluster

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


# Run apt-get update on a schedule - once every 24 hours
apt_update 'Update the apt cache daily' do
  frequency 86_400
  action :periodic
end

# Install etcd packages
remote_file "/tmp/etcd-v3.2.8-linux-amd64.tar.gz" do
  source "https://github.com/coreos/etcd/releases/download/v3.2.8/etcd-v3.2.8-linux-amd64.tar.gz"
  owner 'root'
  group 'root'
  mode 0644
end
ruby_block "copy etcd executables to usr-local-bin" do
  block do
    %x[cd /tmp; tar xvzf /tmp/etcd-v3.2.8-linux-amd64.tar.gz]
    %x[mv /tmp/etcd-v3.2.8-linux-amd64/etcd* /usr/local/bin]
    %x[chmod 755 /usr/local/bin/etcd*]
  end
  action :run
end

#Create etcd group
group "etcd"
user 'etcd' do 
  action :create 
  shell '/sbin/nologin'
  gid 'etcd'
  comment 'etcd account'
  system true 
  manage_home false 
end

# delete the default created config file
file '/etc/default/etcd' do
	action :delete
end

#Delete the default database files
directory '/var/lib/etcd' do
  recursive true
  action :delete
end

#Recreate the /var/lib/etcd directory
directory '/var/lib/etcd' do
  owner 'etcd'
  group 'etcd'
  mode '0777'
  action :create
end

#Recreate the /var/lib/etcd/default directory
directory '/var/lib/etcd/default' do
  owner 'etcd'
  group 'etcd'
  mode '0755'
  action :create
end

# Generate UUID for etcd cluster ID
# cluster_uuid = UUIDTools::UUID.random_create.to_s 

#Delete and recreate the /etc/etcd folder
directory '/etc/etcd' do
  recursive true
  action :delete
end

#Recreate the /etc/etcd directory
directory '/etc/etcd' do
  owner 'etcd'
  group 'etcd'
  mode '0777'
  action :create
end
ruby_block "Copy Kube API and CA Certs into etc-slash-etcd" do
  block do
      %x[cp /master/share/CA/ca.pem /etc/etcd/ca.pem]
      %x[cp /master/share/CA/ca-key.pem /etc/etcd/ca-key.pem]
      %x[cp /master/share/API/kubernetes-key.pem /etc/etcd/kubernetes-key.pem]
      %x[cp /master/share/API/kubernetes.pem /etc/etcd/kubernetes.pem]
  end
  action :run
end

##Create the systemctl startup file for ETCD daemon
template '/etc/systemd/system/etcd.service' do
	source 'etcd_service.erb'
	variables(
		lazy { 
			{
				:etcdhostname => node['hostname'],
				:etcdipaddress => node['ip']
			}
		}
	)
	owner 'root'
	group 'root'
	mode '0644'
	action :create
end

ruby_block "Reload systemd" do
        block do
            %x[systemctl daemon-reload]
        end
        action :run
end

#
service 'etcd' do
  action [ :enable, :start ]
end

cookbook_file '/tmp/check_etcd.sh' do
	source 'check_etcd.sh'
	owner 'root'
	group 'root'
	mode '0755'
	action :create
end

#Run script to check etcd status and change startup file for etcd after inital config
bash 'run_check_etcd' do
  cwd '/tmp'
  user 'root'
  group 'root'
  code <<-EOH
    /usr/bin/at now +5 minutes -f /tmp/check_etcd.sh
  EOH
end