#!/bin/bash

#echo "Source, Destination, Test Time, Parallel Streams, Bandwidth(Gbps), CPU Usage(%), Memory Usage(MB)" > $LOGFILE
LOGFILE="ospf/throughput/throughput_60G.csv"
# DOCKER_STATS_LOGFILE="ospf/resource/1resource.csv"
# # sudo docker exec -d ospf_perf3 bash -c "> /src/ospf/resource/frr_ospf_resource_1to3_record.csv"
# # sudo docker exec -d ospf_perf1 bash -c "> /src/ospf/resource/frr_ospf_resource_1to3_1record.csv"
# # sudo docker exec -d ospf_perf2 bash -c "> /src/ospf/resource/frr_ospf_resource_1to3_2record.csv"
# # sudo docker exec -d ospf_perf3 bash -c "dool --more --output /src/ospf/resource/frr_ospf_resource_1to3_3record.csv 1 60 &"
# # sudo docker exec -d ospf_perf1 bash -c "dool --more --output /src/ospf/resource/frr_ospf_resource_1to3_1record.csv 1 60 &"
# # sudo docker exec -d ospf_perf2 bash -c "dool --more --output /src/ospf/resource/frr_ospf_resource_1to3_2record.csv 1 60 &"

sudo docker exec -d ospf_3 iperf3 -s
sleep 5

# 运行 docker stats 并将输出重定向到文件
# {
#   echo "Name,CPU_%,Mem_Usage_Limit,Mem_%" > $DOCKER_STATS_LOGFILE
#   while true; do
#     timestamp=$(date +"%Y-%m-%d %H:%M:%S")
#     sudo docker stats --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}}" ospf_1 | while read stats; do
#       echo "$timestamp,$stats" >> $DOCKER_STATS_LOGFILE
#     done
#     sleep 1
#   done
# } &
# DOCKER_STATS_PID=$!

echo >> $LOGFILE
echo "Running iperf3 test from ospf_1 to ospf_3"
# -b 60G
sudo docker exec ospf_1 iperf3 -c 192.168.2.5 -t 60 > $LOGFILE

# 确保在脚本结束时终止 docker stats 监控进程
# trap "kill $DOCKER_STATS_PID" EXIT

