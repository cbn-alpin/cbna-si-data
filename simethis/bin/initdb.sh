#!/usr/bin/env bash

#script d'initialisation de la base simethis depuis son dump


dropdb --if-exists si_cbn
echo 'database si_cbn droped'
createdb -T template0 si_cbn
echo 'database si_cbn created'
echo "SELECT 'CREATE USER si_user' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'si_user')\gexec" | psql
echo "SELECT 'CREATE USER cbnmed_user' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cbnmed_user')\gexec" | psql
echo "SELECT 'CREATE USER cbnmed_admin' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cbnmed_admin')\gexec" | psql
echo "SELECT 'CREATE USER cbna_user' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cbna_user')\gexec" | psql
echo "SELECT 'CREATE USER cbnc_user' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cbnc_user')\gexec" | psql
echo "SELECT 'CREATE USER cbnc_admin' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cbnc_admin')\gexec" | psql
echo "SELECT 'CREATE USER cbna_admin' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cbna_admin')\gexec" | psql
echo "SELECT 'CREATE USER \"d.rougie\"' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'd.rougie')\gexec" | psql
echo 'all users created'
psql si_cbn -c "create extension postgis;"
psql si_cbn -c "create extension dblink;"
psql si_cbn -c 'create extension "uuid-ossp";'
psql si_cbn -c "create extension tablefunc;"
psql si_cbn -c "create extension unaccent;"
psql si_cbn -c "create extension fuzzystrmatch;"
psql si_cbn -c "create extension postgres_fdw;"
psql si_cbn -c "create extension intarray;"
psql si_cbn -c "create extension ogr_fdw;"
echo 'all extensions created'
pg_restore --host "localhost" --port "5432" -U "cbionda"  --verbose --dbname "si_cbn" --jobs "3" "/home/cbionda/data/dump_simethis/flore_20230516.dump" 2>&1 | tee "/home/cbionda/data/dump_simethis/flore_20230516_pgrestore.log"
echo 'database flore simethis restored'


