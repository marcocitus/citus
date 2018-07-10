SELECT citus.mitmproxy('conn.allow()');

-- With one placement COPY should error out and placement should stay healthy.
SET citus.shard_replication_factor TO 1;
SET citus.shard_count to 4;

CREATE TABLE test_table(id int, value_1 int);
SELECT create_distributed_table('test_table','id');

SELECT citus.mitmproxy('conn.kill()');

\COPY test_table FROM stdin delimiter ',';
1,2
3,4
6,7
8,9
\.

SELECT citus.mitmproxy('conn.allow()');
SELECT * FROM pg_dist_shard_placement;

-- Now, kill the connection while copying the data
SELECT citus.mitmproxy('conn.onCopyData().kill()');
\COPY test_table FROM stdin delimiter ',';
1,2
3,4
6,7
8,9
\.

SELECT citus.mitmproxy('conn.allow()');
SELECT * FROM pg_dist_shard_placement;

-- With two placement, should we error out or mark untouched shard placements as inactive?
SET citus.shard_replication_factor TO 2;

CREATE TABLE test_table_2(id int, value_1 int);
SELECT create_distributed_table('test_table_2','id');

SELECT citus.mitmproxy('conn.kill()');

\COPY test_table_2 FROM stdin delimiter ',';
1,2
3,4
6,7
8,9
\.

SELECT citus.mitmproxy('conn.allow()');
SELECT * FROM pg_dist_shard_placement;

SELECT citus.mitmproxy('conn.onCopyData().kill()');
\COPY test_table_2 FROM stdin delimiter ',';
1,2
3,4
6,7
8,9
9,10
11,12
13,14
\.

SELECT citus.mitmproxy('conn.allow()');
SELECT * FROM pg_dist_shard_placement;
