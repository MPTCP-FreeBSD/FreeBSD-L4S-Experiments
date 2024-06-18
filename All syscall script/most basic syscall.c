588	AUE_NULL	STD {
		int set_cwnd(
			_In_ int cwnd
		);
	}
589	AUE_NULL	STD {
		int get_cwnd(void);
	}
===========================================================================================
#include <sys/param.h>
#include <sys/sysent.h>
#include <sys/sysproto.h>
#include <sys/kernel.h>
#include <sys/proc.h>
#include <sys/syscallsubr.h>

#include <sys/types.h>
#include <sys/systm.h>

static int _cwnd = 0;

int sys_set_cwnd(struct thread *td, struct set_cwnd_args *uap)
{
	_cwnd = uap->cwnd;
	return 0;
}

int sys_get_cwnd(struct thread *td, struct get_cwnd_args *uap)
{
	td->td_retval[0] = _cwnd;
	return 0;
}
===========================================================================================

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <errno.h>

#define SYS_set_cwnd 588
#define SYS_get_cwnd 589

int main() {
    int cwnd_val;
    int result;

    // Set cwnd
    cwnd_val = 42; // Example value to set
    result = syscall(SYS_set_cwnd, cwnd_val);
    if (result == -1) {
        perror("Error in set_cwnd");
        exit(EXIT_FAILURE);
    }
    printf("Successfully set cwnd to %d\n", cwnd_val);

    // Get cwnd
    result = syscall(SYS_get_cwnd);
    if (result == -1) {
        perror("Error in get_cwnd");
        exit(EXIT_FAILURE);
    }
    printf("Current cwnd value: %d\n", result);

    return 0;
}

