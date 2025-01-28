#!/bin/bash

# Set basic configuration values
set -x


# Access to the source host
srchost="test1"
srchostport="3322"

# Access to the destination host
dsthost="test2"
dsthostport="3323"

# Access to the two dummynet routers
router1port="4422"
router2port="4423"

# Access to VMs and router
src1host="test2"
src1port="3323"
src2host="server"
src2port="4423"
dsthost="client1"
dsthostport="3322"
router1host="dummynetVM1"
router1port="4422"

echo "Script started"

# SSH key
sshkey="mptcprootkey"
sshkeypath="$HOME/.ssh/mptcprootkey"

# Address of VM Host Machine
vmhostaddr="192.168.56.1"

# Set siftr (0 disabled, 1 enabled)
do_siftr="1"

# Set tcpdump (0 disabled, 1 enabled)
do_tcpdump="1"

# Function to end logging data
end_log(){
    # Stop siftr, if enabled
    if [ "$do_siftr" -eq 1 ]; then
        sleep 1
        echo "Stop siftr on $src1host"
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" \
        "sysctl net.inet.siftr.enabled=0"

        sleep 1
        echo "Stop siftr on $src2host"
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" \
        "sysctl net.inet.siftr.enabled=0"

        sleep 1
        echo "Stop siftr on $dsthost"
        ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" \
        "sysctl net.inet.siftr.enabled=0"
    fi

    # Stop tcpdump, if enabled
    if [ "$do_tcpdump" -eq 1 ]; then
        sleep 1
        echo "Stop tcpdump on $src1host"
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" \
        "killall tcpdump"
    fi

    # Stop tcpdump, if enabled
    if [ "$do_tcpdump" -eq 1 ]; then
        sleep 1
        echo "Stop tcpdump on $src2host"
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" \
        "killall tcpdump"
    fi

    # Stop tcpdump on dsthost, if enabled
    if [ "$do_tcpdump" -eq 1 ]; then
        sleep 1
        echo "Stop tcpdump on $dsthost"
        ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" \
        "killall tcpdump"
    fi
    
}

ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out;rm *.json"
ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out;rm *.json"
ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out;rm *.json"
ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out;rm *.json"

ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "truncate -s 0 /var/log/messages"

ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"
ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"
ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"

end_log
# completed
echo "Reset complete"
exit 0

# error
out() {
    echo "Abort test"
    exit 1
}