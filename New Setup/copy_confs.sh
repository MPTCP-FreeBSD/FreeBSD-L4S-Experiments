#!/bin/sh
#
# Copy the config files onto each VM, 
#
# Assumes private/public keys have been copied already, is executed on the
# VM Host machine

# do scp: port file_path dest_path
# Just copies the files across, ssh key is hardcoded...
do_scp()
{
    echo "Copying $2 to $3 on host at port $1..."
    scp -P $1 -p -i ~/.ssh/mptcprootkey $2 root@$controller:$3
}

# Assumes this is run on the VM Host machine
controller="localhost"

# NAT forwarding ports
host1port="3322"
host2port="3323"
router1port="4422"
router2port="4423"

# First test host
do_scp $host1port confs/test1-confs/rc.conf /etc/
do_scp $host1port confs/test1-confs/ipfw.rules /etc/
do_scp $host1port confs/test1-confs/loader.conf /boot/

# Second test host
do_scp $host2port confs/test2-confs/rc.conf /etc/
do_scp $host2port confs/test2-confs/ipfw.rules /etc/
do_scp $host2port confs/test2-confs/loader.conf /boot/

# First router
do_scp $router1port confs/DummynetVM1-confs/rc.conf /etc/
do_scp $router1port confs/DummynetVM1-confs/ipfw.rules /etc/
do_scp $router1port confs/DummynetVM1-confs/loader.conf /boot/

# First router
do_scp $router2port confs/DummynetVM2-confs/rc.conf /etc/
do_scp $router2port confs/DummynetVM2-confs/ipfw.rules /etc/
do_scp $router2port confs/DummynetVM2-confs/loader.conf /boot/

echo "done"
exit 0



