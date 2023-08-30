CREATE OR REPLACE FUNCTION flore.generate_observers(id_releve integer, sep character varying DEFAULT ' '::character varying)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
generate_observers text;
begin
generate_observers :=

concat_ws($2,
	  	CASE 
			WHEN rel.id_obs1 IS NOT NULL --obs1
				THEN concat(obs1.nom,' ', obs1.prenom, 
					CASE
						WHEN obs1.email IS NOT NULL AND obs1.email != '' --si email obs1
							THEN concat(' <', obs1.email,'>') --email obs1
						ELSE ''
					END,
					' (',
			  		CASE
						WHEN id_org_obs1 IS NOT NULL --si org1
							THEN (SELECT coalesce( NULLIF(org1.abb,'') ,org1.nom) --org_obs1
								FROM referentiels.organisme org1
								WHERE rel.id_org_obs1 = org1.id_org )
						ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
					END,')',
					concat(' [',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs1)),']') -- uuid obs1
						   )
			ELSE NULL
		END,		
        CASE 
			WHEN rel.id_obs2 IS NOT NULL --obs2
				THEN concat(obs2.nom,' ', obs2.prenom, 
					CASE
						WHEN obs2.email IS NOT NULL AND obs2.email != '' --si email obs2
							THEN concat(' <', obs2.email,'>') --email obs2
						ELSE ''
					END,
					' (',
			  		CASE
						WHEN id_org_obs2 IS NOT NULL --si org2
							THEN (SELECT coalesce( NULLIF(org2.abb,'') ,org2.nom) --org_obs2
								FROM referentiels.organisme org2
								WHERE rel.id_org_obs2 = org2.id_org )
						ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
					END,')',
					concat(' [',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs2)),']') -- uuid obs2
						   )
			ELSE NULL
		END,
		CASE 
			WHEN rel.id_obs3 IS NOT NULL --obs3
				THEN concat(obs3.nom,' ', obs3.prenom, 
					CASE
						WHEN obs3.email IS NOT NULL AND obs3.email != '' --si email obs3
							THEN concat(' <', obs3.email,'>') --email obs3
						ELSE ''
					END,
					' (',
			  		CASE
						WHEN id_org_obs3 IS NOT NULL --si org3
							THEN (SELECT coalesce( NULLIF(org3.abb,'') ,org3.nom) --org_obs3
								FROM referentiels.organisme org3
								WHERE rel.id_org_obs3 = org3.id_org )
						ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
					END,')',
					concat(' [',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs3)),']') -- uuid obs3
						   )
			ELSE NULL
		END,
		CASE 
			WHEN rel.id_obs4 IS NOT NULL --obs4
				THEN concat(obs4.nom,' ', obs4.prenom, 
					CASE
						WHEN obs4.email IS NOT NULL AND obs4.email != '' --si email obs4
							THEN concat(' <', obs4.email,'>') --email obs4
						ELSE ''
					END,
					' (',
			  		CASE
						WHEN id_org_obs4 IS NOT NULL --si org4
							THEN (SELECT coalesce( NULLIF(org4.abb,'') ,org4.nom) --org_obs4
								FROM referentiels.organisme org4
								WHERE rel.id_org_obs4 = org4.id_org )
						ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
					END,')',
					concat(' [',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs4)),']') -- uuid obs4
						   )
			ELSE NULL
		END,
		CASE 
			WHEN rel.id_obs5 IS NOT NULL --obs5
				THEN concat(obs5.nom,' ', obs5.prenom, 
					CASE
						WHEN obs5.email IS NOT NULL AND obs5.email != '' --si email obs5
							THEN concat(' <', obs5.email,'>') --email obs5
						ELSE ''
					END,
					' (',
			  		CASE
						WHEN id_org_obs5 IS NOT NULL --si org5
							THEN (SELECT coalesce( NULLIF(org5.abb,'') ,org5.nom) --org_obs5
								FROM referentiels.organisme org5
								WHERE rel.id_org_obs5 = org5.id_org )
						ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
					END,')',
					concat(' [',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs5)),']') -- uuid obs5
						   )
			ELSE NULL
		END
		)


	FROM flore.releve rel
		LEFT JOIN referentiels.observateur obs1 on rel.id_obs1 = obs1.id_obs
    	LEFT JOIN referentiels.observateur obs2 on rel.id_obs2 = obs2.id_obs
		LEFT JOIN referentiels.observateur obs3 on rel.id_obs3 = obs3.id_obs
		LEFT JOIN referentiels.observateur obs4 on rel.id_obs4 = obs4.id_obs
		LEFT JOIN referentiels.observateur obs5 on rel.id_obs5 = obs5.id_obs
		LEFT JOIN referentiels.organisme orgf on rel.id_org_f = orgf.id_org
	WHERE rel.id_releve = $1;
	
