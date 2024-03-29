COPY (
    SELECT DISTINCT
        ON (unique_id) mc.uuid_ca AS unique_id,
        mc.lib_ca::VARCHAR(255) AS "name",
        CASE
            WHEN mc.desc_ca IS NULL THEN ' '
            ELSE mc.desc_ca
        END AS "desc",
        mrter.cd_nomenclature AS code_nomenclature_territorial_level,
        public.delete_space (mc.comm_geo) AS territory_desc,
        NULL AS keywords,
        NULL AS code_nomenclature_financing_type,
        NULL AS target_description,
        NULL AS ecologic_or_geologic_target,
        mcasup.uuid_ca AS parent_code,
        mc.meta_cadre AS is_parent,
        CASE
            WHEN mc.date_lancement IS NOT NULL
            AND mc.date_lancement::VARCHAR !~* '^\s*$' THEN mc.date_lancement::date
            ELSE mj.date_creation_jdd::date
        END AS start_date,
        CASE
            WHEN mc.date_cloture::VARCHAR IS NOT NULL
            AND mc.date_cloture::VARCHAR !~* '^\s*$' THEN mc.date_cloture::date
            ELSE NULL
        END AS end_date,
        CASE
            WHEN mrobj.cd_nomenclature IS NOT NULL
            AND mrobj.cd_nomenclature !~* '^\s*$' THEN ARRAY[mrobj.cd_nomenclature]
            ELSE ARRAY['11']
        END AS cor_objectifs,
        ARRAY[1]::TEXT AS cor_voletsinp, --1 Terre
        CASE
            WHEN mc.acteur_principal IS NOT NULL THEN ARRAY[
                ARRAY[
                    LOWER(COALESCE(o.uuid_national, o.permid::VARCHAR)),
                    '1'::CHARACTER VARYING
                ]
            ] -- '1' contact principal
            ELSE NULL::CHARACTER VARYING[]
        END AS cor_actors_organism,
        ARRAY[ARRAY[u.permid::CHARACTER VARYING, '1'::TEXT]] AS cor_actors_user,
        NULL::json AS cor_publications,
        JSONB_BUILD_OBJECT(
            'idCa',
            mc.id_ca,
            'objectifCa',
            mc.objectif_ca,
            'nivTerr',
            mc.niv_terr_ca,
            'acteurPrincipal',
            mc.acteur_principal,
            'idCaSinpReg',
            mc.id_ca_sinp_reg
        )::jsonb AS additional_data,
        CASE
            WHEN mc.date_creation_ca IS NOT NULL
            AND mc.date_creation_ca::VARCHAR !~* '^\s*$' THEN mc.date_creation_ca::TIMESTAMP
            ELSE mj.date_creation_jdd::TIMESTAMP
        END AS meta_create_date,
        mc.date_maj_ca::TIMESTAMP AS meta_update_date,
        'I' AS meta_last_action
    FROM
        referentiels.metadata_ca mc
        JOIN referentiels.metadata_jdd mj ON mj.id_ca = mc.id_ca
        LEFT JOIN referentiels.metadata_ca mcasup ON mcasup.id_ca = mcasup.id_ca_sup
        LEFT JOIN referentiels.metadata_ref mrter ON mrter.id_nomenclature = mc.niv_terr_ca
        LEFT JOIN referentiels.metadata_ref mrobj ON mrobj.id_nomenclature = mc.objectif_ca
        LEFT JOIN referentiels.organisme o ON o.id_org = mc.acteur_principal
        LEFT JOIN applications.utilisateur u ON u.id_user = mc.id_user_creation_ca
        LEFT JOIN flore.releve r ON r.id_jdd = mj.id_jdd
    WHERE
        (
            r.meta_id_groupe = 1
            OR (
                r.meta_id_groupe <> 1
                AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')
            )
        )
) TO STDOUT
WITH
    (FORMAT CSV, HEADER, DELIMITER E'\t', NULL '\N');
