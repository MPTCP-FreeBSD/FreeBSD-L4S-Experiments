#!/bin/sh

# Create a VM for use in MPTCP example testbed
# Will create and configure a VM suitable for the example testebed,
# as outlined in the MPTCP release documentation. Will be prompted 
# for installation media on first boot. The user will need to eject
# the ISO post-installation.
#
# Tested on:
# - Ubuntu Linux
#

# make_vm() - Does the work of creating a new VM. 
# called with: 
#   make_vm name size memory nat_port nic2_intnet nic3_intnet nic4_intnet
make_vm()
{
    # ---- Create VM and Storage ---- #
    VM=$1
    DISKSIZE=$2
    SYSMEM=$3
    NATPORT=$4
    INTNET_NIC2=$5
    INTNET_NIC3=$6
    INTNET_NIC4=$7

    echo "----"
    echo "Creating VM: $VM"
    echo "Disk size (MB): $DISKSIZE"
    echo "Memory (MB): $SYSMEM"
    echo "NAT port: $NATPORT"
    echo "Internal networks: $INTNET_NIC2 $INTNET_NIC3 $INTNET_NIC4"
    echo "----"

    VBoxManage createvm --name $VM --ostype "FreeBSD_64" --register

    echo "Configuring storage..."
    VBoxManage createhd --filename $DIPATH/$VM.vdi --size $DISKSIZE
    VBoxManage storagectl $VM --name "IDE" --add ide --controller PIIX4
    VBoxManage storageattach $VM --storagectl "IDE" --port 0 --device 0 --type hdd --medium $DIPATH/$VM.vdi
    VBoxManage storageattach $VM --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium $ISOPATH

    # ---- Misc Settings ---- #
    echo "Apply system settings..."
    VBoxManage modifyvm $VM --ioapic on --pae on --longmode on
    VBoxManage modifyvm $VM --boot1 disk --boot2 dvd --boot3 none --boot4 none
    VBoxManage modifyvm $VM --memory $SYSMEM --vram 16

    # ---- NICs ---- #
    # Access to guest host via ssh
    echo "Configure NAT forwarding from port ${NATPORT}"
    VBoxManage modifyvm $VM --nic1 nat --nictype1 82540EM 
    VBoxManage modifyvm $VM --natpf1 "guestssh,tcp,,${NATPORT},,22"

    # Test subnets (172.x)
    VBoxManage modifyvm $VM --nic2 intnet --nictype2 82540EM 
    VBoxManage modifyvm $VM --intnet2 $INTNET_NIC2
    VBoxManage modifyvm $VM --nic3 intnet --nictype2 82540EM 
    VBoxManage modifyvm $VM --intnet3 $INTNET_NIC3

    # Router bypass (192.x) or Router link (172.16.5.0) interfaces
    VBoxManage modifyvm $VM --nic4 intnet --nictype2 82540EM 
    VBoxManage modifyvm $VM --intnet4 $INTNET_NIC4

    echo "VM created"
}

# Path to installer ISO, from command line
ISOPATH=$1 
DIPATH="disk_images"

# Make sure we have installation media
if [ -z "$ISOPATH" ]; then
    echo "Must specify an ISO image"
    exit 1
else
    echo "Will mount installation media $ISOPATH"
fi

# Put the disk images in their own subdirectory
if [ -d $DIPATH ]; then
    echo ""
else
    mkdir $DIPATH
fi

# create testbed hosts
make_vm FB11-test1 10240 1024 3322 mptcp-intnet1 mptcp-intnet2 mptcp-intnet0
make_vm FB11-test2 4096 512 3323 mptcp-intnet3 mptcp-intnet4 mptcp-intnet0
make_vm DummynetVM1 4096 512 4422 mptcp-intnet1 mptcp-intnet3 mptcp-intnet5
make_vm DummynetVM2 4096 512 4423 mptcp-intnet2 mptcp-intnet4 mptcp-intnet5

echo "Done. Launch VMs from VirtualBox to complete install of FreeBSD."
echo "Remember to eject the ISO once install is complete."
exit 0

