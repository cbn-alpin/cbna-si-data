
BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into cbna schema and taxref_rank table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.0.0+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Create schema "cbna" if not exists'
CREATE SCHEMA IF NOT EXISTS cbna;


\echo '-------------------------------------------------------------------------------'
\echo 'Create cbna.taxref_rank table from "bib_taxref_rangs" with additional fields'
CREATE TABLE cbna.:trImportTable AS
    SELECT
        NULL::INT AS gid,
        id_rang AS code,
        nom_rang AS label,
        nom_rang_en AS label_en,
        tri_rang AS "level",
        NULL::jsonb AS additional_data,
        NULL::TIMESTAMP AS meta_create_date,
        NULL::TIMESTAMP AS meta_update_date,
        NULL::BPCHAR(1) AS meta_last_action
    FROM taxonomie.bib_taxref_rangs
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on cbna.taxref_rank table'
\set importTablePk 'pk_':trImportTable
ALTER TABLE cbna.:trImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute cbna.taxref_rank to GeoNature DB owner'
ALTER TABLE cbna.:trImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV file to import data into cbna.taxref_rank table'
COPY cbna.:trImportTable (
    code,
    label,
    label_en,
    "level",
    additional_data,
    meta_create_date,
    meta_update_date,
    meta_last_action
)
FROM :'csvFilePath'
WITH (FORMAT CSV, HEADER, DELIMITER E'\t', FORCE_NULL (label_en));


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
