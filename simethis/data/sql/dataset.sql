COPY (
    WITH 
        list_jdd AS (
            SELECT r.id_jdd
            FROM flore.releve r
            WHERE
                (r.meta_id_groupe = 1
                    OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
        )
    --        date_der_exp AS (
    --         SELECT max(suivi_export_synth.date_export) AS date_der_exp
    --           FROM sinp.suivi_export_synth
    --          WHERE suivi_export_synth.bd_cible::text = 'SINP PACA Alp'::text
    --        ), suivi_uuid AS (
    --         SELECT su_1.permid,
    --            su_1.date_last_export
    --           FROM sinp.suivi_uuid su_1
    --          WHERE su_1.reg::text = 'PACA'::text AND su_1.table_sce::text = 'jdd'::text
    --        )
    SELECT DISTINCT ON(unique_id_sinp)
        jd.uuid_jdd AS unique_id_sinp,
        ca.uuid_ca::varchar(255) AS code_acquisition_framework,
        jd.lib_jdd::varchar(150) AS "name",
        CASE
            WHEN ca.uuid_ca = 'b7456c07-9c0b-4e34-abc3-cb35dfc68eb9'
                THEN 'NEOUE'
            ELSE jd.lib_jdd_court
        END AS shortname,
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
            	WHEN COALESCE(pri.uuid_national, pri.permid::CHARACTER VARYING) IS NULL
            		THEN ARRAY[NULL, '1'] 
            	ELSE ARRAY[COALESCE(pri.uuid_national, pri.permid::CHARACTER VARYING), '1'] -- Contact principal
            END,
            CASE 
            	WHEN COALESCE(fi.uuid_national, fi.permid::CHARACTER VARYING) IS NULL
            		THEN ARRAY[NULL, '2'] 
            	ELSE ARRAY[COALESCE(fi.uuid_national, fi.permid::CHARACTER VARYING), '2'] -- Financeur
            END,
            CASE 
            	WHEN COALESCE(fo.uuid_national, fo.permid::CHARACTER VARYING) IS NULL
            		THEN ARRAY[NULL, '5'] 
            	ELSE ARRAY[COALESCE(fo.uuid_national, fo.permid::CHARACTER VARYING), '5'] -- Fournisseur
            END,
            CASE 
            	WHEN COALESCE(pro.uuid_national, pro.permid::CHARACTER VARYING) IS NULL
            		THEN ARRAY[NULL, '6'] 
            	ELSE ARRAY[COALESCE(pro.uuid_national, pro.permid::CHARACTER VARYING), '6'] -- Producteur
            END
            ] AS cor_actors_organism,
        ARRAY[
            ARRAY[upri.permid::CHARACTER VARYING, '1'::character VARYING], -- Contact principal
            ARRAY[ufi.permid::CHARACTER VARYING, '2'::character VARYING], -- Financeur
            ARRAY[ufo.permid::CHARACTER VARYING, '5'::character VARYING],  -- Fournisseur
            ARRAY[upro.permid::CHARACTER VARYING, '6'::character VARYING] -- Producteur
            ] AS cor_actors_user,
        jsonb_build_object(
            'idUserCreationJdd',jd.id_user_creation_jdd, 'methodCollect', jd.method_collect
        )::jsonb AS additional_data,
        jd.date_creation_jdd::timestamp AS meta_create_date,
        jd.date_maj_jdd::timestamp AS meta_update_date,
    --        CASE
    --            WHEN su.permid IS NULL THEN 'I'::text
    --            WHEN su.permid IS NOT NULL AND l.id_jdd IS NOT NULL THEN 'U'::text
    --            WHEN su.permid IS NOT NULL AND l.id_jdd IS NULL THEN 'D'::text
    --            ELSE NULL::text
    --        END AS meta_last_action
    'I'::char(1) AS meta_last_action
    FROM sinp.metadata_jdd jd
        JOIN list_jdd l ON jd.id_jdd = l.id_jdd
        LEFT JOIN sinp.metadata_ca ca ON jd.id_ca = ca.id_ca
        LEFT JOIN sinp.metadata_ref td ON jd.type_donnees = td.id_nomenclature
        LEFT JOIN sinp.metadata_ref obj ON jd.objectif_jdd = obj.id_nomenclature
        LEFT JOIN sinp.metadata_ref mc ON jd.method_collect = mc.id_nomenclature
        LEFT JOIN sinp.metadata_ref ori ON jd.data_origine = ori.id_nomenclature
        LEFT JOIN sinp.metadata_ref sta ON jd.statut_source = sta.id_nomenclature
        LEFT JOIN sinp.metadata_ref ter ON jd.terr_jdd = ter.id_nomenclature
        LEFT JOIN referentiels.organisme pri ON pri.id_org = jd.acteur_principal
        LEFT JOIN referentiels.organisme pro ON pro.id_org = jd.acteur_producteur
        LEFT JOIN referentiels.organisme fi ON fi.id_org = jd.acteur_financeur
        LEFT JOIN referentiels.organisme fo ON fo.id_org = jd.acteur_metadata
        LEFT JOIN applications.utilisateur u ON u.id_user = ca.id_user_creation_ca
        LEFT JOIN applications.utilisateur upri ON upri.id_user = jd.acteur_principal
        LEFT JOIN applications.utilisateur upro ON upro.id_user = jd.acteur_producteur
        LEFT JOIN applications.utilisateur ufi ON ufi.id_user = jd.acteur_financeur
        LEFT JOIN applications.utilisateur ufo ON ufo.id_user = jd.acteur_metadata
    --     LEFT JOIN suivi_uuid su ON jd.uuid_jdd = su.permid,
    --    date_der_exp
    --  WHERE COALESCE(jd.date_maj_jdd, jd.date_creation_jdd) >= COALESCE(su.date_last_export, date_der_exp.date_der_exp) OR su.permid IS NULL
) TO stdout
WITH (format csv, header, delimiter E'\t', null '\N')
;
     
     
