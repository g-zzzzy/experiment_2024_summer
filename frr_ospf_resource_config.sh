#!/bin/bash

IMAGE="gzy:3"

# sudo docker stop ospf_resource1
# sudo docker stop ospf_resource2
# sudo docker stop ospf_resource3
# sudo docker rm ospf_resource1
# sudo docker rm ospf_resource2
# sudo docker rm ospf_resource3

sudo docker run -itd --name ospf_resource1 --mount type=bind,source="$(pwd)",target=/src --privileged --network none $IMAGE
sudo docker run -itd --name ospf_resource2 --mount type=bind,source="$(pwd)",target=/src --privileged --network none $IMAGE
sudo docker run -itd --name ospf_resource3 --mount type=bind,source="$(pwd)",target=/src --privileged --network none $IMAGE
sudo docker exec -it ospf_resource1 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"
sudo docker exec -it ospf_resource2 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"
sudo docker exec -it ospf_resource3 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"


#test unconnected
#echo "test unconnected:"
#sudo docker exec ospf_perf1 ping -c 2 192.168.1.3 || echo "Initial outcome"


#创建veth对
sudo ip link add veth11 type veth peer name veth12
sudo ip link add veth13 type veth peer name veth14

#获取pid
pid1=$(sudo docker inspect -f '{{.State.Pid}}' ospf_resource1)
pid2=$(sudo docker inspect -f '{{.State.Pid}}' ospf_resource2)
pid3=$(sudo docker inspect -f '{{.State.Pid}}' ospf_resource3)

sudo ln -s /proc/$pid1/ns/net /var/run/netns/$pid1
sudo ln -s /proc/$pid2/ns/net /var/run/netns/$pid2
sudo ln -s /proc/$pid3/ns/net /var/run/netns/$pid3


#veth连接到容器
sudo ip link set veth11 netns $pid1
sudo ip link set veth12 netns $pid2
sudo ip link set veth13 netns $pid2
sudo ip link set veth14 netns $pid3


echo "veth"
#容器中开启veth
sudo ip netns exec $pid1 ip link set veth11 up
sudo ip netns exec $pid1 ip addr add 192.168.11.2/24 dev veth11
sudo ip netns exec $pid2 ip link set veth12 up
sudo ip netns exec $pid2 ip addr add 192.168.11.3/24 dev veth12
sudo ip netns exec $pid2 ip link set veth13 up
sudo ip netns exec $pid2 ip addr add 192.168.12.4/24 dev veth13
sudo ip netns exec $pid3 ip link set veth14 up
sudo ip netns exec $pid3 ip addr add 192.168.12.5/24 dev veth14


#配置OSPF
echo "config:"
sudo docker exec -it ospf_resource1 bash -c "

  # 配置 IPv4 转发
  echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
"
sudo docker exec -it ospf_resource2 bash -c "

  # 配置 IPv4 转发
  echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
"

sudo docker exec -it ospf_resource3 bash -c "

  # 配置 IPv4 转发
  echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
"

sudo docker exec ospf_resource1 bash -c 'cat > /etc/frr/frr.conf <<EOF
!
frr defaults traditional
hostname ospf_resource1
service integrated-vtysh-config
log file /var/log/frr/frr.log
!
interface veth11
 ip ospf area 0
!
router ospf
 ospf router-id 1.1.1.12
 network 192.168.11.0/24 area 0
 network 192.168.12.0/24 area 0
!
EOF'

sudo docker exec ospf_resource2 bash -c 'cat > /etc/frr/frr.conf <<EOF
!
frr defaults traditional
hostname ospf_resource2
service integrated-vtysh-config
log file /var/log/frr/frr.log
!
interface veth12
 ip ospf area 0
!
interface veth13
 ip ospf area 0
!
router ospf
 ospf router-id 1.1.1.13
 network 192.168.11.0/24 area 0
 network 192.168.12.0/24 area 0
!
EOF'

sudo docker exec ospf_resource3 bash -c 'cat > /etc/frr/frr.conf <<EOF
!
frr defaults traditional
hostname ospf_resource3
service integrated-vtysh-config
log file /var/log/frr/frr.log
!
interface veth14
 ip ospf area 0
!
router ospf
 ospf router-id 1.1.1.14
 network 192.168.11.0/24 area 0
 network 192.168.12.0/24 area 0
!
EOF'

#sudo docker exec ospf_perf2 bash -c 'cat > /etc/frr/frr.conf <<EOF
#!
#hostname ospf_perf2
#log file /var/log/frr/frr.log
#router ospf
# ospf router-id 1.1.1.2
# network 192.168.1.0/24 area 0
#!
#EOF'


echo "start:"
sudo docker exec ospf_resource1 /usr/lib/frr/frrinit.sh restart
sudo docker exec ospf_resource2 /usr/lib/frr/frrinit.sh restart
sudo docker exec ospf_resource3 /usr/lib/frr/frrinit.sh restart

echo "write:"
sudo docker exec ospf_resource1 vtysh -c "write"
sudo docker exec ospf_resource2 vtysh -c "write"
sudo docker exec ospf_resource3 vtysh -c "write"


#zebra和ospf是否运行
# echo "check 进程:"
# echo "container1:"
# sudo docker exec ospf_resource1 ps aux | grep ospfd
# echo "container2:"
# sudo docker exec ospf_resource2 ps aux | grep ospfd


#验证OSPF
echo "验证OSPF:"
echo "container1:"
sudo docker exec ospf_resource1 vtysh -c "show ip ospf neighbor"
sudo docker exec ospf_resource1 vtysh -c "show ip route"

echo "container2:"
sudo docker exec ospf_resource2 vtysh -c "show ip ospf neighbor"
sudo docker exec ospf_resource2 vtysh -c "show ip route"

echo "container3:"
sudo docker exec ospf_resource3 vtysh -c "show ip ospf neighbor"
sudo docker exec ospf_resource3 vtysh -c "show ip route"

#test connected
#echo "test2:"
#sudo docker exec ospf_perf1 ping -c 2 192.168.1.3 && echo "connectd"

#sudo rm /var/run/netns/$pid1
#sudo rm /var/run/netns/$pid2

#sudo docker stop ospf_perf1
#sudo docker stop ospf_perf2
#sudo docker rm ospf_perf1
#sudo docker rm ospf_perf2


