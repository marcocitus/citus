CREATE SCHEMA failure_create_table;
SET search_path TO 'failure_create_table';

SELECT citus.mitmproxy('conn.allow()');

-- Create distributed table in 1PC and 2PC,
-- then check if the transaction can be rollbacked.
SET citus.shard_replication_factor TO 1;
SET citus.shard_count to 4;

CREATE TABLE test_table(id int, value_1 int);

-- Kill connection before sending query to the worker 
SELECT citus.mitmproxy('conn.kill()');
SELECT create_distributed_table('test_table','id');

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';

-- kill as soon as the coordinator sends CREATE SCHEMA
SELECT citus.mitmproxy('conn.onQuery(query="^CREATE SCHEMA").kill()');
SELECT create_distributed_table('test_table', 'id');

SELECT citus.mitmproxy('conn.allow()');
SELECT count(*) FROM pg_dist_shard;
SELECT run_command_on_workers($$SELECT count(*) FROM information_schema.schemata WHERE schema_name = 'failure_create_table'$$);

-- Now, kill the connection just after transaction is opened on
-- workers.
SELECT citus.mitmproxy('conn.onQuery(query="^BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED").kill()');
SELECT create_distributed_table('test_table','id');

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

-- Now, cancel the connection just after transaction is opened on
-- workers. Note that, cancel requests will be ignored during
-- shard creation.
SELECT citus.mitmproxy('conn.onQuery(query="^BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED").cancel(' || pg_backend_pid() || ')');
SELECT create_distributed_table('test_table','id');

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

DROP TABLE test_table;
CREATE TABLE test_table(id int, value_1 int);

-- Kill the connection while with colocate_with option
CREATE TABLE temp_table(id int, value_1 int);
SELECT create_distributed_table('temp_table','id');

SELECT citus.mitmproxy('conn.onQuery(query="CREATE TABLE").kill()');
SELECT create_distributed_table('test_table','id',colocate_with=>'temp_table');

SELECT citus.mitmproxy('conn.allow()');

SELECT count(*) FROM pg_dist_shard WHERE logicalrelid='test_table'::regclass;

SELECT citus.mitmproxy('conn.onQuery(query="CREATE TABLE").cancel(' || pg_backend_pid() || ')');
SELECT create_distributed_table('test_table','id',colocate_with=>'temp_table');

SELECT citus.mitmproxy('conn.allow()');

SELECT count(*) FROM pg_dist_shard WHERE logicalrelid='test_table'::regclass;

DROP TABLE temp_table;

-- Kill the connection after worker sends "PREPARE TRANSACTION" ack
SELECT citus.mitmproxy('conn.onQuery(query="^PREPARE TRANSACTION").kill()');
SELECT create_distributed_table('test_table','id');

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

SELECT citus.mitmproxy('conn.onQuery(query="PREPARE TRANSACTION").cancel(' ||  pg_backend_pid() || ')');
SELECT create_distributed_table('test_table','id');

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

-- Test inside transaction
-- Kill connection before sending query to the worker 
SELECT citus.mitmproxy('conn.kill()');

BEGIN;
SELECT create_distributed_table('test_table','id');
ROLLBACK;

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

-- Now, kill the connection just after transaction is opened on
-- workers.
SELECT citus.mitmproxy('conn.onQuery(query="^BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED").kill()');

BEGIN;
SELECT create_distributed_table('test_table','id');
ROLLBACK;

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

-- Now, cancel the connection just after transaction is opened on
-- workers. Note that, cancel requests will be ignored during
-- shard creation.
SELECT citus.mitmproxy('conn.onQuery(query="^BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED").cancel(' || pg_backend_pid() || ')');

BEGIN;
SELECT create_distributed_table('test_table','id');
COMMIT;

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

DROP TABLE test_table;
CREATE TABLE test_table(id int, value_1 int);

-- Test inside transaction and with 1PC
SET citus.multi_shard_commit_protocol TO "1pc";

-- Kill connection before sending query to the worker 
SELECT citus.mitmproxy('conn.kill()');

BEGIN;
SELECT create_distributed_table('test_table','id');
ROLLBACK;

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

-- Now, kill the connection just after transaction is opened on
-- workers.
SELECT citus.mitmproxy('conn.onQuery(query="^BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED").kill()');

BEGIN;
SELECT create_distributed_table('test_table','id');
ROLLBACK;

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

-- Now, cancel the connection just after transaction is opened on
-- workers. Note that, cancel requests will be ignored during
-- shard creation.
SELECT citus.mitmproxy('conn.onQuery(query="^BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED").cancel(' || pg_backend_pid() || ')');

BEGIN;
SELECT create_distributed_table('test_table','id');
COMMIT;

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');
DROP TABLE test_table;

-- Test master_create_worker_shards with 2pc
CREATE TABLE test_table_2(id int, value_1 int);
SELECT master_create_distributed_table('test_table_2', 'id', 'hash');

-- Kill connection before sending query to the worker 
SELECT citus.mitmproxy('conn.kill()');
SELECT master_create_worker_shards('test_table_2', 4, 2);

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table_2%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

-- Kill the connection after worker sends "PREPARE TRANSACTION" ack
SELECT citus.mitmproxy('conn.onQuery(query="^PREPARE TRANSACTION").kill()');
SELECT master_create_worker_shards('test_table_2', 4, 2);

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table_2%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

SELECT citus.mitmproxy('conn.onQuery(query="PREPARE TRANSACTION").cancel(' ||  pg_backend_pid() || ')');
SELECT master_create_worker_shards('test_table_2', 4, 2);

SELECT count(*) FROM pg_dist_shard;

\c - - - :worker_1_port
SELECT count(*) FROM pg_class WHERE relname LIKE 'test_table_2%';

\c - - - :master_port
SET search_path TO 'failure_create_table';
SELECT citus.mitmproxy('conn.allow()');

-- Show that there is no pending transaction
SELECT recover_prepared_transactions();

DROP SCHEMA failure_create_table CASCADE;
SET search_path TO default;
