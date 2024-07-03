#!/bin/bash
sudo docker stop ospf_resource1
sudo docker stop ospf_resource2
sudo docker stop ospf_resource3
sudo docker rm ospf_resource1
sudo docker rm ospf_resource2
sudo docker rm ospf_resource3