-------------------------------------------------------------------------------
Centre for Advanced Internet Architectures,
Swinburne University of Technology,
Melbourne, Australia

15 October, 2015
Multipath TCP For FreeBSD Kernel Patch v0.51

mptcp-readme-v0.51.txt
Author: Nigel Williams <njwilliams@swin.edu.au>
-------------------------------------------------------------------------------

This document provides an overview of the v0.51 release of MPTCP for FreeBSD.

Other Documents in this Release
  README-Installation
  README-Testing
  mptcp-changelog-v0.51.txt

The v0.51 MPTCP kernel patch is applied against
  Repository: http://hg-beta.freebsd.org/base
  Branch: freebsd-head
  changeset: a5a383383dcb


Table of Contents

  1. OVERVIEW
     1.1 MPTCP Background
     1.2 Release Notes
     1.3 Licence
     
  2. INSTALLATION
     2.1 Installation Options
     2.2 MPTCP Hosts and Test Topology

  3. IMPLEMENTATION DETAILS
     3.1 Changes to the kernel
     3.2 Capabilities and Features
     3.3 Current Limitations
     3.4 Known Issues

  4. RUN-TIME CONFIGURATION
     4.1 Configuration Parameters
     4.2 Routing Requirements

  5. REFERENCES
     5.1 References
     5.2 Related Reading

  6. ABOUT
     5.1 Links
     5.2 Development Team
     5.3 Acknowledgements


1. OVERVIEW
-----------

1.1 MPTCP Background
RFC6824 [1] proposes extensions to TCP [2] whereby multiple addresses (and
potentially paths) can be used over a single TCP connection. This is referred
to as 'Multipath TCP'. The extension is designed to maintain compatibility 
with existing TCP Socket APIs and is therefore backwards-compatible with 
existing TCP applications. It is recommended that the reader should become
familiar with the Multipath TCP RFC before attempting to use the multipath
kernel.

At the time of writing, the Linux reference implementation is available at
[3] and [4]. At least two commercial implementations also exist - in Citrix 
Netscaler and Apple iOS. An implementation for Oracle Solaris is under 
development.


1.2 Release Notes
This release of the Multipath Kernel is a work-in-progress and should be 
considered for experimental/testing use only. The release is not fully 
compliant with RFC 6824. The kernel is built without optimisations and some 
options (e.g INET6, IPSec) disabled. Some debugging statements are printed to 
the system console and cannot be turned off. See Section 3 for specific 
details on the current capabilities.

We recommend reading the documentation in full before use.

For a list of changes since the previous list, please see change log at:
  http://caia.swin.edu.au/urp/newtcp/mptcp/tools/mptcp-changelog-v0.51.txt

The following changes are expected for upcoming releases:
  o Hooks for modular coupled congestion control
  o Hooks for modular scheduling
  o Completed testing/fixes for data-level retransmit and subflow failures
  o Improved path management
  o Further improvements to increase RFC compliance
  o Defer multipath PCB creation to completion of MP_CAPABLE handshake


1.3 Licence
The FreeBSD multipath kernel patch is released under a BSD licence. Refer to 
licence headers in each source file for further details.


2. INSTALLATION
---------------

2.1 Installation Options
This documentation describes the v0.51 implementation of Multipath TCP for 
FreeBSD. It is applied as a kernel patch against revision a5a383383dcb of 
'freebsd-head' (FreeBSD 11). Instructions for acquiring the source are provided
in 'README-Installation'.

There are two additional options available to get an MPTCP-capable host 
running:
  o  Install pre-built v0.51 kernel binary
  o  Import pre-configured Virtual Machines (VMs) into VirtualBox [6]. The 
     VM images come with a v0.5 kernel pre-installed, however the newer kernel
     can be installed onto these.

The pre-built kernel binary and pre-configured VMs provide the easiest entry-
point to testing the MPTCP kernel. Steps for acquiring and installing these 
are outlined in 'README-Installation'. We recommend using these unless you 
wish to experiment by making changes to the source code itself.


2.2 MPTCP Hosts and Test Topology
As the MPTCP kernel is not yet interoperable with other MPTCP implementations,
it must be installed onto at least two different hosts. An appropriate topology
is also required in order to observe multipath behaviour.

