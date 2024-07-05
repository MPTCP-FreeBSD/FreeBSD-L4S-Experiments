#include <stdio.h>
#include <stdlib.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

// Define the struct data as specified
struct data {
	uint32_t    flows_cnt;	/* number of flows */
	uint32_t    limit;	/* hard limit of L4S queue size*/
	uint32_t    quantum;
    uint64_t    tot_pkts;	/* statistics counters  */
	uint64_t    tot_bytes;
	uint32_t    length;		/* Queue length, in packets */
	uint32_t    len_bytes;	/* Queue length, in bytes */
	uint32_t    drops;
    uint16_t    max_ecnth;	/*AQM Max ECN Marking Threshold (default: 10%) */
	uint16_t	alpha;			/* (default: 1/8) */
	uint16_t	beta;			/* (default: 1+1/4) */
    uint32_t	burst_allowance;
	uint32_t	drop_prob;
	uint32_t	current_qdelay;
	uint32_t	qdelay_old;
	uint64_t	accu_prob;
	uint32_t	avg_dq_time;
	uint32_t	dq_count;
};

// System call numbers (you'll need to replace these with the actual syscall numbers)
#define SYS_DRL_UPDATE_PROB 588
#define SYS_DRL_GET_BUFFER  589

int drl_update_prob(int prob) {
    return syscall(SYS_DRL_UPDATE_PROB, prob);
}

int drl_get_buffer(struct data *data, int *size) {
    return syscall(SYS_DRL_GET_BUFFER, data, size);
}

int main() {
    int prob = 10; // Example probability value
    int ret = drl_update_prob(prob);
    if (ret < 0) {
        fprintf(stderr, "Error calling drl_update_prob: %s\n", strerror(errno));
        return 1;
    }
    printf("drl_update_prob returned: %d\n", ret);

    struct data buffer;
    int size = sizeof(buffer);
    ret = drl_get_buffer(&buffer, &size);
    if (ret < 0) {
        fprintf(stderr, "Error calling drl_get_buffer: %s\n", strerror(errno));
        return 1;
    }
    printf("drl_get_buffer returned: %d\n", ret);
    printf("Buffer details:\n");
    printf("drop_prob: %u\n", buffer.drop_prob);
    printf("current_qdelay: %d\n", buffer.current_qdelay);
    printf("qdelay_old: %d\n", buffer.qdelay_old);
    printf("avg_dq_time: %u\n", buffer.avg_dq_time);
    printf("tot_bytes: %u\n", buffer.tot_bytes);
    printf("drops: %u\n", buffer.drops);

    return 0;
}
