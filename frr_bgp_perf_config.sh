#!/bin/bash

IMAGE="gzy:3"

sudo docker run --privileged -itd --name bgp_con1 --network none $IMAGE
sudo docker run --privileged -itd --name bgp_con2 --network none $IMAGE

sudo docker exec -it bgo_con1 /bin/bash -c "sysctl -w net.ipv4




