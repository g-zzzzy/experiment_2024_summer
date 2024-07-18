#!/bin/bash

LOGFILE="bgp/throughput/1throughput.txt"

DOCKER_STATS_LOGFILE="bgp/resource/1resource.csv"
echo "Source, Destination, Test Time(seconds), Parallel Streams, Bandwidth(Gbps), Restransmissions" > $LOGFILE

# sudo docker exec -d bgp_con1 bash -c "> /src/bgp/resource/1resource_1.csv.csv"
# sudo docker exec -d bgp_con2 bash -c "> /src/bgp/resource/1resource_2.csv"
# sudo docker exec -d bgp_con1 bash -c "dool --more --output /src/bgp/resource/1resource_1.csv 1 60 &"
# sudo docker exec -d bgp_con2 bash -c "dool --more --output /src/bgp/resource/1resource_2.csv 1 60 &"

#sudo docker exec -d bgp_con2 iperf3 -s
sudo docker exec -d bgp_con2 iperf3 -s
sleep 5

# 运行 docker stats 并将输出重定向到文件
{
  echo "CPU_%,Mem_Usage_Limit,Mem_%" > $DOCKER_STATS_LOGFILE
  while true; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    sudo docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" bgp_con1 | while read stats; do
      echo "$timestamp,$stats" >> $DOCKER_STATS_LOGFILE
    done
    sleep 1
  done
} &
DOCKER_STATS_PID=$!
echo "Running iperf test from bgp_con1 to bgp_con2"
sudo docker exec bgp_con1 iperf3 -c 10.10.1.4 -t 60 > $LOGFILE
# 确保在脚本结束时终止 docker stats 监控进程
trap "kill $DOCKER_STATS_PID" EXIT

# 这里可以放置其他你想要执行的命令或逻辑

# 等待 docker stats 进程结束
wait $DOCKER_STATS_PID
# sudo docker exec bgp_con1 iperf -c 10.10.1.4 -P 32 -t 60 > $LOGFILE
#sudo docker exec bgp_con2 pkill iperf3