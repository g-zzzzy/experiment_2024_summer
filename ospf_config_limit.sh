#!/bin/bash

IMAGE="gzy:4"

# sudo docker stop ospf_perf1
# sudo docker stop ospf_perf2
# sudo docker stop ospf_perf3
# sudo docker rm ospf_perf1
# sudo docker rm ospf_perf2
# sudo docker rm ospf_perf3

sudo docker run --privileged -itd \
  --name ospf_1 \
  --label "org.label-schema.tc.enabled=1" \
  --label "org.label-schema.tc.rate=30gbps" \
  --label "org.label-schema.tc.ceil=30gbps" \
  --mount type=bind,source="$(pwd)",target=/src \
  --network none \
  $IMAGE

sudo docker run --privileged -itd \
  --name ospf_2 \
  --label "org.label-schema.tc.enabled=1" \
  --label "org.label-schema.tc.rate=30gbps" \
  --label "org.label-schema.tc.ceil=30gbps" \
  --mount type=bind,source="$(pwd)",target=/src \
  --network none \
  $IMAGE

sudo docker run --privileged -itd \
  --name ospf_3 \
  --label "org.label-schema.tc.enabled=1" \
  --label "org.label-schema.tc.rate=30gbps" \
  --label "org.label-schema.tc.ceil=30gbps" \
  --mount type=bind,source="$(pwd)",target=/src \
  --network none \
  $IMAGE  

# sudo docker run --privileged -itd --name ospf_1 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE
# sudo docker run --privileged -itd --name ospf_2 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE
# sudo docker run --privileged -itd --name ospf_3 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE
sudo docker exec -it ospf_1 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"
sudo docker exec -it ospf_2 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"
sudo docker exec -it ospf_3 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"


#test unconnected
#echo "test unconnected:"
#sudo docker exec ospf_perf1 ping -c 2 192.168.1.3 || echo "Initial outcome"


#创建veth对
sudo ip link add veth1 type veth peer name veth2
sudo ip link add veth3 type veth peer name veth4

#获取pid
pid1=$(sudo docker inspect -f '{{.State.Pid}}' ospf_1)
pid2=$(sudo docker inspect -f '{{.State.Pid}}' ospf_2)
pid3=$(sudo docker inspect -f '{{.State.Pid}}' ospf_3)

sudo ln -s /proc/$pid1/ns/net /var/run/netns/$pid1
sudo ln -s /proc/$pid2/ns/net /var/run/netns/$pid2
sudo ln -s /proc/$pid3/ns/net /var/run/netns/$pid3


#veth连接到容器
sudo ip link set veth1 netns $pid1
sudo ip link set veth2 netns $pid2
sudo ip link set veth3 netns $pid2
sudo ip link set veth4 netns $pid3


echo "veth"
#容器中开启veth
sudo ip netns exec $pid1 ip link set veth1 up
sudo ip netns exec $pid1 ip addr add 192.168.1.2/24 dev veth1
sudo ip netns exec $pid2 ip link set veth2 up
sudo ip netns exec $pid2 ip addr add 192.168.1.3/24 dev veth2
sudo ip netns exec $pid2 ip link set veth3 up
sudo ip netns exec $pid2 ip addr add 192.168.2.4/24 dev veth3
sudo ip netns exec $pid3 ip link set veth4 up
sudo ip netns exec $pid3 ip addr add 192.168.2.5/24 dev veth4


#配置OSPF
echo "config:"
#sudo docker exec ospf_perf1 bash -c "echo 'hostname ospf_perf1\nlog stdout\nrouter ospf\nospf router-id 1.1.1.1\n network 192.168.1.0/24 area 0\n!'> /etc/frr/ospfd.conf"

#sudo docker exec ospf_perf2 bash -c "echo 'hostname ospf_perf2\nlog stdout\nrouter ospf\nospf router-id 1.1.1.2\n network 192.168.1.0/24 area 0\n!'> /etc/frr/ospfd.conf"

#sudo docker exec ospf_perf1 bash -c 'cat > /etc/frr/frr.conf <<EOF
#!
#hostname ospf_perf1
#log file /var/log/frr/frr.log
#!
#router ospf 100
# ospf router-id 10.1.1.92
# ip address 192.168.1.2/24
# ip ospf area 0
#!
#router ospf 100
# ospf router-id 1.1.1.1
# network 192.168.1.0/24 area 0
#!
#EOF'

sudo docker exec -it ospf_1 bash -c "

  # 配置 IPv4 转发
  echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
"
sudo docker exec -it ospf_2 bash -c "

  # 配置 IPv4 转发
  echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
"

sudo docker exec -it ospf_3 bash -c "

  # 配置 IPv4 转发
  echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
"

sudo docker exec ospf_1 bash -c 'cat > /etc/frr/frr.conf <<EOF
!
frr defaults traditional
hostname ospf_1
service integrated-vtysh-config
log file /var/log/frr/frr.log
!
interface veth1
 ip ospf area 0
!
router ospf
 ospf router-id 1.1.1.2
 network 192.168.1.0/24 area 0
 network 192.168.2.0/24 area 0
!
EOF'

sudo docker exec ospf_2 bash -c 'cat > /etc/frr/frr.conf <<EOF
!
frr defaults traditional
hostname ospf_2
service integrated-vtysh-config
log file /var/log/frr/frr.log
!
interface veth2
 ip ospf area 0
!
interface veth3
 ip ospf area 0
!
router ospf
 ospf router-id 1.1.1.3
 network 192.168.1.0/24 area 0
 network 192.168.2.0/24 area 0
!
EOF'

sudo docker exec ospf_3 bash -c 'cat > /etc/frr/frr.conf <<EOF
!
frr defaults traditional
hostname ospf_3
service integrated-vtysh-config
log file /var/log/frr/frr.log
!
interface veth4
 ip ospf area 0
!
router ospf
 ospf router-id 1.1.1.4
 network 192.168.1.0/24 area 0
 network 192.168.2.0/24 area 0
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
sudo docker exec ospf_1 /usr/lib/frr/frrinit.sh restart
sudo docker exec ospf_2 /usr/lib/frr/frrinit.sh restart
sudo docker exec ospf_3 /usr/lib/frr/frrinit.sh restart

echo "write:"
sudo docker exec ospf_1 vtysh -c "write"
sudo docker exec ospf_2 vtysh -c "write"
sudo docker exec ospf_3 vtysh -c "write"


#zebra和ospf是否运行
echo "check 进程:"
echo "container1:"
sudo docker exec ospf_1 ps aux | grep ospfd
echo "container2:"
sudo docker exec ospf_2 ps aux | grep ospfd


#验证OSPF
echo "验证OSPF:"
echo "container1:"
sudo docker exec ospf_1 vtysh -c "show ip ospf neighbor"
sudo docker exec ospf_1 vtysh -c "show ip route"

echo "container2:"
sudo docker exec ospf_2 vtysh -c "show ip ospf neighbor"
sudo docker exec ospf_2 vtysh -c "show ip route"

echo "container3:"
sudo docker exec ospf_3 vtysh -c "show ip ospf neighbor"
sudo docker exec ospf_3 vtysh -c "show ip route"

#test connected
#echo "test2:"
#sudo docker exec ospf_perf1 ping -c 2 192.168.1.3 && echo "connectd"

#sudo rm /var/run/netns/$pid1
#sudo rm /var/run/netns/$pid2

#sudo docker stop ospf_perf1
#sudo docker stop ospf_perf2
#sudo docker rm ospf_perf1
#sudo docker rm ospf_perf2


