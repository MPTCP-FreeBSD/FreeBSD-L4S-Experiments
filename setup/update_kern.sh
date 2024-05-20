#!/bin/sh
#
# Download kernel binary and copy onto VM testbed hosts. Assumes using the VMs
# from the CAIA MPTCP website, and ssh keys have been copied already.
# 
# Can be run from the controller host

# access to the VMs
test1port="3322"
test2port="3323"
test1VMName="FB11-test1"
test2VMName="FB11-test2"

# path to the kernel
kernel_url="http://caia.swin.edu.au/newtcp/mptcp/tools/v051/"
kernel_file="mptcp-kernel-v0.51.tgz"


# call wget or fetch to download the kernel file. exit if neither are
# installed
download_file()
{
    if type "wget" > /dev/null; then
      wget $1$2
      return
    fi

    if type "fetch" > /dev/null; then
      fetch $1$2
      return
    fi

    echo "Install wget or fetch, or download $kernel manually and re-run script"
    exit 1
}

# run a command via ssh
# port command
ssh_command()
{
    ssh -p $1 root@$vmhost -i ~/.ssh/mptcprootkey $2
}

# copy the kernels onto the test hosts
# port srcPath dstPath
do_scp()
{
    echo "Copying $2 to $3 on host at port $1..."
    scp -P $1 -p -i ~/.ssh/mptcprootkey $2 root@$vmhost:$3
}

if [ -z "$1" ]
  then
    echo "Usage: ./update_kern.sh <vm-host-machine-address>"
    exit 1
fi

# the address of the host running the VMs
vmhost=$1

# check if the file already exists
if [ -f $kernel_file ];
then
    echo "$kernel_file already exists. copying to test hosts"
else
    download_file ${kernel_url} ${kernel_file}

    # make sure the file was downloaded
    if [ -f $kernel_file ]; then
        echo "Got kernel file"
    else
        echo "file $kernel_file not downloaded, exiting"
        exit 1
    fi
fi

# uncompress the archive
echo "Unpacking archive"
tar xvzf $kernel_file

echo "Copying to test1"
do_scp $test1port "-r kernel" "/boot/"

echo "Copying to test2"
do_scp $test2port "-r kernel" "/boot/"

echo "Done"
exit 0