The following topology allows for a set of basic tests to be performed that 
demonstrate multi-path connections:

                                +--------+
                                |        |
                 +--------------| Router |--------------+
                 |              |        |              |
                 |              +--------+              |
                 |                  |                   |
             +--------+             |               +--------+
             |        |             |               |        |
             | MPHost |             |               | MPHost |
             |        |             |               |        |
             +--------+             |               +--------+
                 |                  |                   |
                 |              +--------+              |
                 |              |        |              |
                 +--------------| Router |--------------+
                                |        |
                                +--------+

  MPHost: MPTCP-Enabled hosts with multiple addresses in different subnets.
  Router: Standard router configured to allow each subnet to access each 
          other subnet.

The MPTCP kernel may be installed onto physical host machines, however we 
recommend starting with the VM-based testbed described in 'README-Install'. 
Scripts for running multi-path connections over this topology are also 
provided and detailed in 'README-Testing'.


3. IMPLEMENTATION DETAILS
-------------------------

3.1 Changes to the Kernel
Enabling MPTCP support in the FreeBSD kernel required substantial changes to 
the TCP stack, in particular the TCP connection setup, input, output and 
reassembly paths. A high-level overview of some of the changes required is 
below:

  o Creation of multipath Protocol Control Block (MPPCB) and multipath Control
    Block (MPCB). SOCK_STREAM sockets that are multipath enabled will have an
    attached MPCB.

  o MPTCP subflows are attached to the MPCB as sockets within a socket - 
    'subflow sockets'.

  o Addition of several new locks (MPP_LOCK, MP_LOCK) to handle concurrent
    access to data-structures used in MPTCP connections.

  o Existing TCP-stack source files have been modified to support MPTCP
    operation. Additionally, new mptcp-specific files have been added to 
    'sys/netinet/':
        mptcp.h
        mptcp_dtrace_declare.h
        mptcp_dtrace_define.h
        mptcp_handshake.c
        mptcp_pcb.h
        mptcp_pcb.c
        mptcp_sched.h
        mptcp_subr.c
        mptcp_timer.c
        mptcp_timer.h
        mptcp_types.h
        mptcp_usrreq.c
        mptcp_var.h


3.2 Capabilities and Features
  o Compatible with standard TCP: The implementation can establish standard 
    TCP connections with non MPTCP-enabled hosts.

  o Multipath Capable: Can establish, add additional subflows to, and terminate
    a multipath session.

  o MPTCP signalling: MP_CAPABLE, MP_ADD_ADDR, MP_JOIN and DSS exchanges 
    are implemented and functional. Other options are currently parsed but not
    acted upon.

  o Basic round-robin packet scheduling has been implemented to prevent 
    subflows from being starved of data to send.

  o Basic path manager that creates a full mesh of subflow connections.

  o Selective Acknowledgement (SACK) is enabled and functional for subflow-
    level retransmissions.

  o Multi-level debugging through use of sysctl or Dtrace probes.


3.3 Current Limitations
  o TCP Segmentation Offload (TSO) disabled: 
    The implementation has been tested and debugged without TSO enabled.

  o IPSec Disabled: 
    Kernel should be compiled without IPSec (nooptions IPSEC).

  o IPv6 Disabled: 
    Provisions have been made for IPv6 support however IPv6 code paths have not
    been fully implemented as of this version. Kernel should be compiled
    without IPv6 (nooptions INET6).

  o Basic packet scheduler:
    The current packet scheduler features no 'intelligence', such as making 
    decisions based on flow statistics.

  o No buffering out-of-map packets. Packets that arrive and do not belong
    to an existing map (e.g. the packet carrying the map was lost) are 
    discarded. This can increase the number of retransmits required during a 
    multipath session.

  o Fall-back to 'infinite map' not handled:
    A fully established multipath connection will not fall back into standard 
    TCP "infinite map" mode if an error is detected. 

  o No dynamic subflow management during a connection:
    (a) The implementation will issue ADD_ADDR and JOIN signals at the start of
    a connection. It will not attempt to remove advertised addresses. 
    However stalled subflows are timed out and removed from the connection.

  o No automated path discovery, basic path management:
    (a) Addresses are not automatically discovered. They are added via a 
    sysctl variable (see usage details above). Setting this sysctl makes the  
    address available to any multipath connection that becomes established.
    (b) Addresses learnt during a connection (via the ADD_ADDR option) are 
    stored locally in the 'multipath layer', rather than in an independent, 
    globally accessible path manager.

  o No coupled congestion control:
    Coupled congestion control, as defined in [4], is not implemented.

  o Security (hmacs, etc) only at most basic level for operation:
    Hashes and keys are generated and exchanged where required, but are not 
    validated internally.

  o Only 32-Bit DSNs on the wire:
    Data sequence numbers are tracked as 64-bit values internally, but only 
    the lower 32-bits are sent over the wire.

  o Checksumming is disabled:
    MPTCP Checksumming is not implemented in this version of the patch.

  o Performance is not optimised.

  o Panics/KASSERT failure:
    Some KASSERT and panic conditions will occur and break the system to ddb.
    Connections are also susceptable to stalling as testing is ongoing.
    
  o Firewall-based routing
    Currently ipfw is used to re-route packets to the correct interface. In 
    future releases, routing will involve using multiple FIBs and and route 
    management within the MP connection.


