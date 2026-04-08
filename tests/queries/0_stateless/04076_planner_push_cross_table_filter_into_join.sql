SET enable_analyzer = 1;
SET enable_parallel_replicas = 0;
SET enable_join_runtime_filters = 0;

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;

CREATE TABLE t1 (a UInt32, b UInt32, c String) ENGINE = Memory;
CREATE TABLE t2 (a UInt32, b UInt32, c String) ENGINE = Memory;

INSERT INTO t1 VALUES (1, 10, 'x'), (2, 20, 'y'), (3, 30, 'z'), (4, 5, 'w');
INSERT INTO t2 VALUES (1, 5, 'x'), (2, 25, 'y'), (3, 10, 'z'), (4, 50, 'w');

-- Test 1: basic non-equality cross-table filter with hash join
SELECT '--- test 1: hash join, setting OFF ---';
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 0;

SELECT '--- test 1: hash join, setting ON ---';
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 1;

-- EXPLAIN: OFF -> Filter above Join; ON -> Residual filter inside Join
SELECT '--- test 1 explain: hash join, setting OFF ---';
EXPLAIN header=0
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 0;

SELECT '--- test 1 explain: hash join, setting ON ---';
EXPLAIN header=0
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 1;

-- Test 2: multiple non-equality conditions
SELECT '--- test 2: multiple conditions, setting OFF ---';
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b AND t1.b < t2.b + 30
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 0;

SELECT '--- test 2: multiple conditions, setting ON ---';
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b AND t1.b < t2.b + 30
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 1;

SELECT '--- test 2 explain: multiple conditions, setting OFF ---';
EXPLAIN header=0
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b AND t1.b < t2.b + 30
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 0;

SELECT '--- test 2 explain: multiple conditions, setting ON ---';
EXPLAIN header=0
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b AND t1.b < t2.b + 30
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 1;

-- Test 3: non-hash join algorithm -> should fallback to post-join Filter even with setting ON
SELECT '--- test 3: full_sorting_merge, setting OFF ---';
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'full_sorting_merge', query_plan_push_cross_table_filter_into_join = 0;

SELECT '--- test 3: full_sorting_merge, setting ON ---';
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'full_sorting_merge', query_plan_push_cross_table_filter_into_join = 1;

SELECT '--- test 3 explain: full_sorting_merge, setting OFF ---';
EXPLAIN header=0
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'full_sorting_merge', query_plan_push_cross_table_filter_into_join = 0;

SELECT '--- test 3 explain: full_sorting_merge, setting ON ---';
EXPLAIN header=0
SELECT t1.a, t1.b, t2.a, t2.b
FROM t1 INNER JOIN t2 ON t1.a = t2.a WHERE t1.b > t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'full_sorting_merge', query_plan_push_cross_table_filter_into_join = 1;

-- Test 4: mixed equality + non-equality cross-table conditions in WHERE
SELECT '--- test 4: mixed conditions, setting OFF ---';
SELECT t1.a, t1.b, t1.c, t2.a, t2.b, t2.c
FROM t1 INNER JOIN t2 ON t1.c = t2.c WHERE t1.a = t2.a AND t1.b != t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 0;

SELECT '--- test 4: mixed conditions, setting ON ---';
SELECT t1.a, t1.b, t1.c, t2.a, t2.b, t2.c
FROM t1 INNER JOIN t2 ON t1.c = t2.c WHERE t1.a = t2.a AND t1.b != t2.b
ORDER BY t1.a
SETTINGS join_algorithm = 'hash', query_plan_push_cross_table_filter_into_join = 1;

DROP TABLE t1;
DROP TABLE t2;
