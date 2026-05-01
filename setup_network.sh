#!/bin/bash
export PATH=$PATH:/mnt/d/Vaibhav/bin
export PATH=$PATH:/mnt/d/Vaibhav/fabric-samples/bin
cd /mnt/d/Vaibhav/fabric-samples/test-network
./network.sh down
./network.sh up createChannel -c mychannel -ca
