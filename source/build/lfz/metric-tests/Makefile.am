## Process this file with automake to produce Makefile.in

TESTS = check_qos_rules
check_PROGRAMS = check_qos_rules
check_qos_rules_SOURCES = check_qos_rules.c ../osc/qos_rules.c \
	kernel_test_primitives.h $(top_builddir)/lustre/include/metric.h
check_qos_rules_CFLAGS = @CHECK_CFLAGS@ -fstack-protector -D_FORTIFY_SOURCE=2 -I../include -O0 -g -Wall -Werror
check_qos_rules_LDFLAGS = -z relro -z now
check_qos_rules_LDADD = @CHECK_LIBS@
