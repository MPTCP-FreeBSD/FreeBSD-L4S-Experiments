# L4S-TestingCode
L4S test scripts







# Introduction

This repository stores the source code for customized AQM kernel. In this document, we will introduce how to build and run the customized AQM kernel on FreeBSD Version 13.1, and how to run the AQM test suite on FreeBSD Version 13. The result of the test suite generates two types of files:

- `.pcap` file which can be opened by [Wireshark](https://www.wireshark.org/) to analyze the AQM packets.
- `.siftr` file which is a kernel module logs a range of statistics on active AQM connections to a log file.[1] For more information please check [FreeBSD SIFTR Manual Page](https://www.freebsd.org/cgi/man.cgi?query=siftr&apropos=0&sektion=4&manpath=FreeBSD+11.0-RELEASE&arch=default&format=html).

# Installation

## Prerequisites

Before building the customized AQM kernel, you need to install the following software:

- VirtualBox: [Download](https://www.virtualbox.org/wiki/Downloads)
- Bash Shell(bash): Bash shell is used to run the test suite. Bash is installed by default on Ubuntu, if not use command:

  ```bash
  sudo apt-get install bash
  ```


  If using FreeBSD to run the test suite, You need to install Bash, as it is not installed by default. You can download using the following command:

  ```csh
  pkg install bash
  ```

- FreeBSD Version 13.1: You can download from [here](http://ftp-archive.freebsd.org/mirror/FreeBSD-Archive/old-releases/ISO-IMAGES/13.1/?C=S&O=D).

## Build virtual machines

To build virtual machines for running the customized AQM kernel and the test suite. You can use [build vm script](./setup/VM_create.sh) in this repository, it uses [VboxManage](https://www.virtualbox.org/manual/ch08.html) command to create four virtual machines including two routers and two hosts for making AQM requests.

```bash
cd setup
sh ./VM_create.sh <FreeBSD version 13.1 iso file>
```

The script will create four virtual machines and install FreeBSD on them. The virtual machines will be named `FB13.1-test1`, `FB13.1-test2`, `DummynetVM1`, and `DummynetVM2`. The script will also set up other things like network interfaces, NAT port forwarding for SSH, disk size and so on. You can also change the variables in the script to customize the virtual machines.

\* Please notice, when installing the FreeBSD on the virtual machines, please install the _FreeBSD Ports_, and enable the _SSH_ service.

## Pre setup

### SSH

The first step after FreeBSD version 13.1 is installed on the virtual machines is to set up SSH.

1. Firstly, you have to enable root-level login via SSH, you can do this by editing the `/etc/ssh/sshd_config` file and changing the following line:

   ```bash
   PermitRootLogin yes
   UseDNS no
   ```

2. Then, you have to restart the SSH service by running the following command:

   ```bash
    service sshd restart
   ```

3. Finally, you can use the [SSH key setup script](./setup/copy_keys.sh) to copy the SSH key from the host to the virtual machines. You can run the script by the following command:

   ```bash
   cd setup
   csh ./copy_keys.sh <host> <vm-username>
   ```

   This script will copy the SSH key from the host to the virtual machines. Thus you can log in to the virtual machines without entering the password.

### Configuration files

The next step is to copy the configuration files to the virtual machines including [rc.conf](<https://www.freebsd.org/cgi/man.cgi?rc.conf(5)>), [loader.conf](<https://www.freebsd.org/cgi/man.cgi?loader.conf(5)>), and [ipfw.rules](<https://www.freebsd.org/cgi/man.cgi?ipfw(8)>).

Similarly, you can use the [configuration files setup script](./setup/copy_confs.sh) to copy the configuration files to the virtual machines. You can run the script by the following command:

```bash
cd setup
csh ./copy_confs.sh
```

### Install Git
To install Git, you can use the following command:
```
pkg install git
```
if pkg is not installed, it will install it for you. If not follow the instructions below
If the pkg package manager is not installed on the virtual machines, you must install Git manually from FreeBSD Ports or find a pkg mirror maintained by a third party(There could be risks). You can install Git by running the following command:

```bash
cd /usr/ports/devel/git
make install clean BATCH="yes"
```

## Build customized AQM kernel

After the virtual machines are set up, you can build and install the customized AQM kernel by running the following commands:

First, SSH to the virtual machine:
```bash
ssh -p 3322 root@localhost
```
Clone the kernel source:
```bash
git clone https://github.com/deolsatish/FB13.1-AQM-SRC.git <path>
git checkout FB13.1-L4S-KERNEL-SRC
cd <path>
```
Build the world (everything but the kernel):
```bash
make buildworld
```
Build and install the kernel:
```bash
make buildkernel -j4 -DKERNFAST KERNCONF=L4SKERNEL
make installkernel -j4 -DKERNFAST KERNCONF=L4SKERNEL
shutdown -r now
```
Install the world:
```bash
cd <path>
make installworld
shutdown -r now
```

# Run the test suite

## Setup

I assume that you have already installed bash on the host. If not, please check the [Prerequisites](#prerequisites) section.

The test suite is located in the `Experiment Scripts` directory. There is an automated script to run all tests; you can simply run the following command:

```bash
cd Experiment\ Scripts
bash main_test_script.sh
```

In the script, you can modify parameters like TCP congestion control algorithm, AQM algorithm, bandwidth size, delay and ECN or disable _siftr_ and _tcpdump_ by changing the following line:

```bash
# Set basic configuration values
set -x
tcp="newreno"
# tcp="dctcp"
# tcp="cubic"
aqm_schemes=("codel" "pie" "fq_codel" "fq_pie" "l4s")
bandwidth=("1Mbps" "10Mbps")
delay=("20ms")
ecn=("ecn" "noecn")

# set tcp.ecn.enable on clients
tcp_ecn_enable=1

In the script, you can enable or disable _siftr_ and _tcpdump_ by changing the following line:

```bash
# Set siftr (0 disabled, 1 enabled)
set do_siftr = "1"

# Set tcpdump (0 disabled, 1 enabled)
set do_tcpdump = "1"
```

## Generate test results

After the test is finished, the result files will automatically be generated in the `~/` directory of the host. The result files are named as `<aqm scheme>_<network scenario>.pcap` or `<aqm scheme>.<network scenario>.siftr.log`. The result files then can be used to observe the network traffic or perform DRL training.
