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
    unsigned int drop_prob;
    unsigned int current_qdelay;
    unsigned int qdelay_old;
    unsigned int avg_dq_time;
    unsigned int tot_bytes;
    unsigned int drops;
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

    pb->drop_prob = 1;
    pb->current_qdelay = 2;
    pb->qdelay_old = 3;
    pb->avg_dq_time = 4;
    pb->tot_bytes = 5;
    pb->drops = 6;


    printf("System call  %u\n", pb->drop_prob);
    printf("System call  %u\n", pb->current_qdelay);
    printf("System call  %u\n", pb->qdelay_old);
    printf("System call  %u\n", pb->avg_dq_time);
    printf("System call  %u\n", pb->tot_bytes);
    printf("System call  %u\n", pb->drops);
    copyout(pb, uap->data, sizeof(struct data) * size);
	copyout(&size, uap->size, sizeof(int));

    free(pb, M_DRL_PKT_BUFFER);

	return (0);
}