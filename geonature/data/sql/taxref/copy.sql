BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into cbna schema and taxref_change table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.0.0+'

SET client_encoding = 'UTF8';

\echo '-------------------------------------------------------------------------------'
\echo 'Create schema "cbna" if not exists'
CREATE SCHEMA IF NOT EXISTS cbna;

\echo '-------------------------------------------------------------------------------'
\echo 'Create cbna.taxref_change table from "taxref" with additional fields'
CREATE TABLE cbna.:taxrefImportTable AS
    SELECT
        NULL::INT AS gid,
        cd_nom AS sciname_code,
        id_statut AS biogeographic_status_code,
        id_habitat AS habitat_type_code,
        id_rang AS rank_code,
        regne AS kingdom,
        phylum,
        classe AS class,
        ordre AS order,
        famille AS family,
        sous_famille AS subfamily,
        tribu AS tribe,
        cd_taxsup AS higher_taxon_code_shorter,
        cd_sup AS higher_taxon_code_full,
        cd_ref AS taxon_code,
        lb_nom AS sciname_short,
        lb_auteur AS sciname_author,
        nom_complet AS sciname,
        nom_complet_html AS sciname_html,
        nom_valide AS sciname_valid,
        nom_vern AS vernacular_name,
        nom_vern_eng AS vernacular_name_en,
        group1_inpn AS inpn_group1_label,
        group2_inpn AS inpn_group2_label,
        group3_inpn AS inpn_group3_label,
        "url" AS inpn_url,
        NULL::JSONB AS additional_data,
        NULL::TIMESTAMP AS meta_create_date,
        NULL::TIMESTAMP AS meta_update_date,
        NULL::BPCHAR(1) AS meta_last_action
    FROM taxonomie.taxref
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports cbna.taxref_change table'
\set importTablePk 'pk_':taxrefImportTable
ALTER TABLE cbna.:taxrefImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);

\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on cbna.taxref_change table'
\set scinameCodeIdx 'idx_unique_':taxrefImportTable'_sciname_code'
CREATE UNIQUE INDEX :scinameCodeIdx
    ON cbna.:taxrefImportTable USING btree (sciname_code);

\set updateDateIdx 'idx_':taxrefImportTable'_meta_update_date'
CREATE INDEX :updateDateIdx
    ON cbna.:taxrefImportTable USING btree (meta_update_date);

\set lastActionIdx 'idx_':taxrefImportTable'_meta_last_action'
CREATE INDEX :lastActionIdx
    ON cbna.:taxrefImportTable USING btree (meta_last_action);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute cbna.taxref_change to GeoNature DB owner'
ALTER TABLE cbna.:taxrefImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV file to import data into cbna.taxref_change table'
COPY cbna.:taxrefImportTable (
    sciname_code,
    biogeographic_status_code,
    habitat_type_code,
    rank_code,
    kingdom,
    phylum,
    class,
    order,
    family,
    subfamily,
    tribe,
    higher_taxon_code_short,
    higher_taxon_code_full,
    taxon_code,
    sciname_short,
    sciname_author,
    sciname,
    sciname_html,
    sciname_valid,
    vernacular_name,
    vernacular_name_en,
    inpn_group1_label,
    inpn_group2_label,
    inpn_group3_label,
    inpn_url,
    additional_data,
    meta_create_date,
    meta_update_date,
    meta_last_action
)
FROM :'csvFilePath'
WITH (
    FORMAT CSV, HEADER, DELIMITER E'\t',
    FORCE_NULL (phylum, class, order, family, subfamily, tribe, sciname_short, sciname_valid, vernacular_name, vernacular_name_en)
);

-- TODO: ce mécanisme est déjà en place dans l'export de Simethis ! Vérifier si on peut le supprimer.
-- \echo '----------------------------------------------------------------------------'
-- \echo 'UPDATE cd_ref < 15 to add 30 000 000 in prevention of new taxref version'
-- UPDATE cbna.:taxrefImportTable
-- SET taxon_code = taxon_code + 30000000
-- WHERE taxon_code < 15 ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
