#!/bin/bash

# Set basic configuration values
set -x

# TCP variants
tcp1="newreno"
tcp2="dctcp"

# AQM schemes
aqm_schemes=("l4s")

# Bandwidth, delay, and ECN settings
bandwidth=("8Mbps")
delay=("10ms")

# bandwidth=("24Mbps")
# delay=("20ms")

ecn=("ecn")

# Set TCP ECN enable on clients
tcp_ecn_enable=1
dctcp_ect1=1

# Set test duration (60 seconds) and wait time
duration=60
end_wait_time=30

# Access to VMs and router
src1host="test2"
src1port="3323"
src2host="server"
src2port="4423"
dsthost="client1"
dsthostport="3322"
router1host="dummynetVM1"
router1port="4422"

# Enable or disable SIFTR and TCPDUMP
do_siftr="1"
do_tcpdump="1"

# SSH key settings
sshkey="mptcprootkey"
sshkeypath="$HOME/.ssh/mptcprootkey"
vmhostaddr="192.168.56.1"

# Number of iterations to run (10 times)
iterations=10

# Function to configure TCP CC and ECN on Source
configure_tcp_cc_ecn() {
    ecn_status=$1
    echo "Configuring TCP CC and ECN on sources"
    ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "kldload cc_$tcp1"
    ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.cc.algorithm=$tcp1"
    ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "kldload cc_$tcp2"
    ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.cc.algorithm=$tcp2"

    # Set DCTCP ECT1
    if [ "$tcp1" == "dctcp" ]; then
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.cc.dctcp.ect1=$dctcp_ect1"
    fi

    if [ "$tcp2" == "dctcp" ]; then
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.cc.dctcp.ect1=$dctcp_ect1"
    fi

    # Set ECN enable
    if [ "$ecn_status" == "ecn" ]; then
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.ecn.enable=$tcp_ecn_enable"
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.ecn.enable=$tcp_ecn_enable"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.ecn.enable=$tcp_ecn_enable"
    elif [ "$ecn_status" == "noecn" ]; then
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.ecn.enable=0"
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.ecn.enable=0"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.ecn.enable=0"
    fi
}

# Function to configure AQM on routers
configure_routers() {
    aqm=$1
    bw=$2
    d=$3
    e=$4
    echo "Configuring AQM: $aqm with bandwidth $bw and delay $d, ECN: $e"
    ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw -f flush"
    ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw pipe 1 config bw $bw delay $d"
    ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw sched 1 config pipe 1 type $aqm $e"
    ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw queue 1 config sched 1"
    ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw add 100 queue 1 ip from any to any"
}

# Function to run iperf3 client and server
client_iperf3_script() {
    iter=$1
    echo "Running iperf3 client-side test, iteration $iter"
    ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -c 172.16.1.2 -t $duration -p 5101 -J -C cubic > iperf3_client_cubic_${iter}_$aqm.json" &
    ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -c 172.16.1.2 -t $duration -p 5102 -J > iperf3_client_${tcp1}_${iter}_$aqm.json" &
    ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -c 172.16.1.2 -t $duration -p 5103 -J > iperf3_client_${tcp2}_${iter}_$aqm.json"
    sleep $end_wait_time
}

server_iperf3_script() {
    iter=$1
    echo "Running iperf3 server-side test, iteration $iter"
    ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -s -p 5101 -1 -J > iperf3_server_${tcp1}_${iter}_$aqm.json" &
    ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -s -p 5102 -1 -J > iperf3_server_${tcp2}_${iter}_$aqm.json" &
    ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -s -p 5103 -1 -J > iperf3_server_${tcp2}_${iter}_$aqm.json" &
}


