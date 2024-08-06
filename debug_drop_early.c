#include <stdio.h> // Include this at the top of your file if it's not already included

__inline static int
drop_early(struct pie_status *pst, uint32_t qlen)
{
    struct dn_aqm_pie_parms *pprms;
    pprms = pst->parms;

    printf("Entering drop_early function:\n");
    printf("Queue length (qlen): %u\n", qlen);
    printf("Old queue delay (pst->qdelay_old): %u\n", pst->qdelay_old);
    printf("Reference delay (pprms->qdelay_ref): %u\n", pprms->qdelay_ref);
    printf("Drop probability (pst->drop_prob): %u\n", pst->drop_prob);

    /* queue is not congested */
    if ((pst->qdelay_old < (pprms->qdelay_ref >> 1)
        && pst->drop_prob < PIE_MAX_PROB / 5 )
        ||  qlen <= 2 * MEAN_PKTSIZE) {
        printf("Condition met for ENQUE:\n");
        printf("pst->qdelay_old < (pprms->qdelay_ref >> 1): %d\n", pst->qdelay_old < (pprms->qdelay_ref >> 1));
        printf("pst->drop_prob < PIE_MAX_PROB / 5: %d\n", pst->drop_prob < PIE_MAX_PROB / 5);
        printf("qlen <= 2 * MEAN_PKTSIZE: %d\n", qlen <= 2 * MEAN_PKTSIZE);
        return ENQUE;
    }

    if (pst->drop_prob == 0) {
        pst->accu_prob = 0;
        printf("Drop probability is 0. Resetting accumulated probability.\n");
    }

    /* increment accu_prob */
    if (pprms->flags & PIE_DERAND_ENABLED) {
        pst->accu_prob += pst->drop_prob;
        printf("De-randomize option enabled. Updated accumulated probability (pst->accu_prob): %llu\n", (unsigned long long) pst->accu_prob);

        /* De-randomize option 
         * if accu_prob < 0.85 -> enqueue
         * if accu_prob > 8.5 -> drop
         * between 0.85 and 8.5 || !De-randomize --> drop on prob
         * 
         * (0.85 = 17/20 ,8.5 = 17/2)
         */
        if (pst->accu_prob < (uint64_t) (PIE_MAX_PROB * 17 / 20)) {
            printf("Accumulated probability (pst->accu_prob) < 0.85 * PIE_MAX_PROB. Enqueue.\n");
            return ENQUE;
        }
        if (pst->accu_prob >= (uint64_t) (PIE_MAX_PROB * 17 / 2)) {
            printf("Accumulated probability (pst->accu_prob) >= 8.5 * PIE_MAX_PROB. Drop.\n");
            return DROP;
        }
    }

    /* Randomize option */
    if (random() < pst->drop_prob) {
        pst->accu_prob = 0;
        printf("Random decision to drop (random() < pst->drop_prob). Resetting accumulated probability.\n");
        return DROP;
    }

    printf("Default case: Enqueue.\n");
    return ENQUE;
}
