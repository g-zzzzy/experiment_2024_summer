#!/bin/bash

LOGFILE="frr_bgp_throughput_results.csv"
echo "Source, Destination, Test Time(seconds), Parallel Streams, Bandwidth(Gbps), Restransmissions" > $LOGFILE

sudo docker exec -d bgp_con1 bash -c "> /src/bgp/resource/frr_bgp_resource_1to2_1record.csv"
sudo docker exec -d bgp_con2 bash -c "> /src/bgp/resource/frr_bgp_resource_1to2_2record.csv"
sudo docker exec -d bgp_con1 bash -c "dool --more --output /src/bgp/resource/frr_bgp_resource_1to2_1record.csv 1 60 &"
sudo docker exec -d bgp_con2 bash -c "dool --more --output /src/bgp/resource/frr_bgp_resource_1to2_2record.csv 1 60 &"

#sudo docker exec -d bgp_con2 iperf3 -s
sudo docker exec -d bgp_con2 iperf -s
sleep 5
echo "Running iperf3 test from bgp_con1 to bgp_con2"
#sudo docker exec bgp_con1 iperf3 -c 10.10.1.4 -t 60 > $LOGFILE
sudo docker exec bgp_con1 iperf -c 10.10.1.4 -P 32 -t 60 > $LOGFILE
#sudo docker exec bgp_con2 pkill iperf3