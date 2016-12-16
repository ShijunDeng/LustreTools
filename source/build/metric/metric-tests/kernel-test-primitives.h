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
 * Primitives for testing kernel routines in userspace
 *
 *  Created on: Nov 14, 2013
 *      Author: yanli
 */
#ifndef KERNEL_TEST_PRIMITIVES_H_
#define KERNEL_TEST_PRIMITIVES_H_

#include <stdlib.h>
#include <errno.h>

#define CWARN printf
typedef unsigned long long __u64;
typedef int                spinlock_t;

static inline void LIBCFS_FREE(void *ptr, size_t s)
{
	free (ptr);
}

#define LIBCFS_ALLOC_ATOMIC(ptr, size)	\
do {					\
	(ptr) = malloc(size);		\
} while (0)

#endif
