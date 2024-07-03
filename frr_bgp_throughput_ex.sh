#!/bin/bash

LOGFILE="frr_bgp_throughput_results.csv"
echo "Source, Destination, Test Time(seconds), Parallel Streams, Bandwidth(Gbps), Restransmissions" > $LOGFILE

sudo docker exec -d bgp_con2 iperf3 -s
sleep 5
echo "Running iperf3 test from bgp_con1 to bgp_con2"
result=$(sudo docker exec bgp_con1 iperf3 -c 10.10.1.4 -t 60 -P 10 --json)

bandwidth=$(echo "$result" | jq '.end.sum_received.bits_per_second')
bandwidth_gbps=$(echo "$bandwidth / (10^9)" | bc -l)
restransimissions=$(echo "$result" | jq '.end.sum_received.restransmits')

echo "bgp_con1, bgp_con2, 60, 10, $bandwidth_gbps, $restransmissions" >> $LOGFILE

sudo docker exec bgp_con2 pkill iperf3