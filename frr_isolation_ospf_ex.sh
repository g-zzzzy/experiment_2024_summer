#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_networks>"
    exit 1
fi

N=$1

start_iperf3_server() {
    local i=$1
    local CONTAINER="net${i}_3"
    echo "Starting iperf3 server on $CONTAINER"
    sudo docker exec $CONTAINER iperf3 -sD
}
start_iperf3_client() {
    local i=$1
    local CONTAINER="net${i}_1"
    local SERVER_IP="192.168.$(($i*2+1)).4"
    local LOGFILE="ospf${i}_1_to_3.csv"
    echo "Starting iperf3 client on $CONTAINER to connect to $SERVER_IP"
    sudo docker exec $CONTAINER iperf3 -c $SERVER_IP -t 60 > $LOGFILE &
    #sudo docker exec -d $CONTAINER  iperf3 -c $SERVER_IP -t 60 -P 10 &
}

for i in $(seq 1 $N); do
    start_iperf3_server $i
done

sleep 2

for i in $(seq 1 $N); do
    start_iperf3_client $i
done

wait

# for i in $(seq 1 $N); do
#     sudo docker exec net${i}_3 pkill iperf3
# done

echo "iperf3 tests on $N networks completed."