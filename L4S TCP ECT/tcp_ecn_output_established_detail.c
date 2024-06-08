The function `tcp_ecn_output_established` in FreeBSD's TCP implementation handles the Explicit Congestion Notification (ECN) marking for TCP packets when a connection is in the established state. This function determines the appropriate ECN codepoint to set in the IP header based on the current state of the TCP connection and the type of packet being sent.

### Explanation of the Function

Here's a step-by-step explanation of what the function does:

1. **Initialize Variables**:
   - `ipecn` is initialized to `IPTOS_ECN_NOTECT` (which means no ECN).
   - `newdata` is a boolean flag that determines if the current packet contains new data that hasn't been sent before.

2. **Check if Packet Contains New Data**:
   - The function checks if the packet length is greater than 0, if the sequence number of the next byte to be sent (`tp->snd_nxt`) is greater than or equal to the maximum sequence number sent so far (`tp->snd_max`), and if the packet is not a retransmission (`!rxmit`).
   - It also checks if the packet is not a forced data packet (used for window probes), which would have a length of 1 byte.

3. **Mark Data Packets with ECN**:
   - If the packet contains new data, the function checks if the connection should use `ECT1` or `ECT0` for marking.
   - If the `TF2_ECN_USE_ECT1` flag is set, it sets the `ipecn` to `IPTOS_ECN_ECT1` and increments the `tcps_ecn_sndect1` statistic.
   - Otherwise, it sets the `ipecn` to `IPTOS_ECN_ECT0` and increments the `tcps_ecn_sndect0` statistic.

4. **Reply with Proper ECN Notifications**:
   - If the `TF2_ACE_PERMIT` flag is set, the function clears the ECN-related TCP flags (`TH_AE`, `TH_CWR`, `TH_ECE`) and sets them based on the `t_rcep` field.
   - If the connection hasn't yet permitted ECN (`TF2_ECN_PERMIT`), it processes the final ACK of the three-way handshake (3WHS) and sets the `TF2_ECN_PERMIT` flag.
   - Otherwise, if the packet contains new data and the `TF2_ECN_SND_CWR` flag is set, it sets the `TH_CWR` flag and clears the `TF2_ECN_SND_CWR` flag.
   - If the `TF2_ECN_SND_ECE` flag is set, it sets the `TH_ECE` flag.

5. **Return the ECN Codepoint**:
   - The function returns the appropriate ECN codepoint to be used in the IP header.

### Integration with Your Situation

To set ECN flags to `ECN_ECT1` when using DCTCP in FreeBSD, you can leverage this function by ensuring the `TF2_ECN_USE_ECT1` flag is set in the TCP control block (`tcpcb`) for connections using DCTCP. 

### Implementation

Here's how you might modify the relevant parts of the code to ensure `ECN_ECT1` is used with DCTCP:

1. **Set `TF2_ECN_USE_ECT1` for DCTCP**:
   - In the TCP connection setup or configuration code, set the `TF2_ECN_USE_ECT1` flag if the congestion control algorithm is DCTCP.

2. **Ensure `tcp_ecn_output_established` Uses This Flag**:
   - Ensure the function `tcp_ecn_output_established` is called appropriately in the TCP output path.

Here's an example of how you might set the flag during connection setup:

```c
#include <netinet/tcp_var.h>
#include <netinet/tcp.h>
#include <netinet/in_pcb.h>

// Example code to set TF2_ECN_USE_ECT1 during connection setup
void tcp_connection_setup(struct tcpcb *tp)
{
    // Check if the congestion control algorithm is DCTCP
    if (tp->t_ccstate->cc_alg == &dctcp_cc_algo) {
        tp->t_flags2 |= TF2_ECN_USE_ECT1;
    }
}
```

### Summary

- The function `tcp_ecn_output_established` handles setting ECN flags for TCP packets.
- To set the ECN flags to `ECN_ECT1` for DCTCP, you need to ensure the `TF2_ECN_USE_ECT1` flag is set in the `tcpcb` structure.
- Modify the connection setup code to set this flag when DCTCP is used as the congestion control algorithm.

By following these steps and ensuring the `TF2_ECN_USE_ECT1` flag is set appropriately, you can configure FreeBSD to set ECN flags to `ECN_ECT1` for connections using DCTCP.

### Next Steps

**a.** Modify the connection setup code to set `TF2_ECN_USE_ECT1` for DCTCP and test it.
**b.** Review the TCP output path to ensure `tcp_ecn_output_established` is called correctly and the ECN flags are set as expected.