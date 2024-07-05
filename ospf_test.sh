#!/bin/bash

#echo "Source, Destination, Test Time, Parallel Streams, Bandwidth(Gbps), CPU Usage(%), Memory Usage(MB)" > $LOGFILE
LOGFILE="ospf/throughput/frr_ospf_throughput_results.csv"
sudo docker exec -d ospf_perf3 bash -c "> /src/ospf/resource/frr_ospf_resource_1to3_record.csv"
sudo docker exec -d ospf_perf1 bash -c "> /src/ospf/resource/frr_ospf_resource_1to3_1record.csv"
sudo docker exec -d ospf_perf2 bash -c "> /src/ospf/resource/frr_ospf_resource_1to3_2record.csv"
sudo docker exec -d ospf_perf3 bash -c "dool --more --output /src/ospf/resource/frr_ospf_resource_1to3_3record.csv 1 60 &"
sudo docker exec -d ospf_perf1 bash -c "dool --more --output /src/ospf/resource/frr_ospf_resource_1to3_1record.csv 1 60 &"
sudo docker exec -d ospf_perf2 bash -c "dool --more --output /src/ospf/resource/frr_ospf_resource_1to3_2record.csv 1 60 &"

sudo docker exec -d ospf_perf3 iperf -s
sleep 5

echo "Running iperf test from ospf_perf1 to ospf_perf3"
sudo docker exec ospf_perf1 iperf -c 192.168.2.5 -t 60 -P 32 > $LOGFILE
#result=$(sudo docker exec ospf_resource1 iperf3 -c 192.168.12.5 -t 60 -P 10 --json)

#bandwidth=$(echo "$result" | jq '.end.sum_received.bits_per_second')
#bandwidth_gbps=$(echo "$bandwidth / (10^9)" | bc -l)
#restransimissions=$(echo "$result" | jq '.end.sum_received.restransmits')

#echo "ospf_perf1, ospf_perf3, 60, 10, $bandwidth_gbps, $retransmissions" >> $LOGFILE

