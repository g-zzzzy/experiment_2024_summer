#!/bin/bash

LOGFILE="bgp/throughput/1throughput_rate40g.txt"

# DOCKER_STATS_LOGFILE="bgp/resource/1resource_mem20.csv"
echo "Source, Destination, Test Time(seconds), Parallel Streams, Bandwidth(Gbps), Restransmissions" > $LOGFILE

# sudo docker exec -d bgp_con1 bash -c "> /src/bgp/resource/1resource_1.csv.csv"
# sudo docker exec -d bgp_con2 bash -c "> /src/bgp/resource/1resource_2.csv"
# sudo docker exec -d bgp_con1 bash -c "dool --more --output /src/bgp/resource/1resource_1.csv 1 60 &"
# sudo docker exec -d bgp_con2 bash -c "dool --more --output /src/bgp/resource/1resource_2.csv 1 60 &"
pid1=$(sudo docker inspect -f '{{.State.Pid}}' bgp_con1)
pid2=$(sudo docker inspect -f '{{.State.Pid}}' bgp_con2)
echo "rate check:"
sudo ip netns exec $pid1 tc qdisc del root dev veth1
sudo ip netns exec $pid1 tc qdisc add root dev veth1 handle 1: htb default 2
sudo ip netns exec $pid1 tc class add dev veth1 parent 1: classid 1:1 htb rate 50Mbit ceil 50Mbit prio 0
sudo ip netns exec $pid1 tc class add dev veth1 parent 1:1 classid 1:2 htb rate 50Mbit ceil 50Mbit prio 1 burst 96kbit
sudo ip netns exec $pid1 tc class add dev veth1 parent 1:1 classid 1:3 htb rate 40Mbit ceil 50Mbit prio 1 burst 96kbit
sudo ip netns exec $pid1 tc filter add dev veth1 protocol ip parent 1:0 prio 1 u32 match ip src 10.10.1.2/24 flowid 1:2

# 在命名空间 pid1 内检查 veth1 的带宽限制
sudo ip netns exec $pid1 tc qdisc show dev veth1
sudo ip netns exec $pid1 tc class show dev veth1

# 在命名空间 pid2 内检查 veth2 的带宽限制
# sudo ip netns exec $pid2 tc -s qdisc show dev veth2
# sudo ip netns exec $pid2 tc -s class show dev veth2

#sudo docker exec -d bgp_con2 iperf3 -s
sudo ip netns exec $pid2 iperf -s &

sleep 5

# 运行 docker stats 并将输出重定向到文件
# {
#   echo "CPU_%,Mem_Usage_Limit,Mem_%" > $DOCKER_STATS_LOGFILE
#   while true; do
#     timestamp=$(date +"%Y-%m-%d %H:%M:%S")
#     sudo docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" bgp_con1 | while read stats; do
#       echo "$timestamp,$stats" >> $DOCKER_STATS_LOGFILE
#     done
#     sleep 1
#   done
# } &
# DOCKER_STATS_PID=$!
echo "Running iperf test from bgp_con1 to bgp_con2"

sudo ip netns exec $pid1 iperf -c 10.10.1.4 -i 1 -t 60 > $LOGFILE
# sudo ip netns exec $pid2 iperf -c 10.10.1.4 -t 60 > $LOGFILE
