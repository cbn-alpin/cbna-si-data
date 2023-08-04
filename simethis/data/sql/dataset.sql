WITH 
	list_jdd AS (
         SELECT r.id_jdd
         FROM flore.releve r
--          WHERE r.insee_dept = ANY (ARRAY['04'::bpchar, '05'::bpchar,])
         WHERE
			(r.meta_id_groupe = 1
				OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
--          GROUP BY r.id_jdd
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
 SELECT
 	jd.uuid_jdd AS unique_id_sinp,
    concat(ca.id_ca, ' - ', ca.lib_ca)::varchar(255) AS code_acquisition_framework,
    jd.lib_jdd AS name,
    jd.lib_jdd_court AS shortname,
    jd.desc_jdd AS "desc",
--    td.cd_nomenclature AS code_nomenclature_data_type
--    CASE
--    	WHEN td.cd_nomenclature IS NOT NULL 
--    		THEN td.cd_nomenclature
--    	ELSE '1' -- Occurences de taxons
--    END AS code_nomenclature_data_type,
    CASE
    	WHEN jd.type_donnees IS NOT NULL
    		THEN td.cd_nomenclature
    		ELSE '1' -- Occurences de taxons
    END AS code_nomenclature_data_type,
    NULL::text AS keywords,
    jd.dom_marin AS marine_domain,
    jd.dom_terrestre AS terrestrial_domain,
--    obj.cd_nomenclature AS code_nomenclature_dataset_objectif
    CASE 
    	WHEN obj.cd_nomenclature IS NOT NULL
    		THEN obj.cd_nomenclature::varchar(25)
    	ELSE '1.1' -- Observations naturalistes opportunistes
    END code_nomenclature_dataset_objectif,  
    NULL::double precision AS bbox_west,
    NULL::double precision AS bbox_est,
    NULL::double precision AS bbox_south,
    NULL::double precision AS bbox_north,
--    mc.cd_nomenclature AS code_nomenclature_collecting_method,
    CASE 
    	WHEN mc.cd_nomenclature IS NOT NULL
    		THEN mc.cd_nomenclature
    	ELSE '1' -- Observation directe
    END code_nomenclature_collecting_method,    
--    ori.cd_nomenclature AS code_nomenclature_data_origin,
    CASE
    	WHEN ori.cd_nomenclature IS NOT NULL
    		THEN ori.cd_nomenclature
    	ELSE 'NSP' -- Ne Sait Pas
    END AS code_nomenclature_data_origin,
--    sta.cd_nomenclature AS code_nomenclature_source_status,
    CASE
    	WHEN sta.cd_nomenclature IS NOT NULL
    		THEN sta.cd_nomenclature
    	ELSE 'NSP' -- Ne Sait Pas
    END AS code_nomenclature_source_status,
    '1'::varchar(25) AS code_nomenclature_type, -- Jeu de données
    ARRAY[ARRAY[ter.cd_nomenclature, 'Métropole'::character varying]]::TEXT AS cor_territory,
    (ARRAY[ARRAY[pri.uuid_national, '1'::character varying]]::TEXT ||
        CASE
            WHEN jd.acteur_producteur IS NOT NULL THEN ARRAY[pro.uuid_national, '6'::character varying]
            ELSE NULL::character varying[]
        END) ||
        CASE
            WHEN jd.acteur_financeur IS NOT NULL THEN ARRAY[fi.uuid_national, '2'::character varying]
            ELSE NULL::character varying[]
        END AS cor_actors_organism,
    ARRAY[ARRAY[split_part(u.email::text, '@'::text, 1), '1'::text]] AS cor_actors_user,
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
     LEFT JOIN applications.utilisateur u ON u.id_user = ca.id_user_creation_ca
--     LEFT JOIN suivi_uuid su ON jd.uuid_jdd = su.permid,
--    date_der_exp
--  WHERE COALESCE(jd.date_maj_jdd, jd.date_creation_jdd) >= COALESCE(su.date_last_export, date_der_exp.date_der_exp) OR su.permid IS NULL;
    ;
     
      
