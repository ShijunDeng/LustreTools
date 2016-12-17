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
# include"lfz.h"

struct tbf_counter_t tbf_counter;

/*读取配置文件*/
int total_tbf_rate_init(void)
{
	char tbf_cfg[] = "/tmp/lustre/lustre_tbf_cfg";
	int rc = 0;
	char buf[128];
	struct file *f;
    mm_segment_t fs;
	__u64 total_tbf_rate = 0;

	f = filp_open(tbf_cfg, O_RDONLY, 0);

	if(!f || !(f->f_dentry))
	{
		printk(KERN_ALERT "filp_open error!!.\n");
		//没有给出配置文件或者配置文件读取失败 默认速度上限2 GB/s
		total_tbf_rate = 1<<30;
		rc = -1;
	}
	else
	{
        fs = get_fs();
        set_fs(get_ds());
        f->f_op->read(f, buf, 128, &f->f_pos);
        set_fs(fs);
        filp_close(f,NULL);
		printk(KERN_INFO "buf:%s\n",buf);
		total_tbf_rate=simple_strtoll(buf,NULL,10);
	}
	tbf_counter.resid_tbf = tbf_counter.total_tbf_rate =total_tbf_rate;
	printk(KERN_INFO "upper limit:%lld bytes/sec\n", total_tbf_rate);
	do_gettimeofday(&(tbf_counter.last_time));
	return rc;
}
//EXPORT_SYMBOL(total_tbf_rate_init);

void throttle_bandwidth(int bytes_transferred)
{
	struct timeval now;
	long need_sleep_usec = 0;

	spin_lock(&(tbf_counter.lock));
	if (!bytes_transferred)
		goto out;

	do_gettimeofday(&now);

    printk("now:%lld,last:%lld\n",(long long)now.tv_sec,(long long)tbf_counter.last_time.tv_sec);
	if (likely(now.tv_sec < tbf_counter.last_time.tv_sec))
	{
		goto out;
	}
	else if (likely(now.tv_sec > tbf_counter.last_time.tv_sec))
	{
		tbf_counter.last_time = now;
		tbf_counter.resid_tbf = tbf_counter.total_tbf_rate;
	}
    printk("bytes_transferred:%d\n",bytes_transferred);
    printk("tbf_counter.resid_tbf:%lld\n",tbf_counter.resid_tbf);
    printk("tbf_counter.total_tbf_rate:%lld\n",tbf_counter.total_tbf_rate);

	if(unlikely(tbf_counter.resid_tbf-bytes_transferred < 0))
	{
		need_sleep_usec = ONE_MILLION -(now.tv_usec%ONE_MILLION);
		goto out;
	}
	else
	{
		tbf_counter.resid_tbf -= bytes_transferred;
	}
out:
	spin_unlock(&(tbf_counter.lock));
	if (0 == need_sleep_usec)
	{
		return;
	}
    printk("sleep:%ld\n",need_sleep_usec);
    printk("\n");

	udelay(need_sleep_usec);
}
//EXPORT_SYMBOL(total_tbf_rate_init);
