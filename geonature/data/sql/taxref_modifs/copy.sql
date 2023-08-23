
BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into cbna schema and taxref_modifs table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Create cbna.taxref_modifs table from "taxref" with additional fields'
CREATE TABLE cbna.:tmImportTable AS
    SELECT
        NULL::INT AS gid,
        cd_nom,
        id_statut,
        id_habitat,
        id_rang,
        regne,
        phylum,
        classe,
        ordre,
        famille,
        sous_famille,
        tribu,
        cd_taxsup,
        cd_sup,
        cd_ref,
        lb_nom,
        lb_auteur,
        nom_complet,
        nom_complet_html,
        nom_valide,
        nom_vern,
        nom_vern_eng,
        group1_inpn,
        group2_inpn,
        "url",
        group3_inpn,
        NULL::TIMESTAMP AS meta_create_date,
        NULL::TIMESTAMP AS meta_update_date,
        NULL::JSONB AS meta_update_comment,
        NULL::BPCHAR(1) AS meta_last_action
    FROM taxonomie.taxref
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports cbna.taxref_modifs table'
\set importTablePk 'pk_':tmImportTable
ALTER TABLE cbna.:tmImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);

\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on cbna.taxref_modifs table'
\set cdNomIdx 'idx_unique_':tmImportTable'_cd_nom'
CREATE UNIQUE INDEX :cdNomIdx
    ON cbna.:tmImportTable USING btree (cd_nom);

\set updateDateIdx 'idx_':tmImportTable'_meta_update_date'
CREATE INDEX :updateDateIdx
    ON cbna.:tmImportTable USING btree (meta_update_date);

\set lastActionIdx 'idx_':tmImportTable'_meta_last_action'
CREATE INDEX :lastActionIdx
    ON cbna.:tmImportTable USING btree (meta_last_action);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute cbna.taxref_modifs to GeoNature DB owner'
ALTER TABLE cbna.:tmImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV file to import data into cbna.taxref_modifs table'
COPY cbna.:tmImportTable (
    cd_nom,
    id_statut,
    id_habitat,
    id_rang,
    regne,
    phylum,
    classe,
    ordre,
    famille,
    sous_famille,
    tribu,
    cd_taxsup,
    cd_sup,
    cd_ref,
    lb_nom,
    lb_auteur,
    nom_complet,
    nom_complet_html,
    nom_valide,
    nom_vern,
    nom_vern_eng,
    group1_inpn,
    group2_inpn,
    "url",
    group3_inpn,
    meta_create_date,
    meta_update_date,
    meta_update_comment,
    meta_last_action
)
FROM :'csvFilePath'
WITH (FORMAT CSV, HEADER, DELIMITER E'\t', FORCE_NULL (phylum, classe, ordre, famille, sous_famille, tribu, lb_auteur, nom_valide, nom_vern, nom_vern_eng));

\echo '----------------------------------------------------------------------------'
\echo 'UPDATE cd_ref < 15 to add 30 000 in prevention of new taxref version'
UPDATE cbna.:tmImportTable
SET cd_ref = cd_ref + 30000000
WHERE cd_ref < 15 ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
