COPY (
SELECT
	mc.uuid_ca AS unique_id,
	mc.lib_ca AS "name",
	mc.desc_ca AS "desc",
	mrter.cd_nomenclature AS code_nomenclature_territorial_level,
	mc.comm_geo AS territory_desc,
	NULL AS keywords,
	NULL AS code_nomenclature_financing_type,
	NULL AS target_description,
	NULL AS ecologic_or_geologic_target,
	mc.id_ca_sup::varchar(255) AS parent_code,
	mc.meta_cadre AS is_parent,
	mc.date_lancement::date AS start_date,
	mc.date_cloture::date AS end_date,
	ARRAY[mrobj.cd_nomenclature] AS cor_objectifs,
	ARRAY[1]::TEXT AS cor_voletsinp, --1 Terre
	CASE
            WHEN mc.acteur_principal IS NOT NULL THEN ARRAY[ARRAY[o.nom, '1'::character varying]] -- '1' contact principal
            ELSE NULL::character varying[]
        END AS cor_actors_organism,
	ARRAY[ARRAY[split_part(u.email::TEXT, '@'::TEXT, 1), '1'::TEXT]] AS cor_actors_user,
    NULL::json AS cor_publications,
    jsonb_build_object(
    	'idCa', mc.id_ca, 'objectifCa', mc.objectif_ca, 'nivTerr', mc.niv_terr_ca, 'acteurPrincipal', mc.acteur_principal, 'idCaSinpReg', mc.id_ca_sinp_reg
    )::jsonb AS additional_data,
    mc.date_creation_ca::timestamp AS meta_create_date,
    mc.date_maj_ca::timestamp AS meta_update_date
FROM sinp.metadata_ca mc
	JOIN sinp.metadata_jdd mj ON mj.id_ca = mc.id_ca 
	LEFT JOIN sinp.metadata_ref mrter ON mrter.id_nomenclature = mc.niv_terr_ca
	LEFT JOIN sinp.metadata_ref mrobj ON mrobj.id_nomenclature = mc.objectif_ca
	LEFT JOIN referentiels.organisme o ON o.id_org = mc.acteur_principal 
	LEFT JOIN applications.utilisateur u ON u.id_user = mc.id_user_creation_ca 
	LEFT JOIN flore.releve r ON r.id_jdd = mj.id_jdd 
 WHERE (r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1
		AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
) TO stdout
WITH (format csv, header, delimiter E'\t')
;
	
	
	
	
