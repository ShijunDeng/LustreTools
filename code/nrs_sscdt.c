/*
 * GPL HEADER START
 *
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 only,
 * as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License version 2 for more details.  A copy is
 * included in the COPYING file that accompanied this code.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * GPL HEADER END
 */
/*
 * Copyright (c) 2011, 2014, 2016, Intel Corporation.
 *
 * Copyright 2012 Xyratex Technology Limited
 */
/*
 * lustre/ptlrpc/nrs_sscdt.c
 *
 * Network Request Scheduler (NRS) SSCDT policy
 *
 * Request ordering in a self-defined priority
 *
 * Author: Shijun Deng <SjDeng@hust.edu.cn>
 */
/**
 * \addtogoup nrs
 * @{
 */
#ifdef HAVE_SERVER_SUPPORT

#define DEBUG_SUBSYSTEM S_RPC
#include <obd_support.h>
#include <obd_class.h>
#include <libcfs/libcfs.h>
#include <lustre_net.h>
#include <lprocfs_status.h>
#include "ptlrpc_internal.h"

/**
 * \name SSCDT policy
 *
 * Client Round-Robin scheduling over client NIDs
 *
 * @{
 *
 */

#define NRS_POL_NAME_SSCDT  "sscdt"

 /**
 * Interval is the width of the ‘Time Window’, which can be defined as a startup parameter,
 * If interval is not configured, it will use the default value 1000ms
 * (1000ms for HDD and 250ms for SSD).
 */
__u32  interval=1000;
#define INTERVAL interval
 
 
 
 
/**
 * Binary heap predicate.
 *
 * Uses ptlrpc_nrs_request::nr_u::sscdt::priority to compare two binheap nodes and
 * produce a binary predicate that shows their relative priority, so that the
 * binary heap can perform the necessary sorting operations.The smaller this value
 * (ptlrpc_nrs_request::nr_u::sscdt::priority), the higher priority who will get.
 *
 * \param[in] e1 the first binheap node to compare
 * \param[in] e2 the second binheap node to compare
 *
 * \retval 0 priority of e1 <= priority of e2
 * \retval 1 priority of e1 > priority of e2
 * But note that the value of the higher st_priority one will smaller on the contrary
 */
static int sscdt_req_compare(cfs_binheap_node_t *e1, cfs_binheap_node_t *e2)
{
    struct ptlrpc_nrs_request *nrq1;
    struct ptlrpc_nrs_request *nrq2;
    struct ptlrpc_request *req1;
    struct ptlrpc_request *req2;
    __u64 time_window1;
    __u64 time_window2;
    
    nrq1 = container_of(e1, struct ptlrpc_nrs_request, nr_node);
    nrq2 = container_of(e2, struct ptlrpc_nrs_request, nr_node);
    req1 = container_of(nrq1,struct ptlrpc_request,rq_nrq);//rq_nrq -alias
    req2 = container_of(nrq2,struct ptlrpc_request,rq_nrq);//rq_nrq -alias
    /**
     * rq_sent (secs)
     */
    time_window1=(req1->rq_sent)*1000/INTERVAL;
    time_window2=(req2->rq_sent)*1000/INTERVAL;
    
    /**
     * not in the same time window
     */
    if(time_window1 != time_window2){
        return req1->rq_sent < req2->rq_sent;
    }
    
    if((req1->rq_peer).nid == (req2->rq_peer).nid){
        return (req1->rq_peer).pid < (req2->rq_peer).pid;
    }
    return (req1->rq_peer).nid < (req2->rq_peer).nid;
    /**
     * note that the value of the higher priority one will smaller on the contrary
     */
    //if (nrq1->nr_u.sscdt.st_priority < nrq2->nr_u.sscdt.st_priority)
        //return 0;
    //return 1;
}

static cfs_binheap_ops_t nrs_sscdt_heap_ops = {
    .hop_enter  = NULL,
    .hop_exit   = NULL,
    .hop_compare    = sscdt_req_compare,
};


/**
 * Called when a SSCDT policy instance is started.
 *
 * \param[in] policy the policy
 *
 * \retval -ENOMEM OOM error
 * \retval 0       success
 */
