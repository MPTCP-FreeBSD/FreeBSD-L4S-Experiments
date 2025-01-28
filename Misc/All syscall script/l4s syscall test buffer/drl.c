#include <sys/param.h>
#include <sys/sysent.h>
#include <sys/sysproto.h>
#include <sys/kernel.h>
#include <sys/proc.h>
#include <sys/syscallsubr.h>

#include <sys/types.h>
#include <sys/systm.h>

#include <sys/malloc.h>


static MALLOC_DEFINE(M_DQN, "DQN scheduler data", "Per connection DQN scheduler data.");
static MALLOC_DEFINE(M_DRL_PKT_BUFFER, "DRL pkt buffer", "DRL pkt buffer");


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

int sys_drl_update_prob(struct thread *td, struct drl_update_prob_args *uap)
{
	int prob = uap->prob;
    printf("Value of int64_t probability: %d \n", prob);
    return (0);
}

int sys_drl_get_buffer(struct thread *td, struct drl_get_buffer_args *uap)
{
    struct data *pb = NULL;
    int size = 1;


    // Allocate memory for the struct
    pb = malloc(sizeof(struct data) * size, M_DRL_PKT_BUFFER, M_NOWAIT|M_ZERO);

    pb->drop_prob = 1345;
    pb->current_qdelay = 2534;
    pb->qdelay_old = 343;
    pb->avg_dq_time = 4534;
    pb->tot_bytes = 51234;
    pb->tot_pkts = 7123;
    pb->len_bytes = 8132;
    pb->dq_count = 9123;
    pb->drops = 1012312;


    printf("System call  %u\n", pb->drop_prob);
    printf("System call  %u\n", pb->current_qdelay);
    printf("System call  %u\n", pb->qdelay_old);
    printf("System call  %u\n", pb->avg_dq_time);
    printf("System call  %lu\n", pb->tot_pkts);
    printf("System call  %lu\n", pb->tot_bytes);
    printf("System call  %u\n", pb->len_bytes);
    printf("System call  %u\n", pb->dq_count);
    printf("System call  %u\n", pb->drops);
    copyout(pb, uap->data, sizeof(struct data) * size);
	copyout(&size, uap->size, sizeof(int));

    free(pb, M_DRL_PKT_BUFFER);

	return (0);
}