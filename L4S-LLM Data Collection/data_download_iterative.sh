#!/bin/bash

# Set basic configuration values
set -x


# Create directories if they do not exist
mkdir -p ./server_data
mkdir -p ./client1_data
mkdir -p ./client2_data
mkdir -p ./router_data
mkdir -p ./Graphs
mkdir -p ./stats

sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.siftr.log ./server_data; 
sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.pcap ./server_data;
sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.out ./server_data;
sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.json ./server_data;

sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.siftr.log ./client1_data;
sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.json ./client1_data;
sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.pcap ./client1_data;
sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.out ./client1_data;

sudo scp -P 4423 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.siftr.log ./client2_data;
sudo scp -P 4423 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.json ./client1_data;
sudo scp -P 4423 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.pcap ./client2_data;
sudo scp -P 4423 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.out ./client2_data;

ssh -p 4422 -i ~/.ssh/mptcprootkey root@192.168.56.1 "cat /var/log/messages > llmrawdata.txt"

sudo scp -P 4422 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*txt ./router_data; 

echo "done"
exit 0

# error
out() {
    echo "Abort test"
    exit 1
}