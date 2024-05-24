-------------------------------------------------------------------------------
Centre for Advanced Internet Architectures,
Swinburne University of Technology,
Melbourne, Australia

1st September, 2015
Multipath TCP For FreeBSD Kernel Patch v0.5

README-Testing
Author: Nigel Williams <njwilliams@swin.edu.au>
-------------------------------------------------------------------------------

This document describes a sample multi-path network topology for use with the 
FreeBSD MPTCP patch v0.5. Please refer to 'mptcp-readme-v0.5.txt' and 
'README-Installation' before reading this document.

Other Documents in this Release
  mptcp-readme-v0.5.txt
  mptcp-changelog-v0.5.txt
  README-Installation


Definitions

    VM Host Machine: The machine running the virtualisation application
      (e.g. VirtualBox [1]) and thus 'hosting' the VMs.

    VM Guest: The testbed VMs running on the VM Host Machine (routers and test 
      hosts).

    Controller Host: The host on which test scripts are executed. The
      controller must have network access to the VM Host Machine and 
      the VM Guests (I.e. testbed VMs).


Required Software

    Oracle VM VirtualBox: The testbed hosts have been created and configured 
      using VirtualBox. Other VM applications may work but have not been 
      tested. 

    Csh: Required on the controller host to run the test scripts. The scripts
      expect csh to be located at '/bin/csh'.


Other software

    Wireshark: Packet trace analyser with graphical interface. Parses MPTCP
      protocol signalling [2].
    Tcptrace: Command line packet trace analyser, useful for creating quick
      TCP connection summaries or outputting trace statistics to text [3].
    IPAudit: Command line utility that monitors and interface and provides a
      summary of connections [4]. IPAudit is pre-installed on the router VMs.


Table of Contents

  1. BEFORE TESTING

  2. NETWORK TOPOLOGY
     2.1 VirtualBox Internal Networks
     2.2 Topology Diagram
     2.3 Routing and Dummmynet
     2.4 Interface Configuration

  3. TEST SCRIPTS
     3.1 Test Description
     3.2 Using the Test Scripts
     3.3 Viewing Per-subflow Statistics
     3.4 Potential Starving of Subflow Send Buffers

  4. REFERENCES

  5. ABOUT
     5.1 Links
     5.2 Development Team
     5.3 Acknowledgements


1. BEFORE TESTING
-----------------

This document assumes you have downloaded the pre-made VMs or configured a 
testbed as per 'README-Installation'. This document has been written assuming
this setup, however the theory may be applied to other similarly configured
testbeds. We recommend reading 'mptcp-readme-v0.5.txt' and 'README-
Installation' before continuing.


2. NETWORK TOPOLOGY
-------------------

2.1 VirtualBox Internal Networks
A number of internal networks (intnets) are used to provide different subnets, 
shown below:
  
                         intnet      subnet          
                         ------      ------          
                         int-mptcp0  192.168.0.0/24  
                         int-mptcp1  172.16.1.0/24   
                         int-mptcp2  172.16.2.0/24   
                         int-mptcp3  172.16.3.0/24   
                         int-mptcp4  172.16.4.0/24   
                         int-mptcp5  172.16.5.0/24   


2.2 Topology Diagram
The test topology (omitting the control network, router bypass subnet).

                                   em0
                                    |  
                                +--------+
             int-mptcp1      em1|        |em2        int-mptcp3
                 +--------------|   R1   |--------------+
                 |              |        |              |
                 |              +--------+              |
              em1|                  |em3                |em1
            +--------+              |               +--------+
        em0-|        |              |               |        |-em0
            | Test 1 |          int-mptcp5          | Test 2 |
        em3-|        |              |               |        |-em3
            +--------+              |               +--------+
              em2|                  |em3                |em2
                 |              +--------+              |
                 |              |        |              |
                 +--------------|   R2   |--------------+
             int-mptcp2      em1|        |em2        int-mptcp4
                                +--------+
                                    |
                                   em0


o em0 on each host is configured via DHCP and enables SSH access to the
  testbed hosts.
o The 'int-mptcp0' network bypasses the routers and directly connects the two
  test hosts.
o The 'int-mptcp5' network connects the routers and allows each of the subnets 
  to access the others.


2.3 Routing and Dummynet
Dummynet rate limiting is applied on 'em1' of the two routers. Thus the 
bottleneck links are the 172.16.1.0 (int-mptcp1) and 172.16.2.0 (int-mptcp2) 
subnets.

Static routes are configured on the test hosts so that the 'em1' interface is
used as the default for connections to any of the '172.x' subnets. For example,
from '/etc/rc.conf' on Test 1:
               # Test1 - go via 172.16.1.1 by default
               static_routes="internal3 internal4"
               route_internal3="-net 172.16.3.0/24 172.16.1.1"
               route_internal4="-net 172.16.4.0/24 172.16.1.1"

