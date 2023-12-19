-- In order to list the duplicates of the uuid_national of the organism table, we created a query linked below
-- https://wiki-intranet.cbn-alpin.fr/projets/feder-si/migration-simethis-geonature#requete_permettant_de_lister_les_doublons_des_uuid_national_des_organismes

DROP TABLE IF EXISTS flore.permid_organism_uuid_duplicates;

CREATE TABLE flore.permid_organism_uuid_duplicates(
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
        duplicate_shortname AS (
            SELECT lib_jdd_court AS shortname
            FROM referentiels.metadata_jdd
            GROUP BY lib_jdd_court
            HAVING COUNT(*) > 1
        ),
        list_jdd AS (
            SELECT r.id_jdd
            FROM flore.releve r
            WHERE
                (r.meta_id_groupe = 1
                    OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
        )
    SELECT DISTINCT ON(unique_id_sinp)
        jd.uuid_jdd AS unique_id_sinp,
        ca.uuid_ca::varchar(255) AS code_acquisition_framework,
        jd.lib_jdd::varchar(150) AS "name",
        COALESCE(
            (
                SELECT CONCAT(mj.lib_jdd_court, ' - ', mj.id_jdd)
                FROM referentiels.metadata_jdd AS mj
                WHERE mj.id_jdd = jd.id_jdd
                    AND jd.lib_jdd_court IN (SELECT shortname FROM duplicate_shortname)
            ),
            jd.lib_jdd_court
        ) AS shortname,
        CASE
            WHEN jd.desc_jdd IS NULL
                THEN ''
            ELSE jd.desc_jdd::text
        END AS "desc",
        CASE
            WHEN jd.type_donnees IS NOT NULL
                THEN td.cd_nomenclature
            ELSE '1' -- Occurences de taxons
        END AS code_nomenclature_data_type,
        NULL::text AS keywords,
        jd.dom_marin AS marine_domain,
        jd.dom_terrestre AS terrestrial_domain,
        CASE
            WHEN obj.cd_nomenclature IS NOT NULL
                THEN obj.cd_nomenclature::varchar(25)
            ELSE '1.1' -- Observations naturalistes opportunistes
        END AS code_nomenclature_dataset_objectif,
        NULL::double precision AS bbox_west,
        NULL::double precision AS bbox_est,
        NULL::double precision AS bbox_south,
        NULL::double precision AS bbox_north,
        CASE
            WHEN mc.cd_nomenclature IS NOT NULL
                THEN mc.cd_nomenclature
            ELSE '1' -- Observation directe
        END AS code_nomenclature_collecting_method,
        CASE
            WHEN ori.lib_valeur::text = 'Privée'::text
                OR ori.lib_valeur::text = 'Publique'::TEXT
                    THEN ori.cd_nomenclature::text
            ELSE 'NSP'::text -- Ne sait pas
        END AS code_nomenclature_data_origin,
        CASE
            WHEN sta.cd_nomenclature IS NOT NULL
                THEN sta.cd_nomenclature
            ELSE 'NSP' -- Ne Sait Pas
        END AS code_nomenclature_source_status,
        ARRAY[ARRAY[
            CASE
                WHEN ter.cd_nomenclature IS NULL
                    THEN 'METROP'
                ELSE ter.cd_nomenclature
            END, 'Métropole']]
        AS cor_territory,
        ARRAY[
            CASE
                WHEN jd.acteur_principal IS NOT NULL
                    THEN ARRAY [COALESCE(
                        (CASE
                            WHEN lower(pri.uuid_national) ~* '^\s*$'
                                THEN NULL
                            WHEN lower(pri.uuid_national) IS NOT NULL
                                AND pri.permid NOT IN (SELECT poud.permid FROM flore.permid_organism_uuid_duplicates poud)
                                THEN lower(pri.uuid_national)
                            ELSE NULL
                        END),
                    pri.permid::varchar
                    ), '1'] -- Contact principal
                ELSE NULL::varchar[]
            END] ||
            CASE
                WHEN jd.acteur_financeur IS NOT NULL
                    THEN ARRAY [COALESCE(
                        (CASE
                            WHEN lower(fi.uuid_national) ~* '^\s*$'
                                THEN NULL
                            WHEN lower(fi.uuid_national) IS NOT NULL
                                AND fi.permid NOT IN (SELECT poud.permid FROM flore.permid_organism_uuid_duplicates poud)
                                THEN lower(fi.uuid_national)
                        ELSE NULL
                        END),
                    fi.permid::varchar
                    ), '2'] -- Financeur
                ELSE NULL::varchar[]
            END ||
            CASE
                WHEN jd.acteur_metadata IS NOT NULL
                    THEN ARRAY [COALESCE(
                        (CASE
                            WHEN lower(fo.uuid_national) ~* '^\s*$'
                                THEN NULL
                            WHEN lower(fo.uuid_national) IS NOT NULL
                                AND fo.permid NOT IN (SELECT poud.permid FROM flore.permid_organism_uuid_duplicates poud)
                                THEN lower(fo.uuid_national)
                        ELSE NULL
                        END),
                    fo.permid::varchar
                    ), '5'] -- Fournisseur
            ELSE NULL::varchar[]
            END ||
            CASE
                WHEN jd.acteur_producteur IS NOT NULL
                    THEN ARRAY [COALESCE(
                        (CASE
                            WHEN lower(pro.uuid_national) ~* '^\s*$'
                                THEN NULL
                            WHEN lower(pro.uuid_national) IS NOT NULL
                                AND pro.permid NOT IN (SELECT poud.permid FROM flore.permid_organism_uuid_duplicates poud)
                                THEN lower(pro.uuid_national)
                        ELSE NULL
                        END),
                    pro.permid::varchar
                    ), '6'] -- producteur
                ELSE NULL::varchar[]
            END AS cor_actors_organism,
        CASE
            WHEN jd.acteur_principal = 2785
                THEN ARRAY[ARRAY[lower('4690f8e2-78da-4d6b-9c63-6c506c45a50b'), '1']] -- Contact principal JMG
            ELSE NULL
        END AS cor_actors_user,
        jsonb_build_object(
            'idUserCreationJdd',jd.id_user_creation_jdd, 'methodCollect', jd.method_collect
        )::jsonb AS additional_data,
        jd.date_creation_jdd::timestamp AS meta_create_date,
        jd.date_maj_jdd::timestamp AS meta_update_date,
        'I'::char(1) AS meta_last_action
    FROM referentiels.metadata_jdd jd
        JOIN list_jdd l ON jd.id_jdd = l.id_jdd
        LEFT JOIN referentiels.metadata_ca ca ON jd.id_ca = ca.id_ca
        LEFT JOIN referentiels.metadata_ref td ON jd.type_donnees = td.id_nomenclature
        LEFT JOIN referentiels.metadata_ref obj ON jd.objectif_jdd = obj.id_nomenclature
        LEFT JOIN referentiels.metadata_ref mc ON jd.method_collect = mc.id_nomenclature
        LEFT JOIN referentiels.metadata_ref ori ON jd.data_origine = ori.id_nomenclature
        LEFT JOIN referentiels.metadata_ref sta ON jd.statut_source = sta.id_nomenclature
        LEFT JOIN referentiels.metadata_ref ter ON jd.terr_jdd = ter.id_nomenclature
        LEFT JOIN flore.permid_organism_uuid_duplicates poud ON poud.id_org = jd.acteur_principal
            OR poud.id_org = jd.acteur_financeur
            OR poud.id_org = jd.acteur_metadata
            OR poud.id_org = jd.acteur_producteur
        LEFT JOIN referentiels.organisme pri ON pri.id_org = jd.acteur_principal
        LEFT JOIN referentiels.organisme pro ON pro.id_org = jd.acteur_producteur
        LEFT JOIN referentiels.organisme fi ON fi.id_org = jd.acteur_financeur
        LEFT JOIN referentiels.organisme fo ON fo.id_org = jd.acteur_metadata
        LEFT JOIN applications.utilisateur u ON u.id_user = ca.id_user_creation_ca
        LEFT JOIN applications.utilisateur upri ON upri.id_user = jd.acteur_principal
        LEFT JOIN applications.utilisateur upro ON upro.id_user = jd.acteur_producteur
        LEFT JOIN applications.utilisateur ufi ON ufi.id_user = jd.acteur_financeur
        LEFT JOIN applications.utilisateur ufo ON ufo.id_user = jd.acteur_metadata
) TO '/tmp/dataset.csv'
WITH(format csv, header, delimiter E'\t', null '\N');
