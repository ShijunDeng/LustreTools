/*
 * GPL HEADER START
 *
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License version 2 for more details (a copy is included
 * in the LICENSE file that accompanied this code).
 *
 * You should have received a copy of the GNU General Public License
 * version 2 along with this program; If not, see
 * http://www.sun.com/software/products/lustre/docs/GPLv2.pdf
 *
 * Please contact Storage Systems Research Center, Computer Science Department,
 * University of California, Santa Cruz (www.ssrc.ucsc.edu) if you need
 * additional information or have any questions.
 *
 * GPL HEADER END
 */
/*
 * This file is NOT part of Lustre.
 * Lustre is a trademark of Sun Microsystems, Inc.
 */
/*
 * Header file for Metric routines
 */
/**
*声明：借鉴了ASCAR源码的部分思想
*/
#ifndef SMART_QOS_H_
#define SMART_QOS_H_

/* We work with kernel only */
#ifdef __KERNEL__
# include <linux/types.h>
# include <linux/time.h>
# include <asm/param.h>
# include <libcfs/libcfs.h>
# include <linux/delay.h>
#else /* __KERNEL__ */
# define HZ 100
# define ONE_MILLION 1000000
# include <liblustre.h>
#endif

#define EWMA_ALPHA_INV (8)

/**
 * For tracking the exponentially-weighted moving average of a timeval. Note
 * that we can't do float point div in kernel, so actually we are tracking
 * ea = ewma * alpha. You should divide ea with alpha to get the real ewma.
 * 考虑到有的CPU不支持float,这里处理为整数(取其倒数),计算的时候相应变化一下即可
 */
struct time_ewma {
	__u64          alpha_inv;//初始化值为8
	__u64          ea;
	struct timeval last_time;
};
/* We can't do float point div, so we are tracking
 * ea = ewma * alpha = ewma / alpha_inv
 */

struct qos_rule_t {
	__u64 ack_ewma_lower;
	__u64 ack_ewma_upper;
	__u64 send_ewma_lower;
	__u64 send_ewma_upper;
	unsigned int rtt_ratio100_lower;
	unsigned int rtt_ratio100_upper;
	int m100;
	int b100;
	unsigned int tau;
	int used_times;

	__u64 ack_ewma_avg;
	__u64 send_ewma_avg;
	unsigned int rtt_ratio100_avg;
};

struct qos_data_t {
	spinlock_t       lock;
	struct time_ewma ack_ewma;
	struct time_ewma sent_ewma;
	int              rtt_ratio100;
	long             smallest_rtt;
	int              max_rpc_in_flight100;
	struct timeval   last_mrif_update_time;
	int              min_gap_between_updating_mrif;
	int              rule_no;
	/* Following fields are for calculating I/O bandwidth,
	 * 0 for read, 1 for write */
	long             last_req_sec[2];       /* second of last request we received */
	__u64            bw_last_sec[2];        /* bw of last sec */
	__u64            sum_bytes_this_sec[2]; /* cumulative bytes read within this sec */
	/* For throttling support */
	unsigned int     min_usec_between_rpcs;
	struct timeval   last_rpc_time;
	struct qos_rule_t *rules;
};

static inline __u64 qos_get_ewma_usec(const struct time_ewma *ewma) {
	return ewma->ea / ewma->alpha_inv;
}

int parse_qos_rules(const char *buf, struct qos_data_t *qos);

/* No user space test cases for them yet */
/* Lock of qos must be held. op == 0 for read, 1 for write */
static inline void calc_bandwidth(struct qos_data_t *qos, int op, int bytes_transferred) {
	struct timeval now;

	if (op != 0 && op != 1)
		return;

	do_gettimeofday(&now);
	if (likely(now.tv_sec == qos->last_req_sec[op])) {
		qos->sum_bytes_this_sec[op] += bytes_transferred;
	} else if (likely(now.tv_sec == qos->last_req_sec[op] + 1)) {
		qos->bw_last_sec[op] = qos->sum_bytes_this_sec[op];
		qos->last_req_sec[op] = now.tv_sec;
		qos->sum_bytes_this_sec[op] = bytes_transferred;
	} else if (likely(now.tv_sec > qos->last_req_sec[op] + 1)) {
		qos->bw_last_sec[op] = 0;
		qos->last_req_sec[op] = now.tv_sec;
		qos->sum_bytes_this_sec[op] = bytes_transferred;
	}
	/* Ignore cases when now.tv_sec < qos->last_req_sec */
}

#ifndef __KERNEL__
static inline void udelay(long u) {
	(void)u;
}
static inline void usleep_range(long u, long v) {
	(void)u;
	(void)v;
}
static inline void msleep(long u) {
	(void)u;
}
#endif

static inline void qos_throttle(struct qos_data_t *qos) {
	struct timeval now;
	long           usec_since_last_rpc;
	long           need_sleep_usec = 0;

	spin_lock(&qos->lock);
	if (0 == qos->min_usec_between_rpcs)
		goto out;

	do_gettimeofday(&now);
	usec_since_last_rpc = cfs_timeval_sub(&now, &qos->last_rpc_time, NULL);
	if (usec_since_last_rpc < 0) {
		usec_since_last_rpc = 0;
	}
	if (usec_since_last_rpc < qos->min_usec_between_rpcs) {
		need_sleep_usec = qos->min_usec_between_rpcs - usec_since_last_rpc;
	}
	qos->last_rpc_time = now;
out:
	spin_unlock(&qos->lock);
	if (0 == need_sleep_usec) {
		return;
	}

	/* About timer ranges:
	   Ref: https://www.kernel.org/doc/Documentation/timers/timers-howto.txt */
	if (need_sleep_usec < 1000) {
		udelay(need_sleep_usec);
	} else if (need_sleep_usec < 20000) {
		usleep_range(need_sleep_usec - 1, need_sleep_usec);
	} else {
		msleep(need_sleep_usec / 1000);
	}
}

#endif /* METRIC_H_ */
