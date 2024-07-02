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


struct pkt {
	u_int		cwnd;
	int		smoothed_rtt;
	int		cong_events;

	u_int		laddr;
	u_int		lport;
};

int sys_drl_update_prob(struct thread *td, struct drl_update_prob_args *uap)
{
	int64_t prob = uap->prob;
    printf("Value of int64_t probability: %qd\n", prob);
}

int sys_drl_get_buffer(struct thread *td, struct drl_get_buffer_args *uap)
{
    struct pkt *pb = NULL;
    int size = 2;


    // Allocate memory for the struct
    pb = malloc(sizeof(struct pkt) * size, M_DRL_PKT_BUFFER, M_NOWAIT|M_ZERO);


    copyout(pb, uap->data, sizeof(struct pkt) * size);
	uap->size = size;

    printf("System call  %d\n", pb->cwnd);
    printf("System call  %d\n", pb->smoothed_rtt);
    printf("System call  %d\n", pb->cong_events);
    printf("System call  %d\n", pb->laddr);
    printf("System call  %d\n", pb->lport);

    free(pb, M_DRL_PKT_BUFFER);

	return (0);
}

