#
# Cookbook Name:: install_etcd
# Recipe:: default
#
# Arghyanator
#
# 

# Call the install ETCD recipes here
include_recipe "install_etcd::install_ca_etcd_k8s"
include_recipe "install_etcd::install_etcd"