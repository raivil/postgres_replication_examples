# postgres_replication_examples

Example of logical replication between Postgresql 11 and 13.

### How to use
- Run Postgresql 11 (source)
```
docker compose up postgres-11
```
- Run Postgresql 13 (destination)
```
docker compose up postgres-13
```

- Access the postgres-11 database and create random data on table 'large_test' with query below:
```
$ psql -h 127.0.0.1 -p 5431 -U example_user -W -d example_db
Password:
psql (11.11, server 11.12)
Type "help" for help.

example_db=# INSERT INTO large_test (num1, num2, num3)
  SELECT round(random()*10), random(), random()*142
  FROM generate_series(1, 200) s(i);
INSERT 0 200
example_db=#


```
- Access the postgres-13 database and check if data is replicated:
```
$ psql -h 127.0.0.1 -p 5433 -U example_user -W -d example_db
Password:
psql (11.11, server 13.3)
WARNING: psql major version 11, server major version 13.
         Some psql features might not work.
Type "help" for help.

example_db=# select count(*) from large_test;
 count
-------
   200
(1 row)
```

- Check the logs:
```
postgres-11  | 2021-06-18 13:20:01.037 GMT [70] LOG:  logical decoding found consistent point at 0/16782B8
postgres-11  | 2021-06-18 13:20:01.037 GMT [70] DETAIL:  There are no running transactions.
postgres-11  | 2021-06-18 13:20:01.048 GMT [71] LOG:  starting logical decoding for slot "my_subscription"
postgres-11  | 2021-06-18 13:20:01.048 GMT [71] DETAIL:  Streaming transactions committing after 0/16782F0, reading WAL from 0/16782B8.
postgres-11  | 2021-06-18 13:20:01.048 GMT [71] LOG:  logical decoding found consistent point at 0/16782B8


postgres-13  | 2021-06-18 13:20:01.180 GMT [1] LOG:  database system is ready to accept connections
postgres-13  | 2021-06-18 13:20:01.195 GMT [71] LOG:  logical replication apply worker for subscription "my_subscription" has started
postgres-13  | 2021-06-18 13:20:01.203 GMT [72] LOG:  logical replication table synchronization worker for subscription "my_subscription", table "large_test" has started
postgres-13  | 2021-06-18 13:20:01.222 GMT [72] LOG:  logical replication table synchronization worker for subscription "my_subscription", table "large_test" has finished
```
