FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y python3 python3-dev python3-pip && \
	apt-get install -y git && \
	apt-get install -y tcpdump && \
	apt-get install -y inetutils-ping
RUN apt-get install -y iperf3
RUN apt-get install -y netperf
RUN apt-get install -y openvswitch-switch
RUN apt-get install -y openvswitch-common
RUN apt-get install -y iproute2
RUN apt-get install -y frr frr-pythontools
RUN apt-get install -y vim
RUN git clone https://github.com/scottchiefbaker/dool.git
RUN python3 /dool/install.py

RUN sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons && cat /etc/frr/daemons
RUN sed -i '/^zebra=.*/d' /etc/frr/daemons && \
	echo "zebra=yes" >> /etc/frr/daemons
RUN sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons

RUN apt-get install -y iperf