return generate_observers;

END;
$function$
;



-- Requête export_synthese_initialisation

COPY (

	WITH

		evee AS (
			SELECT rt.cd_ref
			FROM referentiels.reglementation_taxon rt
			WHERE rt.id_reglementation::text = ANY (ARRAY['EVEE_EME'::character varying, 'EVEE_MAJ'::character varying, 'EVEE_MOD'::character varying]::text[])
			GROUP BY rt.cd_ref
			),
		sensi_reg AS (
			SELECT rt.cd_ref
			FROM referentiels.reglementation_taxon rt
			WHERE rt.id_reglementation::text = 'SENSI_PACA'::TEXT OR rt.id_reglementation::TEXT = 'SENSI_AURA'::TEXT 
			GROUP BY rt.cd_ref
			),
		sensi_dep AS (
			SELECT rt.cd_ref,
				"right"(rt.id_reglementation::text, 2) AS dept
			FROM referentiels.reglementation_taxon rt
			WHERE rt.id_reglementation ILIKE '%SENSI_AURA_%'
			GROUP BY rt.cd_ref, ("right"(rt.id_reglementation::text, 2))
			)
	SELECT 
	o.id_observation_sinp AS unique_id_sinp,
	r.id_releve_sinp AS unique_id_sinp_grp,
	o.id_observation::varchar(25) AS source_id,
	r.id_releve::varchar(25) AS source_id_grp,
		CASE
			WHEN r.id_org_f = 2785 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74') THEN 'flora_cbna'
			WHEN r.meta_id_groupe = 1 AND r.id_org_f <> 2785 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74') THEN ovf.nom
			WHEN r.id_org_f IS NOT NULL AND r.meta_id_groupe <> 1 AND r.id_org_f <> 2785 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74') THEN ovf.nom
			ELSE NULL
		END AS code_source,		
	mj.lib_jdd_court::varchar(255) AS code_dataset,
		CASE
			WHEN r.id_precision = 'P'::bpchar OR r.id_releve_methode = 10 THEN 'St'::TEXT -- St : Stationnel
			WHEN r.id_precision = ANY (ARRAY['T'::bpchar, 'C'::bpchar]) THEN 'In'::TEXT -- In : Inventoriel
			ELSE 'NSP'::text
		END AS code_nomenclature_geo_object_nature,
	'REL'::text AS code_nomenclature_grp_typ,
	rm.lib AS grp_method,
	'0'::text AS code_nomenclature_obs_technique, -- 0 : Vu
	'1'::text AS code_nomenclature_bio_status, -- 1 : Non renseigné
	'2'::text AS code_nomenclature_bio_condition, -- 2 : vivant
		CASE
			WHEN o.id_deg_nat = ANY (ARRAY[1, 2, 3]) THEN '5'::TEXT -- 5 : Subspontané
			WHEN o.id_deg_nat = 4 THEN '3'::TEXT  -- 3 : Planté
			WHEN o.id_deg_nat = 5 THEN '0'::TEXT  -- 0 : Inconnu
			WHEN o.id_deg_nat IS NULL THEN '1'::TEXT --1 : Sauvage
			ELSE NULL::text
		END AS code_nomenclature_naturalness,
		CASE
			WHEN o.id_herbier1 > 0 THEN '1'::TEXT -- 1 : Oui
			ELSE '2'::TEXT -- 1 : Oui
		END AS code_nomenclature_exist_proof,
	o.valid_reg::varchar(25) AS code_nomenclature_valid_status,
		CASE
			WHEN r.sinp_dspublique::text = ANY (ARRAY['Pu'::character varying, 'Re'::character varying, 'Ac'::character varying]::text[]) THEN 5
		ELSE COALESCE(r.sinp_difnivprec::integer, 0)
		END::varchar(25) AS code_nomenclature_diffusion_level,
	'0'::text AS code_nomenclature_life_stage, -- 0 : Inconnu
		CASE
			WHEN o.sexe = 'M'::bpchar THEN '3'::TEXT -- 3 : Mâle
			WHEN o.sexe = 'F'::bpchar THEN '2'::TEXT -- 2 : Femelle
			WHEN o.sexe = 'H'::bpchar THEN '4'::TEXT --4 : Hermaphrodite
			ELSE '6'::TEXT -- 6 : Non renseigné
		END AS code_nomenclature_sex,
	'NSP'::text AS code_nomenclature_obj_count,
	'NSP'::text AS code_nomenclature_type_count,
		CASE
			WHEN COALESCE(se.cd_ref, sed.cd_ref) IS NOT NULL THEN 1
			ELSE 0
		END::varchar(25) AS code_nomenclature_sensitivity,
	'Pr'::text AS code_nomenclature_observation_status, -- Pr : Présent 
	NULL::character varying(25) AS code_nomenclature_blurring,
		CASE
			WHEN r.id_releve_type::text = 'BIB'::text 
				OR r.id_releve_type::text = 'NM'::text AND r.id_biblio IS NOT NULL THEN 'Li'::TEXT -- Li : Littérature
			WHEN (r.id_releve_type::text = ANY (ARRAY['RT'::character varying, 'COM'::character varying]::text[]))
				OR r.id_releve_type::text = 'NM'::text AND r.id_biblio IS NULL THEN 'Te'::TEXT -- Te : Terrain
			WHEN r.id_releve_type::text = 'HB'::text THEN 'Co'::TEXT -- Co : Collection
			WHEN r.id_releve_type::text = 'I'::text THEN 'NSP'::text
			ELSE NULL::text
		END AS code_nomenclature_source_status,
		CASE
			WHEN r.id_precision = ANY (ARRAY['P'::bpchar, 'T'::bpchar, 'A'::bpchar]) THEN '1'::TEXT -- 1 : Géoréférencement
			WHEN r.id_precision = 'C'::bpchar THEN '2'::TEXT -- 2 : Rattachement
			ELSE NULL::text
		END AS code_nomenclature_info_geo_type,
	'0'::text AS code_nomenclature_behaviour, -- 0 : Inconnu 
		CASE cd.id_indigenat
			WHEN 1 THEN '2'::TEXT -- 2 : Présent
			WHEN 2 THEN '0'::TEXT -- 0 : Inconnu
			WHEN 3 THEN '2'::TEXT -- 2 : Présent
			WHEN 4 THEN
				CASE
					WHEN e.cd_ref IS NOT NULL THEN '4'::TEXT -- 4 : Introduit envahissant
					ELSE '3'::TEXT -- 3 : Introduit
				END
			ELSE '1'::TEXT -- 1 : Non renseigné
		END AS code_nomenclature_biogeo_status,
		CASE
			WHEN r.id_biblio IS NOT NULL THEN concat(b.auteurs, ', ', b.annee, '. ', b.titre)
			ELSE NULL::text
		END AS reference_biblio,
	COALESCE(o.nombre_pieds::integer, np.nb_min) AS count_min,
	COALESCE(o.nombre_pieds::integer, np.nb_max) AS count_max,
	CASE
		WHEN o.cd_ref < 15
			THEN o.cd_ref + 30000000
		ELSE o.cd_ref
	END AS cd_nom,
	NULL::integer AS cd_hab,
		CASE
			WHEN o.nom_taxon IS NOT NULL
				THEN o.nom_taxon::varchar(1000)
			ELSE ''
		END AS nom_cite,
	NULL::text AS digital_proof,
	NULL::text AS non_digital_proof,
	LEAST(NULLIF(r.alti_inf, 0) , r.alti_calc) AS altitude_min,
	GREATEST(NULLIF(r.alti_sup, 0), r.alti_calc) AS altitude_max,
	NULL::text AS depth_min,
	NULL::text AS depth_max,
		CASE
			WHEN r.lieudit  != '' 
				THEN jsonb_build_object('lieudit', jsonb_build_object('lieuditName', r.lieudit, 'locationComment', r.comm_loc))
		ELSE '{"lieudit": null}'
		END::varchar(500) AS place_name,
		st_geomfromtext(
	--  st_geomfromewkt(  
		CASE
				WHEN r.id_precision = 'P'::bpchar THEN st_asewkt(COALESCE(st_transform(r.geom_pres_4326, 2154), r.geom_2154))
				WHEN r.id_precision = ANY (ARRAY['T'::bpchar, 'A'::bpchar, 'C'::bpchar]) THEN st_asewkt(COALESCE(r.geom_2154, st_centroid(st_transform(r.geom_prosp_4326, 2154))))
				ELSE NULL::text
			END) AS geom,
		COALESCE(r.resolution,
			CASE r.id_precision
				WHEN 'P'::bpchar THEN 10
				WHEN 'T'::bpchar THEN 800
				ELSE NULL::integer
			END) AS "precision",  
	r.date_releve_deb::timestamp AS date_min,
	r.date_releve_fin::timestamp AS date_max,
		CASE
			WHEN o.meta_type_valid::text = 'a_v1'::text THEN NULL::text
			ELSE concat(concat_ws(' '::text, val.nom, val.prenom), ' (', COALESCE(ov.abb, ov.nom, 'Inconnu'::character varying), ')')
		END AS "validator", 
		NULL::text AS validation_comment,
		COALESCE(o.meta_date_valid, o.meta_date_maj)::timestamp AS validation_date,
	flore.generate_observers(r.id_releve, ', '::character varying) AS observers,  
	concat(
		CASE 
			WHEN o.id_det IS NOT NULL 
				THEN concat(upper(det.nom),' ', COALESCE (det.prenom, ''))
				ELSE 'INCONNU'
		END,
		CASE 
			WHEN det.email IS NOT NULL AND det.email != '' 
				THEN concat(' ','<', det.email,'>')
			ELSE ''
		END
		)
	AS determiner,
	NULL::timestamp AS determination_date,
	dig.permid::varchar(50) AS code_digitiser,
	1::varchar(25) AS code_nomenclature_determination_method,
	r.comm_date AS comment_context,
	NULL::text AS comment_description,
	jsonb_strip_nulls(
			CASE
				WHEN r.id_org_f IS NOT NULL
					THEN jsonb_build_object('fournisseur', jsonb_build_object('idOrgF', r.id_org_f, 'nomOrgF', ovf.nom))
				ELSE jsonb_build_object('fournisseur', null)
			END ||     
			public.build_simple_json_object('idObs1', r.id_obs1) ||
			public.build_simple_json_object('idObs2', r.id_obs2) ||
			public.build_simple_json_object('idObs3', r.id_obs3) ||
			public.build_simple_json_object('idObs4', r.id_obs4) ||
			public.build_simple_json_object('idObs5', r.id_obs5) ||  
			public.build_simple_json_object('commune', c.nom_min) ||
			public.build_simple_json_object('metaIdGroupe', r.meta_id_groupe) ||
			public.build_simple_json_object('metaIdProg', r.meta_id_prog) ||
			public.build_simple_json_object('inseeReg', r.insee_reg) ||
			CASE
				WHEN h.nom != ''
				THEN jsonb_build_object('herbier', jsonb_build_object('nomHerbier', h.nom, 'partHerbier', o.part_herbier1, 'idHerbier', o.id_herbier1))
				else jsonb_build_object('herbier', null)    			
			END ||
			public.build_simple_json_object('codePerso', r.code_perso) ||
			public.build_simple_json_object('codeGps', r.code_gps) ||
			CASE
				WHEN r.meta_id_prog IS NOT NULL
					THEN jsonb_build_object('metaNomProg', p.nom)
				ELSE '{"metaNomProg": null}'
			END ||
			public.build_simple_json_object('metaIdUserSaisie', r.meta_id_user_saisie) ||
			public.build_simple_json_object('sinpDspublique', r.sinp_dspublique) ||        
			CASE t.tax_type
					WHEN 'P'::bpchar THEN '{"taxTypeLabel": "Plantes vasculaires"}'::TEXT
					WHEN 'B'::bpchar THEN '{"taxTypeLabel": "Bryophytes"}'::TEXT 
					WHEN 'L'::bpchar THEN '{"taxTypeLabel": "Lichens"}'::text
					WHEN 'C'::bpchar THEN '{"taxTypeLabel": "Champignons"}'::TEXT
					WHEN 'A'::bpchar THEN '{"taxTypeLabel": "Algues"}'::TEXT 
				ELSE '{"taxType": null}'
			END::jsonb||
			jsonb_build_object('cd_nom', o.cd_nom)
			)
	AS additionnal_data,
	r.meta_date_saisie::timestamp AS meta_create_date,
	GREATEST(o.meta_date_maj, r.meta_date_maj)::timestamp AS meta_update_date,
	'I' AS meta_last_action 
	FROM flore.releve r
		JOIN flore.observation o ON r.id_releve = o.id_releve
		JOIN sinp.metadata_jdd mj ON r.id_jdd = mj.id_jdd
		LEFT JOIN referentiels.releve_methode rm ON r.id_releve_methode = rm.id_releve_methode
		LEFT JOIN referentiels.biblio b ON r.id_biblio = b.id_biblio
		LEFT JOIN referentiels.nombre_pieds np ON o.id_nombre_pieds = np.id_nombre_pieds
		LEFT JOIN referentiels.observateur det ON det.id_obs = o.id_det
		LEFT JOIN applications.utilisateur val ON val.id_user = o.meta_id_user_valid
		LEFT JOIN applications.utilisateur dig ON dig.id_user = r.meta_id_user_saisie
		LEFT JOIN referentiels.organisme ov ON val.id_org = ov.id_org AND det.meta_id_groupe = ov.meta_id_groupe
		LEFT JOIN referentiels.organisme ovf ON r.id_org_f = ovf.id_org
		LEFT JOIN referentiels.catalog_dept cd ON cd.insee_dept = r.insee_dept AND cd.cd_ref = o.cd_ref
		LEFT JOIN referentiels.commune c ON r.insee_comm = c.insee_comm
		LEFT JOIN referentiels.taxref t ON o.cd_nom = t.cd_nom
		LEFT JOIN referentiels.programme p ON r.meta_id_prog = p.id_prog
		LEFT JOIN referentiels.herbier h ON o.id_herbier1 = h.id_herbier
		LEFT JOIN evee e ON e.cd_ref = o.cd_ref
		LEFT JOIN sensi_reg se ON se.cd_ref = o.cd_ref
		
		LEFT JOIN sensi_dep sed ON sed.cd_ref = o.cd_ref AND sed.dept = r.insee_dept::TEXT AND sed.dept IN ('01', '26', '38', '73', '74')
	WHERE
		(r.meta_id_groupe = 1
			OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))

) TO '/tmp/synthese.csv' WITH(format csv, header, delimiter E'\t', null '\N');






















