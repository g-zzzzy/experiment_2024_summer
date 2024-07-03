#!/bin/bash

#echo "Source, Destination, Test Time, Parallel Streams, Bandwidth(Gbps), CPU Usage(%), Memory Usage(MB)" > $LOGFILE

sudo docker exec -d bgp_con1 bash -c "> /src/frr_bgp_resource_1to2_1record.csv"
sudo docker exec -d bgp_con2 bash -c "> /src/frr_bgp_resource_1to2_2record.csv"
sudo docker exec -d bgp_con1 bash -c "dool --more --output /src/frr_bgp_resource_1to2_1record.csv 1 60 &"
sudo docker exec -d bgp_con2 bash -c "dool --more --output /src/frr_bgp_resource_1to2_2record.csv 1 60 &"

sudo docker exec -d bgp_con2 iperf3 -s
sleep 5

echo "Running iperf3 test from bgp_con1 to bgp_con2"
sudo docker exec bgp_con1 iperf3 -c 10.10.1.4 -t 60 -P 10 --json

#result=$(sudo docker exec ospf_resource1 iperf3 -c 192.168.12.5 -t 60 -P 10 --json)

#bandwidth=$(echo "$result" | jq '.end.sum_received.bits_per_second')
#bandwidth_gbps=$(echo "$bandwidth / (10^9)" | bc -l)
#restransimissions=$(echo "$result" | jq '.end.sum_received.restransmits')

#echo "ospf_perf1, ospf_perf3, 60, 10, $bandwidth_gbps, $retransmissions" >> $LOGFILE

sudo docker exec bgp_con2 pkill iperf3