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
pg_restore --host "localhost" --port "5432" -U "cbionda"  --verbose --dbname "si_cbn" --jobs "3" "/home/cbionda/data/dump_simethis/referentiels_20230828.dump" 2>&1 | tee "/home/cbionda/data/dump_simethis/referentiels_20230828_pgrestore.log"
pg_restore --host "localhost" --port "5432" -U "cbionda"  --verbose --dbname "si_cbn" --jobs "3" "/home/cbionda/data/dump_simethis/applications_20230828.dump" 2>&1 | tee "/home/cbionda/data/dump_simethis/applications_20230828_pgrestore.log"
psql si_cbn -c "create schema sinp"
pg_restore --host "localhost" --port "5432" -U "cbionda"  --verbose --dbname "si_cbn" --jobs "3" "/home/cbionda/data/dump_simethis/sinp_20230824" 2>&1 | tee "/home/cbionda/data/dump_simethis/sinp_20230824_pgrestore.log"
pg_restore --host "localhost" --port "5432" -U "cbionda"  --verbose --dbname "si_cbn" --jobs "3" "/home/cbionda/data/dump_simethis/vegetation_20230828.dump" 2>&1 | tee "/home/cbionda/data/dump_simethis/vegetation_20230828_pgrestore.log"
pg_restore --host "localhost" --port "5432" -U "cbionda"  --verbose --dbname "si_cbn" --jobs "3" "/home/cbionda/data/dump_simethis/flore_20230828.dump" 2>&1 | tee "/home/cbionda/data/dump_simethis/flore_20230828_pgrestore.log"
echo 'database flore simethis restored'
psql -h "localhost" -U "cbionda" -d "si_cbn" -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/utils.sql"
echo 'create utils functions'
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/taxref_rangs.sql" > /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/$(date +'%F')_taxref_rangs.csv
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/taxref.sql" > /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/$(date +'%F')_taxref.csv
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/taxref_modifs.sql" > /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/$(date +'%F')_taxref_modifs.csv
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/source.sql" > /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/$(date +'%F')_source.csv
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/organism.sql" > /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/$(date +'%F')_organism.csv
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -v cbnaAgentCsvFilePath="'/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/raw/cbna_agent.csv'" -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/user.sql"
sudo chown cbionda /tmp/user.csv
sudo mv /tmp/user.csv /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/acquisition_framework.sql" > /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/$(date +'%F')_acquisition_framework.csv
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/dataset.sql" > /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/$(date +'%F')_dataset.csv
psql --no-psqlrc -h localhost -U cbionda -d si_cbn -f "/home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/simethis/data/sql/synthese.sql"
sudo chown cbionda /tmp/synthese.csv
sudo mv /tmp/synthese.csv /home/cbionda/workspace/geonature/migration_data_simethis/cbna-si-data/geonature/data/raw/
echo 'all CSV files created'




