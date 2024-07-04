#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_networks>"
    exit 1
fi

N=$1

for i in $(seq 1 $N); do
    CONTAINER1="net${i}_1"
    CONTAINER2="net${i}_2"
    sudo docker rm -f $CONTAINER1
    sudo docker rm -f $CONTAINER2
done