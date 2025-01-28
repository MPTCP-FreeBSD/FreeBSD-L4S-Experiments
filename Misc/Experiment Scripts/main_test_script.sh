#!/bin/bash

# Set basic configuration values
set -x
# tcp1="cubic"
# tcp2="dctcp"
tcp1="cubic"
tcp2="dctcp"

# aqm_schemes=("fq_codel" "fq_pie" "l4s")
aqm_schemes=("l4s" "fq_codel" "fq_pie" )
aqm_schemes=("fq_pie" "fq_codel" "l4s" )
aqm_schemes=("fq_codel" "fq_pie" "l4s" )
# aqm_schemes=("l4s")


bandwidth=("1Mbps" "10Mbps")
# bandwidth=("10Mbps")
delay=("20ms")
delay=("20ms" "40ms" "10ms")
# ecn=("ecn" "noecn")
ecn=("ecn")


# set tcp.ecn.enable on clients
tcp_ecn_enable=1
# Enable ECT(1) for dctcp
dctcp_ect1=1

# duration=60
# wait_time_bw_stream=10
# end_wait_time=100

duration=60
wait_time_bw_stream=10
end_wait_time=100


# Access to the source host
src1host="test2"
src1port="3323"
src2host="server"
src2port="4423"

# Access to the destination host
dsthost="client1"
dsthostport="3322"

# Access to the one dummynet router
router1host="dummynetVM1"
router1port="4422"




# Set siftr (0 disabled, 1 enabled)
do_siftr="1"

# Set tcpdump (0 disabled, 1 enabled)
do_tcpdump="1"



echo "Script started"

# SSH key
sshkey="mptcprootkey"
sshkeypath="$HOME/.ssh/mptcprootkey"

# Address of VM Host Machine
vmhostaddr="192.168.56.1"





# Function to configure TCP CC algorithm and ECN on Source
configure_tcp_cc_ecn() {
    ecn_status=$1
    echo "Configuring TCP CC algorithm and ECN on Source 1"
    ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "kldload cc_$tcp1"
    ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.cc.algorithm=$tcp1"
    
    echo "Configuring TCP CC algorithm and ECN on Source 2"
    ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "kldload cc_$tcp2"
    ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.cc.algorithm=$tcp2"

    # Check if tcp is "dctcp" and set additional parameter
    if [ "$tcp1" == "dctcp" ]; then
        ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.cc.dctcp.ect1=$dctcp_ect1"
    fi

    if [ "$tcp2" == "dctcp" ]; then
        ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "sysctl net.inet.tcp.cc.dctcp.ect1=$dctcp_ect1"
    fi
    
    # Check if ecn_status is "ecn" and set ecn.enable to 3
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
    echo "======================================================================================================================"
    echo "configure AQM on routers $aqm , $bw , $d and $e"
    # Check if ecn_status is "ecn" and set ecn.enable to 3
    if [ "$aqm" == "fq_codel" ] || [ "$aqm" == "fq_pie" ] || [ "$aqm" == "l4s" ]; then
  
        echo "Configuring Router 1"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw -f flush"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw pipe 1 config bw $bw delay $d"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw sched 1 config pipe 1 type $aqm $e"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw queue 1 config sched 1"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw add 100 queue 1 ip from 172.16.0.0/16 to 172.16.0.0/16"


        # echo "Configuring Router 2"
        # ssh -p "$router2port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw -f flush"
        # ssh -p "$router2port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw pipe 1 config bw $bw delay $d"
        # ssh -p "$router2port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw sched 1 config pipe 1 type $aqm $e"
        # ssh -p "$router2port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw queue 1 config sched 1"
        # ssh -p "$router2port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw add 100 queue 1 ip from 172.16.0.0/16 to 172.16.0.0/16"


    elif [ "$aqm" == "codel" ] || [ "$aqm" == "pie" ]; then
        echo "Configuring Router 1"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw -f flush"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw pipe 1 config bw $bw delay $d $aqm $e"
        ssh -p "$router1port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw add 100 pipe 1 ip from any to any"

        # echo "Configuring Router 2"
        # ssh -p "$router2port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw -f flush"
        # ssh -p "$router2port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw pipe 1 config bw $bw delay $d $aqm $e"
        # ssh -p "$router2port" -i "$sshkeypath" root@"$vmhostaddr" "ipfw add 100 pipe 1 ip from any to any"
    fi
}

# Function to start logging data
start_log(){
    aqm=$1
    bw=$2
    d=$3
    e=$4
    testname="${aqm}_${bw}_${d}_${e}"
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
    testname="${aqm}_${bw}_${d}_${e}"
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

client_iperf3_script() {
    echo "start client side running iperf3 tests"
    ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -c 172.16.1.2 -t $duration -p 5101" >/dev/null &       
    ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -c 172.16.1.2 -t $duration -p 5102"
    sleep $end_wait_time
    # wait
}

server_iperf3_script() {
    echo "run server side iperf3 scripts"

    ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -s -p 5101 -1" >/dev/null &
    ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "iperf3 -s -p 5102 -1" >/dev/null &
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


# Nested for loops to iterate over each combination
for aqm in "${aqm_schemes[@]}"; do
    for bw in "${bandwidth[@]}"; do
        for d in "${delay[@]}"; do
            for e in "${ecn[@]}"; do
                # echo "Aqm: $aqm, Bandwidth: $bw, Delay: $d, ECN: $e"
                # Add your code here for each combination
                configure_tcp_cc_ecn "$e"
                configure_routers "$aqm" "$bw" "$d" "$e"
                start_log "$aqm" "$bw" "$d" "$e"
                #server_iperf3_script
                client_iperf3_script                

                end_log "$aqm" "$bw" "$d" "$e"
                ssh -p "$src1port" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"
                ssh -p "$src2port" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"
                #ssh -p "$dsthostport" -i "$sshkeypath" root@"$vmhostaddr" "killall iperf3"
            done
        done
    done
done

# Create directories if they do not exist
mkdir -p ./server_data
mkdir -p ./client1_data
mkdir -p ./client2_data
mkdir -p ./Graphs
mkdir -p ./stats

sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.siftr.log ./server_data; 
sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.pcap ./server_data;
sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.out ./server_data;

sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.siftr.log ./client1_data;
sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.pcap ./client1_data;
sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.out ./client1_data;

sudo scp -P 4423 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.siftr.log ./client2_data;
sudo scp -P 4423 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.pcap ./client2_data;
sudo scp -P 4423 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.out ./client2_data;


# completed
echo "Test complete"
exit 0

# error
out() {
    echo "Abort test"
    exit 1
}