/*
 * Extract a packet from the head of sub-queue 'q'
 * Return a packet or NULL if the queue is empty.
 * If getts is set, also extract packet's timestamp from mtag.
 */
__inline static struct mbuf *
fq_pie_extract_head(struct fq_pie_flow *q, aqm_time_t *pkt_ts,
	struct fq_pie_si *si, int getts)
{
	struct mbuf *m;
	m = q->mq.head;
	if (m == NULL)
		return m;
	q->mq.head = m->m_nextpkt;

	fq_update_stats(q, si, -m->m_pkthdr.len, 0);

	if (si->main_q.ni.length == 0) /* queue is now idle */
			si->main_q.q_time = V_dn_cfg.curr_time;

	if (getts) {
		/* extract packet timestamp*/
		struct m_tag *mtag;
		mtag = m_tag_locate(m, MTAG_ABI_COMPAT, DN_AQM_MTAG_TS, NULL);
		if (mtag == NULL){
			D("PIE timestamp mtag not found!");
			*pkt_ts = 0;
		} else {
			*pkt_ts = *(aqm_time_t *)(mtag + 1);
			m_tag_delete(m,mtag); 
		}
	}
	return m;
}