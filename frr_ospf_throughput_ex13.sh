#!/bin/bash
LOGFILE="frr_ospf_throughput_1to3_results.csv"

echo "Source, Destination, Test Time(seconds), Parallel Streams, Bandwidth(Gbps), Restransmissions" > $LOGFILE

sudo docker exec -d ospf_perf3 iperf3 -s
sleep 5

echo "Running iperf3 test from ospf_perf1 to ospf_perf3"
result=$(sudo docker exec ospf_perf1 iperf3 -c 192.168.2.5 -t 60 -P 10 --json)

bandwidth=$(echo "$result" | jq '.end.sum_received.bits_per_second')
bandwidth_gbps=$(echo "$bandwidth / (10^9)" | bc -l)
restransimissions=$(echo "$result" | jq '.end.sum_received.restransmits')

echo "ospf_perf1, ospf_perf3, 60, 10, $bandwidth_gbps, $retransmissions" >> $LOGFILE

sudo docker exec ospf_perf3 pkill iperf3