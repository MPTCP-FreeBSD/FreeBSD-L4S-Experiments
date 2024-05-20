-------------------------------------------------------------------------------
Centre for Advanced Internet Architectures,
Swinburne University of Technology,
Melbourne, Australia

15 October, 2015
Multipath TCP For FreeBSD Kernel Patch v0.51

README-Installation
Author: Nigel Williams <njwilliams@swin.edu.au>
-------------------------------------------------------------------------------

This document provides an overview of installation procedures for the v0.5
release of MPTCP for FreeBSD.

Other Documents in this Release
  mptcp-readme-v0.51.txt
  mptcp-changelog-v0.51.txt
  README-Testing


Additional Software

    Oracle VM VirtualBox [1]: The testbed hosts have been created and 
      configured using VirtualBox. Other VM applications may work but have not 
      been tested. 

    Csh: Required to run several included scripts. The scripts expect csh to 
      be located at '/bin/csh'.  

    Sh: Required for several included scripts. The scripts expects sh to be 
      located at '/bin/sh'.

    Mercurial: Recommended if using the MPTCP repository hosted on BitBucket.


Table of Contents

  1. VIRTUALBOX APPLIANCES
     1.1 Importing OVAs
     1.2 Included Files
     1.5 Installed Utilities

  2. HOST PREPARATION
     2.1 Recommended System
     2.2 Creating VMs

  3. BUILDING FROM SOURCE
     3.1 Mercurial Repository on BitBucket
     3.2 Obtaining Source
     3.3 Building and Installing

  4. PRE-BUILT KERNEL
     4.1 Obtaining the Pre-Built Kernel
     4.2 Installing the Pre-Built Kernel
     4.3 Booting the Original Kernel

  5. REFERENCES

  6. ABOUT
     6.1 Links
     6.2 Development Team
     6.3 Acknowledgements


1. VIRTUALBOX APPLIANCES
------------------------

1.1 Importing OVAs
We have prepared a small topology of Virtual Machines (VMs) as a quick entry-
point to trying the MPTCP kernel. They can be downloaded from the FreeBSD MPTCP
project webpage: 
  http://caia.swin.edu.au/newtcp/mptcp/tools.html

The VMs have been exported from VirtualBox as OVA packages and can be imported 
using the 'import appliance' option. It should be possible to import the VMs 
into other applications (e.g. VMWare) however this has not been tested and the 
document assumes you are using VirtualBox. 

There are two test hosts and two routers. The test hosts are multi-homed while
the routers provide bandwidth shaping and allow any subnet to reach any other 
subnet. Note that the test hosts come with the v0.5 kernel installed. Kernels 
based on later releases will need to be built and installed separately.

Two test hosts with FreeBSD 11.0-CURRENT installed:
  o VM Names: FB11-test1, FB11-test2
  o VM networks and NAT forwarding have been pre-configured
  o Interface addresses have been pre-configured
  o The MPTCP kernel is built with debugging enabled and the follow modules:
      o Based on the v0.5 release
      o ipfw, dummynet and siftr
  o Several files are included for transfer tests and are located at:
      o /root/random{SIZE}.file

Two routers with FreeBSD 10.2-RELEASE installed:
  o VM Names: DummynetVM1, DummynetVM2
  o VM networks and NAT forwarding have been pre-configured
  o Interface addresses have been pre-configured

The root password for each host is 'mptcproot'. There are no additional users 
for the VMs. 


1.2 Included Files
Several random files of different sizes are included on the test hosts, located 
at:
  /root/random32k.file
  /root/random5M.file
  /root/random10M.file

These files can be used for basic transfer tests and are also used by the 
test scripts detailed in 'README-Testing'.

Copies of host configuration files used in the VMs are also available in the 
'confs' folder of the v0.5 package.


1.3 Installed utilities
Rsync is installed on the test clients and is used by the test scripts. 
IPAudit [2] is installed on the routers and can be used to obtain a summary of 
TCP connections across a specific router interface.


2. HOST PREPARATION
-------------------

2.1 Recommended System
The kernel patch has been developed and tested using 64-bit x86 virtual 
machines (VMs). It is also compatible with 32-bit x86. We have not yet 
attempted to build or test for other architectures (for example ARM). This 
documentation assumes that you are using an x86 VM.

If creating a VM and building from source, a 15GB disk image is recommended as 
a minimum. This will be enough to hold the distribution, source and build 
files with around 4-5GB of headroom. A 5GB disk should be adequate if only 
installing the pre-built kernel. Our examples assume you are using VirtualBox.

