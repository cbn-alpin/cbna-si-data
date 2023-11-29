-- In order to list the duplicates of the uuid_national of the organism table, we created a query linked below
-- https://wiki-intranet.cbn-alpin.fr/projets/feder-si/migration-simethis-geonature#requete_permettant_de_lister_les_doublons_des_uuid_national_des_organismes

DROP TABLE IF EXISTS flore.permid_organism_uuid_duplicates;

CREATE TABLE flore.permid_organism_uuid_duplicates (
    gid SERIAL PRIMARY KEY,
    permid UUID,
    id_org SMALLSERIAL,
    "name" VARCHAR
);

-- Insert datas from CSV file to table
COPY flore.permid_organism_uuid_duplicates(permid, id_org, "name")
FROM :'organismsDuplicatesCsvFilePath'
DELIMITER ','
CSV HEADER;

COPY (
    WITH
        all_id_orgs_export AS(
            SELECT DISTINCT(id_org)
                id_org
            FROM referentiels.organisme o
                JOIN referentiels.metadata_jdd mjorg
                    ON (mjorg.acteur_principal = o.id_org
                        OR mjorg.acteur_metadata = o.id_org
                        OR mjorg.acteur_producteur = o.id_org
                        OR mjorg.acteur_financeur = o.id_org
                    )
                LEFT JOIN flore.releve r
                    ON r.id_jdd = mjorg.id_jdd
            WHERE
                r.meta_id_groupe = 1
                    OR (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))

            UNION

            SELECT DISTINCT(id_org)
                id_org
            FROM referentiels.organisme o
                JOIN flore.releve r
                    ON (r.id_org_f = o.id_org
                        OR r.id_org_obs1 = o.id_org
                        OR r.id_org_obs2 = o.id_org
                        OR r.id_org_obs3 = o.id_org
                        OR r.id_org_obs4 = o.id_org
                        OR r.id_org_obs5 = o.id_org
                    )
            WHERE
                r.meta_id_groupe = 1
                    OR (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))

            UNION

            SELECT DISTINCT ON (o.id_org)
                CASE
                    WHEN r.meta_id_user_saisie IS NOT NULL
                        THEN o.id_org
                END AS id_org
            FROM applications.utilisateur u
                    JOIN flore.releve r ON r.meta_id_user_saisie  = u.id_user
                    LEFT JOIN referentiels.organisme o ON o.id_org = u.id_org
            WHERE
                (r.meta_id_groupe = 1
                    OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
    )
    SELECT DISTINCT ON (unique_id)
        COALESCE(
            (CASE
                WHEN lower(o.uuid_national) ~* '^\s*$'
                    THEN NULL
                WHEN lower(o.uuid_national) IS NOT NULL
                    AND o.permid NOT IN (SELECT poud.permid FROM flore.permid_organism_uuid_duplicates poud)
                    THEN lower(o.uuid_national)
                ELSE NULL
            END),
            o.permid::varchar
        )::uuid AS unique_id,
        o.nom AS "name",
        o.adresse AS adress,
        public.delete_space(o.cp) AS postal_code,
        public.delete_space(o.ville) AS city,
        LEFT(public.delete_space(o.tel),14) AS phone,
        NULL::bpchar AS fax,
        public.delete_space(o.email) AS email,
        public.delete_space(o.web) AS url,
        NULL::bpchar AS logo_url,
        jsonb_strip_nulls(
            CASE
                WHEN o.id_org IS NOT NULL
                    THEN jsonb_build_object('infoSup',
                        jsonb_build_object(
                            'idOrg', o.id_org,
                            'code', o.code,
                            'pays', o.pays,
                            'sinpDspublique', o.sinp_dspublique,
                            'metaIdGroupe', o.meta_id_groupe,
                            'comm', o.comm,
                            'permid', o.permid,
                            'fichier1', o.fichier1
                        )
                    )
                ELSE jsonb_build_object('infoSup', null)
                END ||
            CASE
                WHEN o.uuid_national ~* '^\s*$' OR  o.uuid_national IS NULL
                    THEN jsonb_build_object('is_uuid_national', false)
                ELSE jsonb_build_object('is_uuid_national', TRUE)
            END::jsonb) AS additional_data,
        o.meta_date_saisie::timestamp AS meta_create_date,
        CASE
            WHEN o.meta_date_maj IS NOT NULL OR o.meta_date_maj::varchar !~* '^\s*$'
                THEN o.meta_date_maj::timestamp
            ELSE NULL
        END AS meta_update_date,
        'I' AS meta_last_action
    FROM referentiels.organisme o
        JOIN all_id_orgs_export a ON a.id_org = o.id_org
    WHERE o.id_org IN(a.id_org)
) TO '/tmp/organism.csv'
WITH(format csv, header, delimiter E'\t', null '\N') ;
