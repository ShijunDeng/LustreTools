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
 * Test suite of qos_rules routines
 *
 *  Created on: Nov 14, 2013
 *      Author: yanli
 */

#include <stdio.h>
#include <check.h>
#include <kernel-test-primitives.h>
#include <metric.h>

struct qos_data_t qos;
void setup (void)
{
	memset(&qos, 0, sizeof(qos));
}
void teardown (void)
{
}

START_TEST (test_error_input_no_rule_no)
{
	const char buf[] = "wrong data";

	ck_assert_int_eq(parse_qos_rules(buf, &qos), -EINVAL);
	ck_assert_int_eq(qos.rule_no, 0);
	ck_assert(qos.rules == NULL);
}
END_TEST

START_TEST (test_error_input_bad_lines)
{
	/* Make an error on the 2nd line and test if the first line
	 * result is freed before returning */
	const char buf[] = "2,1\n"
		"0,10000,9,10009,0,2147483647,163,-923,7\n"
		"10000,2147483647,";

	ck_assert_int_eq(parse_qos_rules(buf, &qos), -EINVAL);
	ck_assert_int_eq(qos.rule_no, 0);
	ck_assert(qos.rules == NULL);
}
END_TEST

START_TEST (test_zero_input)
{
	const char buf1[] = "0";
	const char buf2[] = "0\n";

	ck_assert_int_eq(parse_qos_rules(buf1, &qos), 0);
	ck_assert_int_eq(qos.rule_no, 0);
	ck_assert(qos.rules == NULL);
	ck_assert_int_eq(parse_qos_rules(buf2, &qos), 0);
	ck_assert_int_eq(qos.rule_no, 0);
	ck_assert(qos.rules == NULL);
}
END_TEST

START_TEST (test_too_few_rules)
{
	const char buf[] = "2,1\n"
		"0,10000,9,10009,0,2147483647,163,-923,7";

	ck_assert_int_eq(parse_qos_rules(buf, &qos), -EINVAL);
	ck_assert_int_eq(qos.rule_no, 0);
	ck_assert(qos.rules == NULL);
}
END_TEST

START_TEST (test_parsing_rules_without_used_times_or_ewma_avgs)
{
	const char buf[] = "2,1\n"
		"0,10000,9,10009,0,2000,163,-923,7\n"
		"10000,2147483647,10009,2147483647,2000,2147483647,164,-924,8\n";

	ck_assert_int_eq(parse_qos_rules(buf, &qos), 0);
	ck_assert_int_eq(qos.rule_no, 2);
	ck_assert_int_eq(qos.min_gap_between_updating_mrif, 1000000);
	ck_assert_int_eq(qos.rules[0].ack_ewma_lower, 0);
	ck_assert_int_eq(qos.rules[0].ack_ewma_upper, 10000);
	ck_assert_int_eq(qos.rules[0].send_ewma_lower, 9);
	ck_assert_int_eq(qos.rules[0].send_ewma_upper, 10009);
	ck_assert_int_eq(qos.rules[0].rtt_ratio100_lower, 0);
	ck_assert_int_eq(qos.rules[0].rtt_ratio100_upper, 2000);
	ck_assert_int_eq(qos.rules[0].m100, 163);
	ck_assert_int_eq(qos.rules[0].b100, -923);
	ck_assert_int_eq(qos.rules[0].tau, 7);
	ck_assert_int_eq(qos.rules[0].used_times, 0);
	ck_assert_int_eq(qos.rules[0].ack_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[0].send_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[1].ack_ewma_lower, 10000);
	ck_assert_int_eq(qos.rules[1].ack_ewma_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].send_ewma_lower, 10009);
	ck_assert_int_eq(qos.rules[1].send_ewma_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].rtt_ratio100_lower, 2000);
	ck_assert_int_eq(qos.rules[1].rtt_ratio100_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].m100, 164);
	ck_assert_int_eq(qos.rules[1].b100, -924);
	ck_assert_int_eq(qos.rules[1].tau, 8);
	ck_assert_int_eq(qos.rules[1].used_times, 0);
	ck_assert_int_eq(qos.rules[1].ack_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[1].send_ewma_avg, 0);

	free(qos.rules);
}
END_TEST

