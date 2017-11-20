#!/bin/bash
while [ "$(etcdctl cluster-health |tail -1)" != "cluster is healthy" ]
do
echo "cluster not healthy yet...sleeping 5 seconds and trying again"
sleep 5
done
echo "cluster setup done...change cluster to existing"
sed -i 's/--initial-cluster-state new/--initial-cluster-state existing/g' /etc/systemd/system/etcd.service
/bin/systemctl restart etcd.service