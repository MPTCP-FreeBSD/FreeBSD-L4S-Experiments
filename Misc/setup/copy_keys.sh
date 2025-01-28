#!/bin/csh
#
# Copy the public and private keys across to all the testbed hosts. Assumes
# that NAT forwarding has been configured and each of the VMs is running.
#  
# This _should_ be run on the controller host, but will work if run from 
# elsewhere. 

if ($#argv != 2) then
        echo "Usage: $0 <controller-host> <username>"
        echo "If this is the controller, use: localhost <username>"
        exit 1
endif

# Host that will act as the controller for tests
set controller = $1

# The user on the controller that will execute the test scripts
set controlleruser = $2

set keypath = "keys"

# hosts
set test1port = "3322"
set test2port = "3323"

# routers
set router1port = "4422"
set router2port = "4423"

# Configure keys on the host executing the script
echo "Configure key on current host"
rm -f  ~/.ssh/mptcprootkey
cp $keypath/mptcprootkey ~/.ssh/
chmod 400 ~/.ssh/mptcprootkey


echo "If copying for the first time, there will be some password prompts."

# Configure key on the controller (this might well be the same as the
# host running the script)
echo "Configuring key on controller host"

if ($controller != "localhost") then
    echo "Remove old key"
    ssh $controlleruser@$controller 'rm -f  ~/.ssh/mptcprootkey'

    echo "Copy new key"
    scp -p -i ~/.ssh/mptcprootkey ~/.ssh/mptcprootkey ${controlleruser}@${controller}:/root/.ssh/

endif

# First test host
echo "create .ssh folder"
ssh -p $test1port root@$controller 'mkdir .ssh/'
echo "Copying root public key to host at port $test1port"
scp -P $test1port -o StrictHostKeyChecking=no -p -i ~/.ssh/mptcprootkey $keypath/mptcprootkey.pub root@${controller}:/root/.ssh/authorized_keys
echo "set authorized keys permissions to 644"
ssh -p $test1port root@$controller 'chmod 644 .ssh/authorized_keys'

echo "Copying root private key to host at port $test1port"
scp -P $test1port -p -i ~/.ssh/mptcprootkey ~/.ssh/mptcprootkey root@${controller}:/root/.ssh/


# Second test host
echo "create .ssh folder"
ssh -p $test2port root@$controller 'mkdir .ssh/'
echo "Copying root public key to host at port $test2port"
scp -P $test2port -o StrictHostKeyChecking=no -p -i ~/.ssh/mptcprootkey $keypath/mptcprootkey.pub root@${controller}:/root/.ssh/authorized_keys
echo "set authorized keys permissions to 644"
ssh -p $test2port root@$controller 'chmod 644 .ssh/authorized_keys'

echo "Copying root private key"
scp -P $test2port -p -i ~/.ssh/mptcprootkey ~/.ssh/mptcprootkey root@${controller}:/root/.ssh/

# First router host
echo "create .ssh folder"
ssh -p $router1port root@$controller 'mkdir .ssh/'
echo "Copying root public key to host at port $test2port"
scp -P $router1port -o StrictHostKeyChecking=no -p -i ~/.ssh/mptcprootkey $keypath/mptcprootkey.pub root@${controller}:/root/.ssh/authorized_keys
echo "set authorized keys permissions to 644"
ssh -p $router1port root@$controller 'chmod 644 .ssh/authorized_keys'

echo "Copying root private key (for VM to VM connections)"
scp -P $router1port -p -i ~/.ssh/mptcprootkey ~/.ssh/mptcprootkey root@${controller}:/root/.ssh/

# Second router host
echo "Copying root public key to host at port $test2port"
ssh -p $router2port root@$controller 'mkdir .ssh/'
scp -P $router2port -o StrictHostKeyChecking=no -p -i ~/.ssh/mptcprootkey $keypath/mptcprootkey.pub root@${controller}:/root/.ssh/authorized_keys
echo "set authorized keys permissions to 644"
ssh -p $router2port root@$controller 'chmod 644 .ssh/authorized_keys'

echo "Copying root private key (for VM to VM connections)"
scp -P $router2port -p -i ~/.ssh/mptcprootkey ~/.ssh/mptcprootkey root@${controller}:/root/.ssh/

exit 0