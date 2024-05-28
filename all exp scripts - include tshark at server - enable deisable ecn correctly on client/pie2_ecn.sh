#!/bin/csh
#
# Launch a single-path rsync where the client initiates a connection
# then pushes data.
#

set testname="pie2_ecn"

# Access to the source host
set srcvm = "FB13-test1"
set srchost = "test1"
set srchostport = "3322"
set srchostaddr = "172.16.2.2"
set srchostmpaddr = "0"

# Access to the destination host
set dstvm = "FB13-test2"
set dsthost = "test2"
set dsthostport = "3323"
set dsthostaddr = "172.16.3.2"
set dsthostmpaddr = "0"

# Access to the two dummynet routers
set router1port = "4422"
set router2port = "4423"

# Dummynet data rate
set vm1drate = "1Mbps"
set vm2drate = "1Mbps"


set vm1delay = "20ms"
set vm2delay = "20ms"

# File to be transferred
set rcvfilepath = "/tmp"               # path on the receiver
set filename = "random10M.file"        # the actual filename
set filesource = "/root/${filename}"   # source for rsync command
set filedest = "172.16.3.2:/tmp"       # dest for rsync command

# Receiver host port (to clear data before transfer)
set rcvhostport = $dsthostport  # Pushing data to server

# Set siftr (0 disabled, 1 enabled)
set do_siftr = "1"

# Set tcpdump (0 disabled, 1 enabled)
set do_tcpdump = "1"

echo "Loaded config for single path rysnc"
echo "----"
echo "" && echo "${srchost} (client) is single-homed, ${dsthost} (server) is"
echo "single-homed and we PUSH data from ${srchost} to ${dsthost}."



# SSH key
set sshkey = "mptcprootkey"

# Address of VM Host Machine
set vmhostaddr = "192.168.56.1"


# Configure desired dummynet settings


# WHat I need
# ipfw pipe 1 config bw 10mbits/s delay 20ms codel
echo "Configuring DummynetVM1 for $vm1drate"
ssh -p $router1port -i ~/.ssh/$sshkey root@$vmhostaddr "sysctl net.inet.tcp.ecn.enable=1"
ssh -p $router1port -i ~/.ssh/$sshkey root@$vmhostaddr "ipfw pipe 1 config bw $vm1drate delay $vm1delay pie target 20 tupdate 30ms max_burst 100ms ecn"
ssh -p $router1port -i ~/.ssh/$sshkey root@$vmhostaddr "ipfw add 100 pipe 1 ip from any to any"

echo "Configuring DummynetVM2 for $vm2drate"
ssh -p $router2port -i ~/.ssh/$sshkey root@$vmhostaddr "ipfw pipe 1 config bw $vm1drate delay $vm1delay pie target 20 tupdate 30ms max_burst 100ms ecn"
ssh -p $router1port -i ~/.ssh/$sshkey root@$vmhostaddr "ipfw add 100 pipe 1 ip from any to any"



# Configure siftr, if enabled
if ($do_siftr == 1) then
    sleep 1
    echo "Starting siftr on $srchost"
    ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "rm /root/${testname}.siftr.log ; touch /root/${testname}.siftr.log ; sysctl net.inet.siftr.logfile=/root/${testname}.siftr.log"
    ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "sysctl net.inet.siftr.enabled=1"

    sleep 1
    echo "Starting siftr on $dsthost"
    ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "rm /root/${testname}.siftr.log ; touch /root/${testname}.siftr.log ; sysctl net.inet.siftr.logfile=/root/${testname}.siftr.log"
    ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "sysctl net.inet.siftr.enabled=1"
endif

# Start tcpdump, if enabled
if ($do_tcpdump == 1) then
    sleep 1
    echo "Starting tcpdump on $srchost"
    ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "tcpdump -i em1 -w /root/${testname}.em1.pcap >& tcpdump.em1.out & ; tcpdump -i em2 -w /root/${testname}.em2.pcap >& tcpdump.em2.out & ;"
endif

# Start tcpdump, if enabled
if ($do_tcpdump == 1) then
    sleep 1
    echo "Starting tcpdump on $srchost"
    ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "tcpdump -i em1 -w /root/${testname}.em1.pcap >& tcpdump.em1.out & ; tcpdump -i em2 -w /root/${testname}.em2.pcap >& tcpdump.em2.out & ;"
endif

# initiate test
echo "Starting iperf3 test"
# ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -s -1"

# ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -c 172.16.3.2 -t 60"




# ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -s -p 5101 -1" >/dev/null &
# ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -s -p 5102 -1" >/dev/null &
# ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -s -p 5103 -1" >/dev/null &
# ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -s -p 5104 -1" >/dev/null &



ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -c 172.16.3.2 -t 60 -p 5101" >/dev/null &
sleep 10
ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -c 172.16.3.2 -t 60 -p 5102" >/dev/null &
sleep 10
ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -c 172.16.3.2 -t 60 -p 5103" >/dev/null &
sleep 10
ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr "iperf3 -c 172.16.3.2 -t 60 -p 5104"

sleep 100






# Stop siftr, if enabled
if ($do_siftr == 1) then
    sleep 1
    echo "Stop siftr on $srchost"
    ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "sysctl net.inet.siftr.enabled=0"

    sleep 1
    echo "Stop siftr on $dsthost"
    ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "sysctl net.inet.siftr.enabled=0"
endif

# Stop tcpdump, if enabled
if ($do_tcpdump == 1) then
    sleep 1
    echo "Stop tcpdump on $srchost"
    ssh -p $srchostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "killall tcpdump"
endif

# Stop tcpdump, if enabled
if ($do_tcpdump == 1) then
    sleep 1
    echo "Stop tcpdump on $srchost"
    ssh -p $dsthostport -i ~/.ssh/$sshkey root@$vmhostaddr \
    "killall tcpdump"
endif

# completed
echo "Test complete"
exit 0

# error
out:
    echo "Abort test"
    exit 1