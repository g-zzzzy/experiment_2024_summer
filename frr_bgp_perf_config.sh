#!/bin/bash

#IMAGE="gzy:3"
IMAGE="gzy:4"


sudo docker run --privileged -itd --name bgp_con1 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE
sudo docker run --privileged -itd --name bgp_con2 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE

sudo ip link add veth1 type veth peer name veth2
# #去掉ARP限制
# echo 1 > /proc/sys/net/ipv4/conf/veth1/accept_local 
# echo 1 > /proc/sys/net/ipv4/conf/veth2/accept_local
# echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter 
# echo 0 > /proc/sys/net/ipv4/conf/veth2/rp_filter 
# echo 0 > /proc/sys/net/ipv4/conf/veth1/rp_filter 

pid1=$(sudo docker inspect -f '{{.State.Pid}}' bgp_con1)
pid2=$(sudo docker inspect -f '{{.State.Pid}}' bgp_con2)

sudo ln -s /proc/$pid1/ns/net /var/run/netns/$pid1
sudo ln -s /proc/$pid2/ns/net /var/run/netns/$pid2


sudo ip link set veth1 netns $pid1
sudo ip link set veth2 netns $pid2

sudo ip netns exec $pid1 ip link set veth1 up
sudo ip netns exec $pid1 ip addr add 10.10.1.2/24 dev veth1
sudo ip netns exec $pid2 ip link set veth2 up
sudo ip netns exec $pid2 ip addr add 10.10.1.4/24 dev veth2

sudo docker exec -it bgp_con1 bash -c 'cat > /etc/frr/frr.conf <<EOF
!
frr defaults traditional
hostname bgp_con1
service integrated-vtysh-config
!
router bgp 100
 bgp router-id 10.10.1.2
 network 100.10.1.0/24
 neighbor 10.10.1.4 remote-as 200
 neighbor 10.10.1.4 ebgp-multihop
 address-family ipv4 unicast
 exit-address-family
!
EOF'

sudo docker exec -it bgp_con2 bash -c 'cat > /etc/frr/frr.conf <<EOF
!
frr defaults traditional
hostname bgp_con2
service integrated-vtysh-config
!
router bgp 200
 bgp router-id 10.10.1.4
 network 200.10.1.0/24
 neighbor 10.10.1.2 remote-as 100
 neighbor 10.10.1.2 ebgp-multihop
 address-family ipv4 unicast
 exit-address-family
!
EOF'

sudo docker exec bgp_con1 /usr/lib/frr/frrinit.sh restart
sudo docker exec bgp_con2 /usr/lib/frr/frrinit.sh restart

sudo docker exec bgp_con1 vtysh -c "write"
sudo docker exec bgp_con2 vtysh -c "write"





