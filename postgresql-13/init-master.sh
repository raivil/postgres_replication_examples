#!/bin/bash
set -e

echo "Creating pg_hba.conf... ${REP_USER}"
sed -e "s/\${REPLICATION_USER}/$REPLICATION_USER/" \
    -e "s/\${DB_NAME}/$DB_NAME/" \
    -e "s/\${DB_USER}/$DB_USER/" \
    /tmp/postgresql/pg_hba.conf \
    > $PGDATA/pg_hba.conf
echo "Creating pg_hba.conf complete."

echo "Creating postgresql.conf..."
cp /tmp/postgresql/postgresql.conf $PGDATA/postgresql.conf

echo "Creating example database..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
   CREATE DATABASE ${DB_NAME};
   CREATE ROLE ${DB_USER} PASSWORD '${DB_PASS}' SUPERUSER LOGIN;
   GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} to ${DB_USER};
EOSQL
echo "Creating example database complete."

echo "Creating example tables."
psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" <<-EOSQL
    CREATE TABLE large_test (num1 bigint, num2 double precision, num3 double precision);
    SELECT grantee, privilege_type FROM information_schema.role_table_grants WHERE table_name='large_test';
EOSQL
echo "Creation complete."

echo "Creating replication user and granting access..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$DB_NAME" <<-EOSQL
    CREATE ROLE ${REPLICATION_USER} PASSWORD '${REPLICATION_PASS}' REPLICATION LOGIN;
    GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${REPLICATION_USER};
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${REPLICATION_USER};
    SELECT grantee, privilege_type FROM information_schema.role_table_grants WHERE table_name='large_test';
EOSQL
echo "Creating replication user complete."

echo "Creating subscription."
psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" <<-EOSQL
  CREATE SUBSCRIPTION my_subscription CONNECTION 'host=$PUBLICATION_SERVER port=5432 password=$REPLICATION_PASS user=$REPLICATION_USER dbname=$DB_NAME application_name=pg13-subscriber' PUBLICATION my_publication;
EOSQL
echo "Creation complete."

mkdir /var/lib/postgresql/archive
chown postgres:postgres /var/lib/postgresql/archive
chown -R postgres:postgres ${PGDATA}