We recommend installing a snapshot of FreeBSD 11-CURRENT from:
     ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/amd64/amd64/ISO-IMAGES/11.0/

The patch has been tested with a FreeBSD snapshot built from r285794 of HEAD. 
The patch should also be compatible with subsequent snapshots releases for
a period of time.

After creating MPTCP-capable hosts, an appropriate testbed is required to 
observe multi-path behaviour. It is possible to use two directly-connected 
MP-capable hosts, but we recommend the inclusion of at least one router. Our
sample topology uses two routers, and is detailed in 'READEME-Testing'.


2.2 Creating VMs
The MPTCP kernel may be installed onto physical host machines, however we 
recommend starting with the VM-based testbed described in this document. If 
using the pre-made VM images, skip to Section 4. 

If building from source or using the pre-built kernel, scripts are provided to 
simplify the creation of VMs and a basic multi-path network topology:
  setup/VM_setup.sh     (sh)
  setup/copy_keys.sh    (csh)
  setup/copy_confs.sh   (sh)

The scripts must be run in the order as shown above. 'VM_setup.sh' has a 
single argument, that being the path of the FreeBSD install ISO (the script 
assumes VirtualBox is installed). For example:
  # ./VM_setup.sh FreeBSD-11.0-CURRENT-amd64-20150722-r285794-disc1.iso

The script will create four VMs with NAT forwarding enabled for SSH:

          VM Name       NAT Port    Disk Size    Function            
          DummynetVM1   4422        4GB          Router/shaping host
          DummynetVM2   4423        4GB          Router/shaping host
          FB-test1      3322        15GB         MP-enabled host
          FB-test2      3323        4GB          MP-enabled host

All NICs are enabled and set to internal networks for use with the provided 
test scripts (see topology diagram in 'README-Testing'). The specified ISO is 
mounted, and launching the VM will start the install process. The ports tree 
and source files are not required. The ISO should be ejected from the VM once
installation is complete.

On completing the install, make the following edits to '/etc/ssh/sshd_config':
  PermitRootLogin yes
  UseDNS no

After root login is enabled, run 'copy_keys.sh'. This script will copy a public
and private key to each of the hosts to allow for password-less login (this
is required for running the test scripts).

After keys have been copied, running 'copy_confs.sh' will copy the following
configuration files to each of the VMs:
  /etc/rc.conf
  /etc/ipfw.rules
  /boot/loader.conf

Upon reboot, the testbed will be configured in the topology as described in 
'README-Testing'. The MPTCP kernel should now be installed. To build from the 
source patch, see Section 2. To install the pre-built kernel, see Section 3.


3. BUILDING FROM SOURCE
-----------------------

3.1 Mercurial Repository on BitBucket
As of v0.51 the implementation is no longer available as a patch. The full 
FreeBSD source plus MPTCP modifications is now available from a repository
on BitBucket:
    https://bitbucket.org/nw-swin/caia-mptcp-freebsd

The repository contains two branches:
  caia-mptcp-head
  freebsd-head

The 'freebsd-head' branch pulls updates from the FreeBSD mercurial repository 
at 'hg-beta.freebsd.org/base'. The 'caia-mptcp-head' branch contains the MPTCP-
enabled kernel, and is merged with 'freebsd-head' at least once a week. 

Revisions in the 'caia-mptcp-head' branch that are designated as releases are
tagged in the format 'caia-mptcp-vX.XX'. It is possible to switch between 
different releases by updating to a particular release tag and re-building.


3.2 Obtaining Source
The general use of Mercurial is beyond the scope of this document, however 
following the basic commands below should be sufficient for obtaining and 
building the source. 

On a FreeBSD host, mercurial can be installed using the following command (as 
root): 
  pkg install mercurial

A zip archive of the repository is available on the BitBucket project page for
download, or if mercurial is installed you can clone the repository using 
the following command:
  hg clone -U https://bitbucket.org/nw-swin/caia-mptcp-freebsd

If there is an SSL certificate error, try the following:
  hg clone --insecure -U https://bitbucket.org/nw-swin/caia-mptcp-freebsd  

The repository will create a new folder called 'caia-mptcp-freebsd', which
will contain only a hidden '.hg' subfolder after cloning. To see the source 
files update to the v0.51 release:
  hg update caia-mptcp-v0.51

Now that you have a local copy of the repository, it can be updated to include 
the most recent commits by issuing the following command from the root of the
repository:
  hg pull


