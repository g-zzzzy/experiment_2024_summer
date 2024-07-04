#!/bin/bash

IMAGE="gzy:3"

if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_networks>"
    exit 1
fi

N=$1

for i in $(seq 1 $N); do
    CONTAINER1="net${i}_1"
    CONTAINER2="net${i}_2"
    CONTAINER3="net${i}_3"

    docker run --privileged -itd --name $CONTAINER1 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE
    docker run --privileged -itd --name $CONTAINER2 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE
    docker run --privileged -itd --name $CONTAINER3 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE

    sudo docker exec -it $CONTAINER1 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"
    sudo docker exec -it $CONTAINER2 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"
    sudo docker exec -it $CONTAINER3 /bin/bash -c "sysctl -w net.ipv4.ip_forward=1"


    VETH1="veth${i}a"
    VETH2="veth${i}b"
    VETH3="veth${i}c"
    VETH4="veth${i}d"
    sudo ip link add $VETH1 type veth peer name $VETH2
    sudo ip link add $VETH3 type veth peer name $VETH4


    pid1=$(sudo docker inspect -f '{{.State.Pid}}' $CONTAINER1)
    pid2=$(sudo docker inspect -f '{{.State.Pid}}' $CONTAINER2)
    pid3=$(sudo docker inspect -f '{{.State.Pid}}' $CONTAINER3)

    sudo ln -s /proc/$pid1/ns/net /var/run/netns/$pid1
    sudo ln -s /proc/$pid2/ns/net /var/run/netns/$pid2
    sudo ln -s /proc/$pid3/ns/net /var/run/netns/$pid3

    sudo ip link set $VETH1 netns $pid1
    sudo ip link set $VETH2 netns $pid2
    sudo ip link set $VETH3 netns $pid2
    sudo ip link set $VETH4 netns $pid3

    sudo ip netns exec $pid1 ip link set $VETH1 up
    sudo ip netns exec $pid1 ip addr add 192.168.$(($i*2)).2/24 dev $VETH1
    sudo ip netns exec $pid2 ip link set $VETH2 up
    sudo ip netns exec $pid2 ip addr add 192.168.$(($i*2)).4/24 dev $VETH2
    sudo ip netns exec $pid2 ip link set $VETH3 up
    sudo ip netns exec $pid2 ip addr add 192.168.$(($i*2+1)).2/24 dev $VETH3
    sudo ip netns exec $pid3 ip link set $VETH4 up
    sudo ip netns exec $pid3 ip addr add 192.168.$(($i*2+1)).4/24 dev $VETH4

    sudo docker exec -it $CONTAINER1 bash -c "

        # 配置 IPv4 转发
        echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
        sysctl -p /etc/sysctl.conf
    "
    sudo docker exec -it $CONTAINER2 bash -c "

        # 配置 IPv4 转发
        echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
        sysctl -p /etc/sysctl.conf
    "

    sudo docker exec -it $CONTAINER3 bash -c "

        # 配置 IPv4 转发
        echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
        sysctl -p /etc/sysctl.conf
    "


    sudo docker exec $CONTAINER1 bash -c "cat > /etc/frr/frr.conf <<EOF
    !
    frr defaults traditional
    hostname $CONTAINER1
    service integrated-vtysh-config
    log file /var/log/frr/frr.log
    !
    interface $VETH1
     ip ospf area 0
    !
    router ospf
     ospf router-id 1.$i.1.2
     network 192.168."$(($i*2+1))".0/24 area 0
     network 192.168."$(($i*2))".0/24 area 0
    !
    EOF"

    sudo docker exec $CONTAINER2 bash -c "cat > /etc/frr/frr.conf <<EOF
    !
    frr defaults traditional
    hostname $CONTAINER2
    service integrated-vtysh-config
    log file /var/log/frr/frr.log
    !
    interface $VETH2
     ip ospf area 0
    !
    interface $VETH3
     ip ospf area 0
    !
    router ospf
     ospf router-id 1.$i.1.3
     network 192.168."$(($i*2+1))".0/24 area 0
     network 192.168."$(($i*2))".0/24 area 0
    !
    EOF"

    sudo docker exec -it $CONTAINER3 bash -c "cat > /etc/frr/frr.conf <<EOF
    !
    frr defaults traditional
    hostname $CONTAINER3
    service integrated-vtysh-config
    log file /var/log/frr/frr.log
    !
    interface $VETH4
     ip ospf area 0
    !
    router ospf
     ospf router-id 1.$i.1.4
     network 192.168."$(($i*2+1))".0/24 area 0
     network 192.168."$(($i*2))".0/24 area 0
    !
    EOF"

    

    sudo docker exec $CONTAINER1 /usr/lib/frr/frrinit.sh restart
    sudo docker exec $CONTAINER2 /usr/lib/frr/frrinit.sh restart
    sudo docker exec $CONTAINER3 /usr/lib/frr/frrinit.sh restart
    

    sudo docker exec $CONTAINER1 vtysh -c "write"
    sudo docker exec $CONTAINER2 vtysh -c "write"
    sudo docker exec $CONTAINER3 vtysh -c "write"
done

echo "Created $N networks with BGP configured."
