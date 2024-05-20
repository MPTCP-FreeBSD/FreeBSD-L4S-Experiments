588	AUE_NULL	STD {
		int aqm_test_get_state(
			_Out_ struct state *sf1_state
            
		);
	}



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


/* Structure for DQN state information */
struct state {
    int pipe;      /* Unacknowledged bytes in flight */
    int wnd;  /* Window size - min of cwnd and swnd */
    int srtt;      /* Smoothed round trip time */
    int rttvar;    /* Variance in round trip time */
};


int sys_aqm_test_get_state(struct thread *td, struct aqm_test_get_state_args *uap)
{
    struct state *se = NULL;


    // Allocate memory for the struct
    se = malloc(sizeof(struct state), M_DQN, M_NOWAIT | M_ZERO);

    se->pipe=18;
    se->wnd=19;
    se->srtt=20;
    se->rttvar=21;

    copyout(&se, uap->sf1_state, sizeof(struct state));

	return (0);
}





#include <stdio.h>
#include <sys/syscall.h>
#include <unistd.h>


/* Structure for DQN state information */
struct state {
    int pipe;      /* Unacknowledged bytes in flight */
    int wnd;  /* Window size - min of cwnd and swnd */
    int srtt;      /* Smoothed round trip time */
    int rttvar;    /* Variance in round trip time */
};



int main()
{

    struct state sf1_state;


    int err = syscall(588, &sf1_state);


    printf("System call  %d\n", sf1_state.pipe);
    printf("System call  %d\n", sf1_state.wnd);
    printf("System call  %d\n", sf1_state.srtt);
    printf("System call  %d\n", sf1_state.rttvar);


    return 0;
}