3.4 Known Issues
There are several known issues that occur during connections:
  o Lock order reversal on passive opens. A LOR between the MPP_LOCK and the
    INP_INFO_WLOCK occurs at the end of a successful handshake on the passive
    opener (server). This is due to the creation of a new MPPCB while holding
    the INP_INFO_WLOCK. This has been left in the current patch and should 
    disappear after an overhaul of the PCB creation code.

  o It is possible for connections to stall (standard TCP and MPTCP). The 
    cause of these stalls has yet to be investigated.
    
  o A (possible) race condition prevents release of session PCBs. Some
    connections will close but fail to free all PCBs.
    
  o A kernel panic has been observed during connection closes after stalled
    connections or connections whose PCBs have not freed correctly.
    
  o A kernel panic can occur during connection teardown for connections to 
    localhost.
    
  o Testing has been limited to the test scripts provided with the release and 
    SCP/Iperf connections with similar address configurations. Other types of 
    connections will likely cause weird behaviour, so if you do run something 
    different please note down what you are doing.
    
  o Subflow-socket send buffers can be starved due to a combination of small
    connection-level send buffer and simplistic scheduler.
 
  o Configuring sysctl for 'mp_addresses' will at times produce an error 
    "Argument list too long", however this can ignored.


4. RUN-TIME CONFIGURATION
-------------------------

4.1 Configuration Parameters
Sysctl variables that provide configuration options:

net.inet.tcp.mptcp.mp_addresses 
    
    Additional addresses are made available using this variable. A list 
    of addresses are provided as input, and these will be advertised to 
    the remote host when a multipath connection becomes established. This 
    setting can be left empty if you only wish to use a single address on 
    the local host (the default address, or master subflow address, is 
    determined by the route table).

    For example, on a host with two addresses: 192.168.0.10 (default gw) and 
    192.168.0.11, you can add the '.11' address to be used as an extra subflow
    in multipath connections with the following command:

        sysctl net.inet.tcp.mptcp.mp_addresses="192.168.0.11"

    In this case '.10' will act as the primary subflow, while '.11' will 
    be advertised with ADD_ADDR once multipath is established. By default the
    host receiving an ADD_ADDR will initiate the MP_JOIN.

    Multiple addresses can be added as a space delimited string:

        sysctl net.inet.tcp.mptcp.mp_addresses="192.168.0.11 10.0.0.20"

	The list of addresses can be cleared by setting a '0'

        sysctl net.inet.tcp.mptcp.mp_addresses=0

net.inet.tcp.mptcp.max_subflows

    Specifies the maximum number of subflows that can be attached to a 
    single multipath connection. The default value is 8, however the 
    implementation is currently internally limited to a maximum of two 
    subflows.

net.inet.tcp.mptcp.single_packet_maps

    Enabled by default, restricts DSN mappings to cover a single segment only.
    Setting this to '0' will enable multi-packet DSN mappings (the DSN mapping
    being present only on the first packet of the map). Recent testing has
    been performed using single-packet maps, so it is highly recommended that 
    the default setting should be used.

