#!/bin/bash
export PATH=$PATH:/mnt/d/Vaibhav/bin
export PATH=$PATH:/mnt/d/Vaibhav/bin/node-linux/bin
export PATH=$PATH:/mnt/d/Vaibhav/fabric-samples/bin
cd /mnt/d/Vaibhav/fabric-samples/test-network
./network.sh deployCC -ccn farm2formula -ccp /mnt/d/Vaibhav/chaincode/farm2formula -ccl javascript -ccv 1.0 -ccs 1