# Function to start logging data
start_log(){
    aqm=$1
    bw=$2
    d=$3
    e=$4
    testname="${iter}_${aqm}_${bw}_${d}_${e}"
    # Configure siftr, if enabled
    if [ "$do_siftr" -eq 1 ]; then
        sleep 1
        echo "Starting siftr on $src1host"
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" \
        "rm /root/${testname}_${tcp1}_src1.siftr.log && touch /root/${testname}_${tcp1}_src1.siftr.log ;sysctl net.inet.siftr.logfile=/root/${testname}_${tcp1}_src1.siftr.log"
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" \
        "sysctl net.inet.siftr.enabled=1"

        echo "Starting siftr on $src2host"
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" \
        "rm /root/${testname}_${tcp2}_src2.siftr.log && touch /root/${testname}_${tcp2}_src2.siftr.log ;sysctl net.inet.siftr.logfile=/root/${testname}_${tcp2}_src2.siftr.log"
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" \
        "sysctl net.inet.siftr.enabled=1"

        sleep 1
        echo "Starting siftr on $dsthost"
        ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" \
        "rm /root/${testname}.siftr.log && touch /root/${testname}.siftr.log ; sysctl net.inet.siftr.logfile=/root/${testname}_dst.siftr.log"
        ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" \
        "sysctl net.inet.siftr.enabled=1"
    fi

    if [ "$do_tcpdump" -eq 1 ]; then
        sleep 1
        echo "Starting tcpdump on $src1host"
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "tcpdump -i em1 -w /root/${testname}_${tcp1}_src1.em1.pcap > tcpdump.em1.out 2>&1 & tcpdump -i em2 -w /root/${testname}_${tcp1}_src1.em2.pcap > tcpdump.em2.out 2>&1 &"

        sleep 1
        echo "Starting tcpdump on $src2host"
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "tcpdump -i em1 -w /root/${testname}_${tcp2}_src2.em1.pcap > tcpdump.em1.out 2>&1 & tcpdump -i em2 -w /root/${testname}_${tcp2}_src2.em2.pcap > tcpdump.em2.out 2>&1 & tcpdump -i em3 -w /root/${testname}_${tcp2}_src2.em3.pcap > tcpdump.em3.out 2>&1 &"

        sleep 1
        echo "Starting tcpdump on $dsthost"
        ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "tcpdump -i em1 -w /root/${testname}.em1.pcap > tcpdump.em1.out 2>&1 & tcpdump -i em2 -w /root/${testname}_dst.em2.pcap > tcpdump.em2.out 2>&1 &"
    fi


    
}

# Function to end logging data
end_log(){
    aqm=$1
    bw=$2
    d=$3
    e=$4
    testname="${iter}_${aqm}_${bw}_${d}_${e}"
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


# Cleanup previous data and iperf3 instances
cleanup() {
    echo "Cleaning up previous data and processes"
    ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out; killall iperf3"
    ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out; killall iperf3"
    ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out"
}

# Before starting delete all previous files
ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out"
ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out"
ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "rm *.siftr.log;rm *.pcap;rm *.out"

ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"
ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"
#ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"

rm -r ./server_data
rm -r ./client1_data
rm -r ./client2_data
rm -r ./Graphs
rm -r ./stats


# Function to run the test
run_test() {
    iter=$1
    for aqm in "${aqm_schemes[@]}"; do
        for bw in "${bandwidth[@]}"; do
            for d in "${delay[@]}"; do
                for e in "${ecn[@]}"; do
                    configure_tcp_cc_ecn "$e"
                    configure_routers "$aqm" "$bw" "$d" "$e"
                    start_log "$iter" "$aqm" "$bw" "$d" "$e"
                    server_iperf3_script "$iter"
                    client_iperf3_script "$iter"
                    end_log "$iter" "$aqm" "$bw" "$d" "$e"
                done
            done
        done
    done
}

# Main execution loop for running 10 iterations
for i in $(seq 1 $iterations); do
    echo "Running test iteration $i"
    run_test "$i"
    echo "Iteration $i completed"
done

# completed
echo "Test complete"
exit 0

# error
out() {
    echo "Abort test"
    exit 1
}
