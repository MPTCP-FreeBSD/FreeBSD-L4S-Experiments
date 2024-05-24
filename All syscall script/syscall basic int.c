588	AUE_NULL	STD {
		int aqm_test_get_state(
			_Out_ int *ref,
            _Out_ int *old_prob,
            _Out_ int *ecn

            
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



int sys_aqm_test_get_state(struct thread *td, struct aqm_test_get_state_args *uap)
{

    int ref = 991;
    int old_prob = 7328;
    int ecn = 8532;    


	/* Copy values from kernel to userland */
    copyout(&ref, uap->ref, sizeof(int));
    copyout(&old_prob, uap->old_prob, sizeof(int));
    copyout(&ecn, uap->ecn, sizeof(int));
	
	return (1);

}





#include <stdio.h>
#include <sys/syscall.h>
#include <unistd.h>


int main()
{
    int ref;
    int old_prob;
    int ecn;

    int err = syscall(588, &ref, &old_prob, &ecn);


    
    printf("System call  %d\n", ref);
    printf("System call  %d\n", old_prob);
    printf("System call  %d\n", ecn);

    return 0;
}