static int nrs_sscdt_start(struct ptlrpc_nrs_policy *policy, char *arg)
{
    struct nrs_sscdt_head    *head;
    int         rc = 0;
    ENTRY;

    OBD_CPT_ALLOC_PTR(head, nrs_pol2cptab(policy), nrs_pol2cptid(policy));
    if (head == NULL)
        RETURN(-ENOMEM);

    head->st_binheap = cfs_binheap_create(&nrs_sscdt_heap_ops,
                         CBH_FLAG_ATOMIC_GROW, 4096, NULL,
                         nrs_pol2cptab(policy),
                         nrs_pol2cptid(policy));
    if (head->st_binheap == NULL)
        GOTO(failed, rc = -ENOMEM);
    /**
     * Set to 1 so that the test inside nrs_sscdt_req_add() can evaluate to
     * true.
     */
    head->st_sequence = 1;

    policy->pol_private = head;

    RETURN(rc);

failed:
    if (head->st_binheap != NULL)
        cfs_binheap_destroy(head->st_binheap);

    OBD_FREE_PTR(head);

    RETURN(rc);
}

/**
 * Called when a SSCDT policy instance is stopped.
 *
 * Called when the policy has been instructed to transition to the
 * ptlrpc_nrs_pol_state::NRS_POL_STATE_STOPPED state and has no more pending
 * requests to serve.
 *
 * \param[in] policy the policy
 */
static void nrs_sscdt_stop(struct ptlrpc_nrs_policy *policy)
{
    struct nrs_sscdt_head   *head = policy->pol_private;
    ENTRY;

    LASSERT(head != NULL);
    LASSERT(head->st_binheap != NULL);
    LASSERT(cfs_binheap_is_empty(head->st_binheap));

    cfs_binheap_destroy(head->st_binheap);

    OBD_FREE_PTR(head);
}

/**
 * Performs a policy-specific ctl function on SSCDT policy instances; similar
 * to ioctl.
 *
 * \param[in]     policy the policy instance
 * \param[in]     opc    the opcode
 * \param[in,out] arg    used for passing parameters and information
 *
 * \pre assert_spin_locked(&policy->pol_nrs->->nrs_lock)
 * \post assert_spin_locked(&policy->pol_nrs->->nrs_lock)
 *
 * \retval 0   operation carried out successfully
 * \retval -ve error
 */
static int nrs_sscdt_ctl(struct ptlrpc_nrs_policy *policy,
            enum ptlrpc_nrs_ctl opc,
            void *arg)
{
    assert_spin_locked(&policy->pol_nrs->nrs_lock);

    switch((enum nrs_ctl_sscdt)opc) {
    default:
        RETURN(-EINVAL);

    /**
     * Read the value of interval .
     */
    case NRS_CTL_SSCDT_RD_INTERVAL: {
        *(__u64 *)arg = interval;
        }
        break;

    /**
     * Write the value of interval .
     */
    case NRS_CTL_SSCDT_WR_INTERVAL: {
        interval= *(__u64 *)arg;
        }
        break;
    }

    RETURN(0);
}
/**
 * Is called for obtaining a SSCDT policy resource.
 *
 * \param[in]  policy     The policy on which the request is being asked for
 * \param[in]  nrq    The request for which resources are being taken
 * \param[in]  parent     Parent resource, unused in this policy
 * \param[out] resp   Resources references are placed in this array
 * \param[in]  moving_req Signifies limited caller context; unused in this
 *            policy
 *
 * \retval 1 The SSCDT policy only has a one-level resource hierarchy, as since
 *       it implements a simple scheduling algorithm in which request
 *       priority is determined on the request arrival order, it does not
 *       need to maintain a set of resources that would otherwise be used
 *       to calculate a request's priority.
 *
 * \see nrs_resource_get_safe()
 */
static int nrs_sscdt_res_get(struct ptlrpc_nrs_policy *policy,
                struct ptlrpc_nrs_request *nrq,
                const struct ptlrpc_nrs_resource *parent,
                struct ptlrpc_nrs_resource **resp, bool moving_req)
{
    /**
     * Just return the resource embedded inside nrs_sscdt_head, and end this
     * resource hierarchy reference request.
     */
    *resp = &((struct nrs_sscdt_head *)policy->pol_private)->st_res;
    return 1;
}

/**
 * Called when releasing references to the resource hierachy obtained for a
 * request for scheduling using the SSCDT policy.
 *
 * \param[in] policy   the policy the resource belongs to
 * \param[in] res      the resource to be released
 */
static void nrs_sscdt_res_put(struct ptlrpc_nrs_policy *policy,
                 const struct ptlrpc_nrs_resource *res)
{
    /**
     *
     */
}

/**
 * Called when getting a request from the SSCDT policy for handlingso that it can be served
 *
 * \param[in] policy the policy being polled
 * \param[in] peek   when set, signifies that we just want to examine the
 *           request, and not handle it, so the request is not removed
 *           from the policy.
 * \param[in] force  force the policy to return a request; unused in this policy
 *
 * \retval the request to be handled
 * \retval NULL no request available
 *
 * \see ptlrpc_nrs_req_get_nolock()
 * \see nrs_request_get()
 */
