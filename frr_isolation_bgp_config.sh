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

    docker run --privileged -itd --name $CONTAINER1 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE
    docker run --privileged -itd --name $CONTAINER2 --mount type=bind,source="$(pwd)",target=/src --network none $IMAGE

    VETH1="veth${i}a"
    VETH2="veth${i}b"
    sudo ip link add $VETH1 type veth peer name $VETH2

    pid1=$(sudo docker inspect -f '{{.State.Pid}}' $CONTAINER1)
    pid2=$(sudo docker inspect -f '{{.State.Pid}}' $CONTAINER2)

    sudo ln -s /proc/$pid1/ns/net /var/run/netns/$pid1
    sudo ln -s /proc/$pid2/ns/net /var/run/netns/$pid2

    sudo ip link set $VETH1 netns $pid1
    sudo ip link set $VETH2 netns $pid2

    sudo ip netns exec $pid1 ip link set $VETH1 up
    sudo ip netns exec $pid1 ip addr add 10.10.$i.2/24 dev $VETH1
    sudo ip netns exec $pid2 ip link set $VETH2 up
    sudo ip netns exec $pid2 ip addr add 10.10.$i.4/24 dev $VETH2

    sudo docker exec -it $CONTAINER1 bash -c "cat > /etc/frr/frr.conf <<EOF
    !
    frr defaults traditional
    hostname $CONTAINER1
    service integrated-vtysh-config
    !
    router bgp "$((100+$i))"
     bgp router-id 10.10.$i.2
     network 100.10.$i.0/24
     neighbor 10.10.$i.4 remote-as "$((200+$i))"
     neighbor 10.10.$i.4 ebgp-multihop
     address-family ipv4 unicast
     exit-address-family
    !
    EOF"

    sudo docker exec -it $CONTAINER2 bash -c "cat > /etc/frr/frr.conf <<EOF
    !
    frr defaults traditional
    hostname $CONTAINER2
    service integrated-vtysh-config
    !
    router bgp "$((200+"$i"))"
     bgp router-id 10.10.$i.4
     network 200.10.$i.0/24
     neighbor 10.10.$i.2 remote-as "$((100+"$i"))"
     neighbor 10.10.$i.2 ebgp-multihop
     address-family ipv4 unicast
     exit-address-family
    !
    EOF"

    sudo docker exec $CONTAINER1 /usr/lib/frr/frrinit.sh restart
    sudo docker exec $CONTAINER2 /usr/lib/frr/frrinit.sh restart
    
    sudo docker exec $CONTAINER1 vtysh -c "write"
    sudo docker exec $CONTAINER2 vtysh -c "write"
done

echo "Created $N networks with BGP configured."