START_TEST (test_parsing_rules_without_used_times_or_ewma_avgs_without_last_newline)
{
	const char buf[] = "2,2\n"
		"0,10000,9,10009,0,2000,163,-923,7\n"
		"10000,2147483647,10009,2147483647,2000,2147483647,164,-924,8";

	ck_assert_int_eq(parse_qos_rules(buf, &qos), 0);
	ck_assert_int_eq(qos.rule_no, 2);
	ck_assert_int_eq(qos.min_gap_between_updating_mrif, 1000000 / 2);
	ck_assert_int_eq(qos.rules[0].ack_ewma_lower, 0);
	ck_assert_int_eq(qos.rules[0].ack_ewma_upper, 10000);
	ck_assert_int_eq(qos.rules[0].send_ewma_lower, 9);
	ck_assert_int_eq(qos.rules[0].send_ewma_upper, 10009);
	ck_assert_int_eq(qos.rules[0].rtt_ratio100_lower, 0);
	ck_assert_int_eq(qos.rules[0].rtt_ratio100_upper, 2000);
	ck_assert_int_eq(qos.rules[0].m100, 163);
	ck_assert_int_eq(qos.rules[0].b100, -923);
	ck_assert_int_eq(qos.rules[0].tau, 7);
	ck_assert_int_eq(qos.rules[0].used_times, 0);
	ck_assert_int_eq(qos.rules[0].ack_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[0].send_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[1].ack_ewma_lower, 10000);
	ck_assert_int_eq(qos.rules[1].ack_ewma_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].send_ewma_lower, 10009);
	ck_assert_int_eq(qos.rules[1].send_ewma_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].rtt_ratio100_lower, 2000);
	ck_assert_int_eq(qos.rules[1].rtt_ratio100_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].m100, 164);
	ck_assert_int_eq(qos.rules[1].b100, -924);
	ck_assert_int_eq(qos.rules[1].tau, 8);
	ck_assert_int_eq(qos.rules[1].used_times, 0);
	ck_assert_int_eq(qos.rules[1].ack_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[1].send_ewma_avg, 0);

	free(qos.rules);
}
END_TEST

START_TEST (test_parsing_rules_with_used_times_and_ewma_avgs)
{
	const char buf[] = "2,1\n"
		"0,10000,9,10009,0,2000,163,-923,7,1234,2456,2457\n"
		"10000,2147483647,10009,2147483647,2000,2147483647,164,-924,8,4321,12345,12346\n";

	ck_assert_int_eq(parse_qos_rules(buf, &qos), 0);
	ck_assert_int_eq(qos.rule_no, 2);
	ck_assert_int_eq(qos.min_gap_between_updating_mrif, 1000000);
	ck_assert_int_eq(qos.rules[0].ack_ewma_lower, 0);
	ck_assert_int_eq(qos.rules[0].ack_ewma_upper, 10000);
	ck_assert_int_eq(qos.rules[0].send_ewma_lower, 9);
	ck_assert_int_eq(qos.rules[0].send_ewma_upper, 10009);
	ck_assert_int_eq(qos.rules[0].rtt_ratio100_lower, 0);
	ck_assert_int_eq(qos.rules[0].rtt_ratio100_upper, 2000);
	ck_assert_int_eq(qos.rules[0].m100, 163);
	ck_assert_int_eq(qos.rules[0].b100, -923);
	ck_assert_int_eq(qos.rules[0].tau, 7);
	ck_assert_int_eq(qos.rules[0].used_times, 0);
	ck_assert_int_eq(qos.rules[0].ack_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[0].send_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[1].ack_ewma_lower, 10000);
	ck_assert_int_eq(qos.rules[1].ack_ewma_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].send_ewma_lower, 10009);
	ck_assert_int_eq(qos.rules[1].send_ewma_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].rtt_ratio100_lower, 2000);
	ck_assert_int_eq(qos.rules[1].rtt_ratio100_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].m100, 164);
	ck_assert_int_eq(qos.rules[1].b100, -924);
	ck_assert_int_eq(qos.rules[1].tau, 8);
	ck_assert_int_eq(qos.rules[1].used_times, 0);
	ck_assert_int_eq(qos.rules[1].ack_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[1].send_ewma_avg, 0);

	free(qos.rules);
}
END_TEST

