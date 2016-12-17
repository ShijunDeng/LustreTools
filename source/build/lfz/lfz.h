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
# ifndef _LFZ_H_
# define _LFZ_H_
# include <linux/types.h>
# include <linux/time.h>
# include <asm/param.h>
# include <linux/delay.h>
# include <linux/module.h>
# include <linux/kernel.h>
# include <linux/fs.h>
# include <asm/uaccess.h>
# define ONE_MILLION 1000000

struct tbf_counter_t
{
	spinlock_t lock;
	__u64 total_tbf_rate;
	__u64 resid_tbf;
	struct timeval last_time;
} ;

/*读取配置文件,初始化*/
int total_tbf_rate_init(void);
/*限速操作*/
void throttle_bandwidth(int bytes_transferred);

#ifndef __KERNEL__
static inline void udelay(long u)
{
	(void)u;
}
static inline void usleep_range(long u, long v)
{
	(void)u;
	(void)v;
}
static inline void msleep(long u)
{
	(void)u;
}
#endif
#endif
