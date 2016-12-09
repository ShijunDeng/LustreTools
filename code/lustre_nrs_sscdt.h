/*
 * GPL HEADER START
 *
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License version 2 for more details.
 *
 * You should have received a copy of the GNU General Public License
 * version 2 along with this program; If not, see
 * http://www.gnu.org/licenses/gpl-2.0.html
 *
 * GPL HEADER END
 */
/*
 * Copyright (c) 2016, Intel Corporation.
 *
 * Copyright 2012 Xyratex Technology Limited
 */
/*
 *
 * Network Request Scheduler (NRS) Server-side I/O Coordination (SSCDT) policy
 * 
 */

#ifndef _LUSTRE_NRS_SSCDT_H
#define _LUSTRE_NRS_SSCDT_H
 
/**
 * \name SSCDT
 *
 * SSCDT, Server-side I/O Coordination
 * @{
 */

/**
 * private data structure for SSCDT NRS
 */
struct nrs_sscdt_head {
    struct ptlrpc_nrs_resource  st_res;
    cfs_binheap_t         *st_binheap;

    /**
     * For debugging purposes.
     */
    __u64               st_sequence;
        
};

struct nrs_sscdt_req_priority
{
    __u64           st_priority;
};

/**
 * SSCDT NRS request definition
 */
struct nrs_sscdt_req {
    /**
     * When a file server receives a request, the scheduler first calculates 
     * its priority, and then inserts the request to the request queue in the 
     * ascending order of their priorities.The smaller the priority number 
     * a request gets, the earlier it would be scheduled. 
     */
    __u64           st_priority;
    /**
     * Sequence number for this request; 
     */
    __u64           st_sequence;
};

/**
 * SSCDT policy operations.
 */
enum nrs_ctl_sscdt {
    /**
     * Interval is the width of the ‘Time Window’, which can be defined as a startup parameter,
     * If interval is not configured, it will use the default value 1000000ns
     * (1000000ns for HDD and 250000ns for SSD).
     * Read the value of interval .
     */
    NRS_CTL_SSCDT_RD_INTERVAL = PTLRPC_NRS_CTL_1ST_POL_SPEC,
    /**
     * Write the value of interval .
     */
    NRS_CTL_SSCDT_WR_INTERVAL ,
};

/** @} SSCDT */
#endif

