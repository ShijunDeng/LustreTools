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
 * Copyright (c) 2013, 2014, 2015, University of California, Santa Cruz, CA, USA.
 * All rights reserved.
 * Developers:
 *   Yan Li <yanli@cs.ucsc.edu>
 */
/*
 * This file is NOT part of Lustre.
 * Lustre is a trademark of Sun Microsystems, Inc.
 */
/*
 * qos_rules.c
 *
 *  Created on: Nov 14, 2013
 *      Author: yanli
 */
#ifndef __KERNEL__
  #include <stdio.h>
  #include "kernel-test-primitives.h"
  #include <string.h>
#endif
#include <metric.h>

/* Parse qos_rules in buf and store the result to qos.
 *
 * Pre-condition:
 *   1. qos must be initialized and qos->lock MUST be held before calling this function!
 *   2. exisiting rules in qos->rules will be freed
 *   3. buf must be NULL-terminated or sscanf may overread it.
 *
 * Return value:
 *  0: success
 *  other value: error code. On error, qos->rules is NULL and qos->rule_no is 0.
 */
int parse_qos_rules(const char *buf, struct qos_data_t *qos)
{
	int new_rule_no = 0;
	int rules_per_sec = 0;
	int rc;
	int i;
	const char *p = buf;
	int n;
	const size_t rule_size = sizeof(*(qos->rules));
	struct qos_rule_t *r;

	/* handle "0\n" and "0" */
	if (strlen(p) <= 2 && '0' == *p) {
		if (qos->rules) {
			LIBCFS_FREE(qos->rules, qos->rule_no * rule_size);
		}
		qos->rule_no = 0;
		qos->rules = NULL;
		return 0;
	}

	rc = sscanf(p, "%d,%d\n%n", &new_rule_no, &rules_per_sec, &n);
	if (2 != rc) {
		CWARN("Input data error, can't read new_rule_no\n");
		return -EINVAL;
	}
	if (0 == new_rule_no || 0 == rules_per_sec) {
		if (qos->rules) {
			LIBCFS_FREE(qos->rules, qos->rule_no * rule_size);
		}
		qos->rule_no = 0;
		qos->rules = NULL;
		return 0;
	}
	p += n;
	if (qos->rules) {
		LIBCFS_FREE(qos->rules, qos->rule_no * rule_size);
	}
	qos->rule_no = new_rule_no;
	qos->min_gap_between_updating_mrif = 1000000 / rules_per_sec;
	LIBCFS_ALLOC_ATOMIC(qos->rules, new_rule_no * rule_size);
	if (!qos->rules) {
		CWARN("Can't allocate enough mem for %d rules\n", new_rule_no);
		return -ENOMEM;
	}
	memset(qos->rules, 0, new_rule_no * rule_size);

	for (i = 0; i < new_rule_no; i++) {
		r = &qos->rules[i];
		/* Don't put \n at the end of sscanf format str
		   because there may be other unknown fields there,
		   which will be discarded later */
		rc = sscanf(p, "%llu,%llu,%llu,%llu,%u,%u,%d,%d,%u%n",
		                &r->ack_ewma_lower,  &r->ack_ewma_upper,
		                &r->send_ewma_lower, &r->send_ewma_upper,
		                &r->rtt_ratio100_lower, &r->rtt_ratio100_upper,
		                &r->m100, &r->b100, &r->tau, &n);
		p += n;
		if (rc != 9) {
			CWARN("QoS rule parsing error, rc = %d\n", rc);
			LIBCFS_FREE(qos->rules, qos->rule_no * rule_size);
			qos->rules = NULL;
			qos->rule_no = 0;
			return -EINVAL;
		}
		/* consume all other chars till \n or end-of-buffer */
		while (*p != '\0' && *(p++) != '\n')
			;
	}

	return 0;
}