#!/bin/bash

IMAGE="gzy:4"
# -m 30M
sudo docker run --privileged -itd --name bgp_con1 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE
sudo docker run --privileged -itd --name bgp_con2 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE

sudo ip link add veth1 type veth peer name veth2
# #去掉ARP限制
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/conf/veth1/accept_local'
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/conf/veth2/accept_local'
sudo sh -c 'echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter'
sudo sh -c 'echo 0 > /proc/sys/net/ipv4/conf/veth2/rp_filter' 
sudo sh -c 'echo 0 > /proc/sys/net/ipv4/conf/veth1/rp_filter' 

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


sudo docker exec $pid1 sysctl -w net.ipv4.ip_forward=1
sudo docker exec $pid1 sysctl -w net.ipv4.ip_forward=1

sudo docker exec $pid1 bash -c "

  # 配置 IPv4 转发
  echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
"
sudo docker exec $pid2 bash -c "

  # 配置 IPv4 转发
  echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
"


# 在容器内部配置接口并限制带宽
# 在命名空间 pid1 内限制 veth1 接口的带宽
# sudo ip netns exec $pid1 tc qdisc del root dev veth1
# sudo ip netns exec $pid1 tc qdisc add root dev veth1 handle 1: htb default 1
# sudo ip netns exec $pid1 tc class add dev veth1 parent 1: classid 1:1 htb rate 60Mbit ceil 60Mbit prio 0
# sudo ip netns exec $pid1 tc class add dev veth1 parent 1:1 classid 1:2 htb rate 50Mbit ceil 50Mbit prio 1 burst 96kbit
# sudo ip netns exec $pid1 tc class add dev veth1 parent 1:1 classid 1:3 htb rate 40Mbit ceil 50Mbit prio 1 burst 96kbit
# sudo ip netns exec $pid1 tc filter add dev veth1 protocol ip parent 1:0 prio 1 u32 match ip src 10.10.1.2/24 flowid 1:2

# # 在命名空间 pid2 内限制 veth2 接口的带宽
# sudo ip netns exec $pid2 tc qdisc add dev veth2 root handle 1: htb default 10
# sudo ip netns exec $pid2 tc class add dev veth2 parent 1: classid 1:1 htb rate 10gbit
# sudo ip netns exec $pid2 tc class add dev veth2 parent 1:1 classid 1:10 htb rate 10gbit
# sudo ip netns exec $pid2 tc qdisc add dev veth2 parent 1:10 handle 10: netem delay 0ms



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
 no bgp network import-check
 no bgp ebgp-requires-policy
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
 no bgp network import-check
 no bgp ebgp-requires-policy
!
EOF'

sudo docker exec bgp_con1 /usr/lib/frr/frrinit.sh restart
sudo docker exec bgp_con2 /usr/lib/frr/frrinit.sh restart

sudo docker exec bgp_con1 vtysh -c "write"
sudo docker exec bgp_con2 vtysh -c "write"