net.inet.tcp.override_isn

    Manually set the TCP initial sequence number (isn). The isn can be set to 
    any number greater than 0. The default value of 0 will result in normal
    randomisation. Useful for debugging sequence number issues.

net.inet.tcp.mptcp.mp_debug 

    The kernel features multi-level debugging info, the depth and class 
    of which is set using this sysctl variable. There are currently three 
    classes of debug info that can be displayed:

        MPSESSION - General session information (such as hashes and keys)
        DSMAP - data-sequence map info (e.g. map lengths etc)
        SBSTATUS - the status of the socket buffers
        REASS - reassembly-related information
        ALL - apply settings to ALL of the above classes at once

    Each of these classes has a level of verbosity, which ranges from 0 
    (no output) to 5 (fully verbose). An example of usage is shown below 
    (enables full verbosity DSMAP):

        sysctl net.inet.tcp.mptcp.mp_debug="DSMAP:5"

    In this case we use the format <class:verbosity> to enable debugging. 
    The <class:verbosity> notation causes all debugging levels up to 
    <verbosity> to be printed. I.e., "DSMAP:5" causes debugging at levels
    1-5 of DSMAP to be printed. To print a single debug level exclusively, use
    the <class:=verbosity> notation:

        sysctl net.inet.tcp.mptcp.mp_debug="DSMAP:=5"

    This prints out ONLY level five debug statements.
    To turn off debugging, the following command would be issued:
        
        sysctl net.inet.tcp.mptcp.mp_debug="DSMAP:0"

    Entering the following will print a string with the current debug 
    configuration:

        sysctl net.inet.tcp.mptcp.mp_debug

    Note that enabling mp_debug will result in many lines being printed to the
    console, which will slow down the connection dramatically. However, it may
    be useful when testing to have at least MPSESSION:1 information displayed.


4.2 Routing Requirements
The current implementation has been tested using only a single routing table. 
In such configurations, if the destination subnet is not directly connected to 
any of the local interfaces, packets will be sent via the default interface.
For example, consider a host with the following route table:

                Destination        Gateway           Netif
                default            10.0.2.2          em0
                172.16.1.0         link#2            em1
                172.16.2.0         link#3            em2

In this case, an outbound packet (source: 172.16.2.2, dest: 172.16.3.2) would 
egress via interface em0 towards 10.0.2.2 (the default gateway). This may lead 
to an asymmetric return path. 

A static route is not useful in this case, as we may want to reach the same
destination network via different local interfaces. We thus use ipfw source-
based forwarding rules to ensure that packets are transmitted via the correct 
interface (the correct interface being the one that matches the source address 
of the packet). For a description relating to the example testbed, refer to 
'README-Installation'. 

The use of ipfw to perform source-based routing is a temporary measure until 
more suitable route management is added to the implementation.


4.3 Saving Core Dumps
The test VMs will break to debugger in case of a panic. Save a core dump using
the following commands:
  
  # Save the core
  call doadump
  # Reboot
  reboot

The core files are saved in /var/crash/ by default.


5. REFERENCES
-------------

5.1 References

  [1] Ford, A. et al, "TCP Extensions for Multipath Operation with 
      Multiple Addresses", RFC 6824, January 2013.
  [2] Postel, J., "Transmission Control Protocol", RFC 793, September 1981.
  [3] "MultiPath TCP - Linux Kernel implementation", Homepage, 
      http://multipath-tcp.org/, October 2015
  [4] "Multipath TCP - Github", https://github.com/multipath-tcp/, 
      October 2015
  [5] "Apple seems to also believe in Multipath TCP", Blog Entry,
      http://perso.uclouvain.be/olivier.bonaventure/blog/html/2013/09/18/mptcp.html
  [6] Oracle VirtualBox, https://www.virtualbox.org
  [7] The Dummynet Projet, http://info.iet.unipi.it/~luigi/dummynet/


5.2 Related Reading

  o Raiciu, C. et al, "Coupled Congestion Control for Multipath Transport
    Protocols", RFC 6356, October 2011.
  o Raiciu, C. et al, "How Hard Can It Be? Designing and Implementing a 
    Deployable Multipath TCP", USENIX Symposium of Networked Systems Design 
    and Implementation (NSDI'12), San Jose (CA), 2012.


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


