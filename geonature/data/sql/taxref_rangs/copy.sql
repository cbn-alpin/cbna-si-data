
BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into cbna schema and taxref_rangs table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Create schema "cbna"'
CREATE SCHEMA IF NOT EXISTS cbna;


\echo '-------------------------------------------------------------------------------'
\echo 'Create cbna.taxref_rangs table from "bib_taxref_rangs" with additional fields'
CREATE TABLE cbna.:trImportTable AS
    SELECT
        NULL::INT AS gid,
        id_rang,
        nom_rang,
        nom_rang_en,
        tri_rang,
        NULL::TIMESTAMP AS meta_create_date,
        NULL::TIMESTAMP AS meta_update_date,
        NULL::BPCHAR(1) AS meta_last_action
    FROM taxonomie.bib_taxref_rangs
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on cbna.taxref_rangs table'
\set importTablePk 'pk_':trImportTable
ALTER TABLE cbna.:trImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute cbna.taxref_rangs to GeoNature DB owner'
ALTER TABLE cbna.:trImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV file to import data into cbna.taxref_rangs table'
COPY cbna.:trImportTable (
    id_rang,
    nom_rang,
    nom_rang_en,
    tri_rang,
    meta_create_date,
    meta_update_date,
    meta_last_action
)
FROM :'csvFilePath'
WITH (FORMAT CSV, HEADER, DELIMITER E'\t', FORCE_NULL (nom_rang_en));


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