3.3 Building and Installing
The MPTCP kernel can be built on FreeBSD 10 and FreeBSD 11 hosts, however the
kernel binary must be installed onto a FreeBSD 11 host. 

Issuing the following commands will build and install the mptcp-enabled
distribution:

  # Building the Kernel
  cd path/to/caia-mptcp-freebsd
  make -s kernel-toolchain
  make -s KERNCONF=MPTCP buildkernel

Install the kernel as the default system kernel:
  make KERNCONF=MPTCP MODULES_OVERRIDE="ipfw dummynet" installkernel

Here the MODULES_OVERRIDE directive is used to limit the modules included with
the installed kernel. 

The kernel is installed to /boot/kernel and can be copied to another 
host (with the same version of FreeBSD) to enable MPTCP on that host. See 
Section 4.2 for instructions on how to install a pre-built kernel.

If using nextboot, or if you want to copy the kernel to another test host, 
install to a specified folder:
  make KERNCONF=MPTCP installkernel DESTDIR=/path/to/install

Use nextboot if you want the MPTCP kernel to load only on the next boot (the
default kernel is restored for subsequent boot ups):
  nextboot -k ../path/to/install/boot/kernel

The kernel binary can also be copied to another host for installation. This
process is the same as that described in Section 4.

Upon reboot MPTCP will be enabled by default, and the host will attempt 
to use MPTCP when setting up new connections. Settings such as TSO should be 
disabled when attempting to use multipath connections (see Section 3.3 in
mptcp-readme-v0.5.txt).

We recommend configuring the MPTCP-enabled hosts as per the files found in 
'setup/confs' of the v0.51 'allfiles' package.


4. PRE-BUILT KERNEL
-------------------

4.1 Obtaining the Pre-Built Kernel
Before attempting to install the MPTCP kernel, a base FreeBSD system should 
already be installed (see Section 1.2).

The kernel is built against revision 285254 of FreeBSD-HEAD, and has been 
tested with a FreeBSD-CURRENT snapshot against revision 285794. The kernel can 
be downloaded from the following location:
 http://caia.swin.edu.au/urp/newtcp/mptcp/tools/v05/mptcp_v0.5_11.x.285254.kern.tgz

Within the archive is a single folder 'kernel', containing the kernel and 
kernel modules. Extract the archive to a temporary location (e.g. /tmp/kernel).


4.2 Installing the Pre-Built Kernel
Assuming the kernel has been downloaded and extracted to '/tmp/kernel', use the
following commands to install the kernel as the default boot kernel of the 
system:

  cd /boot/
  mv kernel kernel.original  # keep the original kernel
  cp -r /tmp/kernel .        # copy the mptcp kernel to boot
  shutdown -r now

Upon reboot the MPTCP will be loaded. If you have created the hosts as per the 
instructions in Section 1.2, the VMs will be ready to run the test scripts 
described in 'README-Testing'.


4.3 Booting the Original Kernel
If required, the original kernel can be booted with the following steps:

(1) At the boot menu, hit escape or select option 3: 
    '3. [Esc]ape to loader prompt'

(2) This will exit the boot menu and enter the boot prompt. Then enter:
    boot kernel.original


5. REFERENCES
-------------

  [1] Oracle VirtualBox, https://www.virtualbox.org/
  [2] IPAudit, http://ipaudit.sourceforge.net/index.html


6. ABOUT
--------

6.1 Links
This software was developed at Swinburne University's Centre for Advanced 
Internet Architectures, under the umbrella of the NewTCP research project. 
More information on the project is available at:
    http://caia.swin.edu.au/urp/newtcp/

The FreeBSD MPTCP implementation homepage can be found at:
    http://caia.swin.edu.au/urp/newtcp/mptcp


6.2 Development Team
This FreeBSD MPTCP implementation was first released in 2013 by the Multipath
TCP research project at Swinburne University of Technology's Centre for
Advanced Internet Architectures (CAIA), Melbourne, Australia. The members
of this project team are:

Lead developer:              Nigel Williams      (njwilliams@swin.edu.au)
Technical advisor/developer: Lawrence Stewart    (lastewart@swin.edu.au)
Project leader:              Grenville Armitage  (garmitage@swin.edu.au)


6.3 Acknowledgements
This project has been made possible in part by grants from:
  o The FreeBSD Foundation   
  o The Cisco University Research Program Fund, at Community Foundation 
    Silicon Valley



