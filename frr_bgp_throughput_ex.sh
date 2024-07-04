#!/bin/bash

LOGFILE="frr_bgp_throughput_results.csv"
echo "Source, Destination, Test Time(seconds), Parallel Streams, Bandwidth(Gbps), Restransmissions" > $LOGFILE

sudo docker exec -d bgp_con2 iperf3 -s
sleep 5
echo "Running iperf3 test from bgp_con1 to bgp_con2"
sudo docker exec bgp_con1 iperf3 -c 10.10.1.4 -t 60 > $LOGFILE

sudo docker exec bgp_con2 pkill iperf3