START_TEST (test_parsing_rules_with_used_times_and_ewma_avgs_without_last_newline)
{
	const char buf[] = "2,1\n"
		"0,10000,9,10009,0,2000,163,-923,7,1234,2456,2457\n"
		"10000,2147483647,10009,2147483647,2000,2147483647,164,-924,8,4321,12345,12346";

	ck_assert_int_eq(parse_qos_rules(buf, &qos), 0);
	ck_assert_int_eq(qos.rule_no, 2);
	ck_assert_int_eq(qos.min_gap_between_updating_mrif, 1000000);
	ck_assert_int_eq(qos.rules[0].ack_ewma_lower, 0);
	ck_assert_int_eq(qos.rules[0].ack_ewma_upper, 10000);
	ck_assert_int_eq(qos.rules[0].send_ewma_lower, 9);
	ck_assert_int_eq(qos.rules[0].send_ewma_upper, 10009);
	ck_assert_int_eq(qos.rules[0].rtt_ratio100_lower, 0);
	ck_assert_int_eq(qos.rules[0].rtt_ratio100_upper, 2000);
	ck_assert_int_eq(qos.rules[0].m100, 163);
	ck_assert_int_eq(qos.rules[0].b100, -923);
	ck_assert_int_eq(qos.rules[0].tau, 7);
	ck_assert_int_eq(qos.rules[0].used_times, 0);
	ck_assert_int_eq(qos.rules[0].ack_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[0].send_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[1].ack_ewma_lower, 10000);
	ck_assert_int_eq(qos.rules[1].ack_ewma_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].send_ewma_lower, 10009);
	ck_assert_int_eq(qos.rules[1].send_ewma_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].rtt_ratio100_lower, 2000);
	ck_assert_int_eq(qos.rules[1].rtt_ratio100_upper, 2147483647);
	ck_assert_int_eq(qos.rules[1].m100, 164);
	ck_assert_int_eq(qos.rules[1].b100, -924);
	ck_assert_int_eq(qos.rules[1].tau, 8);
	ck_assert_int_eq(qos.rules[1].used_times, 0);
	ck_assert_int_eq(qos.rules[1].ack_ewma_avg, 0);
	ck_assert_int_eq(qos.rules[1].send_ewma_avg, 0);

	free(qos.rules);
}
END_TEST

Suite *
qos_rules_suite (void)
{
	Suite *s = suite_create ("qos_rules");

	/* Core test case */
	TCase *tc_parsing = tcase_create ("Parsing");
	tcase_add_checked_fixture (tc_parsing, setup, teardown);
	tcase_add_test (tc_parsing, test_error_input_no_rule_no);
	tcase_add_test (tc_parsing, test_error_input_bad_lines);
	tcase_add_test (tc_parsing, test_zero_input);
	tcase_add_test (tc_parsing, test_too_few_rules);
	tcase_add_test (tc_parsing, test_parsing_rules_without_used_times_or_ewma_avgs);
	tcase_add_test (tc_parsing, test_parsing_rules_without_used_times_or_ewma_avgs_without_last_newline);
	tcase_add_test (tc_parsing, test_parsing_rules_with_used_times_and_ewma_avgs);
	tcase_add_test (tc_parsing, test_parsing_rules_with_used_times_and_ewma_avgs_without_last_newline);
	suite_add_tcase (s, tc_parsing);

	return s;
}

int
main (void)
{
	int number_failed;
	Suite *s = qos_rules_suite ();
	SRunner *sr = srunner_create (s);
	srunner_run_all (sr, CK_NORMAL);
	number_failed = srunner_ntests_failed (sr);
	srunner_free (sr);
	return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