static
struct ptlrpc_nrs_request *nrs_sscdt_req_get(struct ptlrpc_nrs_policy *policy,
                        bool peek, bool force)
{
    struct nrs_sscdt_head     *head = policy->pol_private;
    cfs_binheap_node_t   *node = cfs_binheap_root(head->st_binheap);
    struct ptlrpc_nrs_request *nrq;

    nrq = unlikely(node == NULL) ? NULL :
          container_of(node, struct ptlrpc_nrs_request, nr_node);

    if (likely(!peek && nrq != NULL)) {
        struct ptlrpc_request *req = container_of(nrq,
                              struct ptlrpc_request,
                              rq_nrq);//rq_nrq -alias

        cfs_binheap_remove(head->st_binheap, &nrq->nr_node);
        
        CDEBUG(D_RPCTRACE, "NRS start %s request from %s, seq: "LPU64
               "\n", policy->pol_desc->pd_name,
               libcfs_id2str(req->rq_peer), nrq->nr_u.sscdt.st_sequence);
    }

    return nrq;
}

/**
 * Adds request \a nrq to \a policy's list of queued requests
 *
 * \param[in] policy The policy
 * \param[in] nrq    The request to add
 *
 * \retval 0 success; nrs_request_enqueue() assumes this function will always
 *            succeed
 */
static int nrs_sscdt_req_add(struct ptlrpc_nrs_policy *policy,
                struct ptlrpc_nrs_request *nrq)
{
    struct nrs_sscdt_head   *head;
    int          rc;
    //struct ptlrpc_request *req = container_of(nrq,
    //                          struct ptlrpc_request,
    //                         rq_nrq);//rq_nrq -alias
    head = container_of(nrs_request_resource(nrq),
               struct nrs_sscdt_head, st_res);
    //nrq->nr_u.sscdt.st_priority=
    rc = cfs_binheap_insert(head->st_binheap, &nrq->nr_node);
    nrq->nr_u.sscdt.st_sequence = head->st_sequence++;
    return rc;
}

/**
 * Removes request \a nrq from a SSCDT \a policy instance's set of queued
 * requests.
 *
 * \param[in] policy the policy
 * \param[in] nrq    the request to remove
 */
static void nrs_sscdt_req_del(struct ptlrpc_nrs_policy *policy,
                 struct ptlrpc_nrs_request *nrq)
{
    struct nrs_sscdt_head   *head;
    bool             is_root;
    head = container_of(nrs_request_resource(nrq),
               struct nrs_sscdt_head, st_res);

    is_root = &nrq->nr_node == cfs_binheap_root(head->st_binheap);
    cfs_binheap_remove(head->st_binheap, &nrq->nr_node);
}

/**
 * Called right after the request \a nrq finishes being handled by SSCDT policy
 * instance \a policy.
 *
 * \param[in] policy the policy that handled the request
 * \param[in] nrq    the request that was handled
 */
static void nrs_sscdt_req_stop(struct ptlrpc_nrs_policy *policy,
                  struct ptlrpc_nrs_request *nrq)
{
    struct ptlrpc_request *req = container_of(nrq, struct ptlrpc_request,
                          rq_nrq);

    CDEBUG(D_RPCTRACE, "NRS stop %s request from %s, seq: "LPU64"\n",
               policy->pol_desc->pd_name, libcfs_id2str(req->rq_peer),
               nrq->nr_u.sscdt.st_sequence);
}

/**
 * SSCDT policy operations
 */
static const struct ptlrpc_nrs_pol_ops nrs_sscdt_ops = {
    .op_policy_start    = nrs_sscdt_start,
    .op_policy_stop     = nrs_sscdt_stop,
    .op_policy_ctl      = nrs_sscdt_ctl,
    .op_res_get     = nrs_sscdt_res_get,
    .op_res_put     = nrs_sscdt_res_put,
    .op_req_get     = nrs_sscdt_req_get,
    .op_req_enqueue     = nrs_sscdt_req_add,
    .op_req_dequeue     = nrs_sscdt_req_del,
    .op_req_stop        = nrs_sscdt_req_stop,
};

/**
 * SSCDT policy configuration
 */
struct ptlrpc_nrs_pol_conf nrs_conf_sscdt = {
    .nc_name        = NRS_POL_NAME_SSCDT,
    .nc_ops         = &nrs_sscdt_ops,
    .nc_compat      = nrs_policy_compat_all,
};

/** @} SSCDT policy */

/** @} nrs */

#endif /* HAVE_SERVER_SUPPORT */