The result of this is that the address on 'em1' is always the first address 
used in a multi-path connection, and the address of 'em2' is made available to 
a connection using the 'mp_addresses' sysctl (see Section 4.1 of 'mptcp-readme-
v0.5.txt').

An ipfw routing policy is set so that the outbound interface is selected based
on the source-address of the IP packet. For example from '/etc/ipfw.rules' on 
Test 1:
               # Source-address based routing for outgoing packets
               add fwd 172.16.2.1 tcp from 172.16.2.2 to any
               add fwd 172.16.1.1 tcp from 172.16.1.2 to any

This ensures that packets are forwarded to the appropriate next-hop based on
the source address, rather than the destination address (which may result in 
packets being sent via the default gateway). Section 4.2 of 'mptcp-readme-
v0.5.txt' discusses the reasons for the use of ipfw 'fwd' rules.


2.4 Interface configuration

               Test1
               -----
               em0="DHCP"             (NAT forwarding port: 3322)
               em1="172.16.1.2/24"    (int-mptcp1)
               em2="172.16.2.2/24"    (int-mptcp2)
               em3="192.168.0.100/24" (int-mptcp0)

               Test2
               -----
               em0="DHCP"             (NAT forwarding port: 3323)
               em1="172.16.3.2/24"    (int-mptcp3)
               em2="172.16.4.2/24"    (int-mptcp4)
               em3="192.168.0.200/24" (int-mptcp0)

               R1 (DummynetVM1)
               ----------------
               em0="DHCP"             (NAT forwarding port: 4422)
               em1="172.16.1.1/24"    (int-mptcp1)
               em2="172.16.3.1/24"    (int-mptcp3)
               em3="172.16.5.1/24"    (int-mptcp5)

               R2 (DummynetVM2)
               ----------------
               em0="DHCP"             (NAT forwarding port: 4423)
               em1="172.16.2.1/24"    (int-mptcp2)
               em2="172.16.4.1/24"    (int-mptcp4)
               em3="172.16.5.2/24"    (int-mptcp5)


3. TEST SCRIPTS
---------------

3.1 Test Description
Several test scripts have been included that demonstrate basic multipath 
connections. They can be found in the 

The scripts use rsync to transfer files between the hosts and cover five
scenarios. Connections are always established from Test1, though the number
of subflows used and the direction of transfer changes. 

The scripts are executed by a controller host (currently this MUST be the VM 
host). All VMs should be started before running the script.

The test scenarios are: 

*arrows indicate direction of data
*recall that Dummynet bandwidth limits are applied to links connecting to 
Test1

  - Single-path: 
    Test1 connects to Test2 and pushes data.

                Test1                             Test2
               (CLIENT)          Routers         (SERVER)
                +----+            +---+           +----+  
                | em1| -------->  |   | --------> |em1 |
                |    |            +---+           |    |
                |    |              |             |    |
                |    |            +---+           |    |
                |    |            |   |           |    |
                +----+            +---+           +----+


  - Two-path type1: 
    Test1 is multi-homed and Test2 is single-homed. Test1 connects to Test2
    and pushes data. Expect higher throughput compared to single-subflow.

                Test1                             Test2
               (CLIENT)          Routers         (SERVER)
                +----+            +---+           +----+  
                | em1| -------->  |   | ========> |em1 |
                |    |            +---+           |    |
                |    |              |             |    |
                |    |            +---+           |    |
                | em2| -------->  |   |           |    |
                +----+            +---+           +----+


  - Two-path type2: 
    Test1 is single-homed and Test2 is multi-homed. Test1 connects to Test2
    and pushes data. Expect same throughput as single-subflow (due to 
    bottleneck).
                       bottleneck
                Test1      |                      Test2
               (CLIENT)    |     Routers         (SERVER)
                +----+     |      +---+           +----+  
                | em1| ========>  |   | --------> |em1 |
                |    |            +---+           |    |
                |    |              |             |    |
                |    |            +---+           |    |
                | em2|            |   | --------> |    |
                +----+            +---+           +----+


  - Two-path type3: 
    Test1 is multi-homed and Test2 is single-homed. Test1 connects to Test2
    and pulls data. Expect higher throughput compared to single-subflow.

                Test1                             Test2
               (CLIENT)          Routers         (SERVER)
                +----+            +---+           +----+  
                | em1| <--------  |   | <======== |em1 |
                |    |            +---+           |    |
                |    |              |             |    |
                |    |            +---+           |    |
                | em2| <--------  |   |           |    |
                +----+            +---+           +----+


  - Two-path type4: 
    Test1 is single-homed and Test2 is multi-homed. Test1 connects to Test2
    and pulls data. Expect same throughput as single-subflow (due to 
    bottleneck).
                       bottleneck
                Test1      |                      Test2
               (CLIENT)    |     Routers         (SERVER)
                +----+     |      +---+           +----+  
                | em1| <========  |   | <-------- |em1 |
                |    |            +---+           |    |
                |    |              |             |    |
                |    |            +---+           |    |
                | em2|            |   | <-------- |    |
                +----+            +---+           +----+


  - Four-path type1: 
    Both hosts are multi-homed. Test1 connects to Test2 and pushes data. Note
    that there are a total of four subflows as the implementation will create
    a mesh of connections by default. See Section 3.5 for notes on this test.

                       bottleneck
                Test1      |                      Test2
               (CLIENT)    |     Routers         (SERVER)
                +----+     |      +---+           +----+  
                | em1| ========>  |   | ========> |em1 |
                |    |            +---+           |    |
                |    |             | |            |    |
                |    |            +---+           |    |
                | em2| ========>  |   | ========> |    |
                +----+     |      +---+           +----+
                           |
                       bottleneck


  - Four-path type2: 
    Both hosts are multi-homed. Test1 connects to Test2 and pulls data. Note
    that there are a total of four subflows as the implementation will create
    a mesh of connections by default. See Section 3.5 for notes on this test.

                       bottleneck
                Test1      |                      Test2
               (CLIENT)    |     Routers         (SERVER)
                +----+     |      +---+           +----+  
                | em1| <========  |   | <======== |em1 |
                |    |            +---+           |    |
                |    |             | |            |    |
                |    |            +---+           |    |
                | em2| <========  |   | <======== |    |
                +----+     |      +---+           +----+
                           |
                       bottleneck


3.2 Using the Test Scripts
The test scripts take a test configuration as an argument. The test 
configuration scripts are used to set test-specific variables. Note that while
running the scripts, an error "Argument list too long" may appear. This error 
will not affect the test and can be ignored.

Run using:
  ./test_controller.sh <test_config.sh>

Test script:
  test_controller.sh  

Test configuration scripts:
  singlepath.sh
  twopathtype1.sh
  twopathtype2.sh
  twopathtype3.sh
  twopathtype4.sh
  fourpathtype1.sh
  fourpathtype2.sh  

Within the configuration scripts are options to enable tcpdump and siftr. These
are disabled by default to save space. Tcpdump files are stored on Test1, while
siftr is run on both hosts.


3.3 Viewing Per-subflow Statistics
The test scripts will only display the average throughput of the connection,
which is the sum of the individual subflows. Per-subflow statistics can be 
viewed on a live interface using IPAudit (pre-installed on the router VMs), or 
by processing the '.pcap' and '.log' files generated when tcpdump and siftr 
are enabled. Wireshark [2] and tcptrace [3] are useful for examining the pcap 
files.

Please refer to the applicable documentation as use of these programs is out 
of scope for this document.


3.4 Potential Starving of Subflow Send Buffers 
Four-subflow connections should provide higher throughput than a single-subflow 
connection, however this is not the case. A possible reason is the combination 
of simple scheduling and an undersized send buffer starves the subflows of data 
to send. This has yet to be investigated further.


4. REFERENCES
-------------

  [1] VirtualBox, https://www.virtualbox.org/
  [2] Wireshark, https://www.wireshark.org/
  [3] tcptrace, http://www.tcptrace.org/
  [4] IPAudit, http://ipaudit.sourceforge.net/index.html


5. ABOUT
--------

5.1 Links
This software was developed at Swinburne University's Centre for Advanced 
Internet Architectures, under the umbrella of the NewTCP research project. 
More information on the project is available at:
    http://caia.swin.edu.au/urp/newtcp/

The FreeBSD MPTCP implementation homepage can be found at:
    http://caia.swin.edu.au/urp/newtcp/mptcp


5.2 Development Team
This FreeBSD MPTCP implementation was first released in 2013 by the Multipath
TCP research project at Swinburne University of Technology's Centre for
Advanced Internet Architectures (CAIA), Melbourne, Australia. The members
of this project team are:

Lead developer:              Nigel Williams       (njwilliams@swin.edu.au)
Technical advisor/developer: Lawrence Stewart    (lastewart@swin.edu.au)
Project leader:              Grenville Armitage  (garmitage@swin.edu.au)


5.3 Acknowledgements
This project has been made possible in part by grants from:
  o The FreeBSD Foundation   
  o The Cisco University Research Program Fund, at Community Foundation Silicon 
    Valley



