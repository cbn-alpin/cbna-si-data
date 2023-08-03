-- Requête export_synthese_initialisation
--CREATE TEMP TABLE temp_det_org
--AS
--SELECT 
--r.id_obs1,
--r.id_org_obs1,
--o.nom
--FROM flore.releve r
--JOIN referentiels.organisme o ON o.id_org = r.id_org_obs1 
--WHERE
--	(r.meta_id_groupe = 1
--		OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
--	CREATE INDEX temp_det_org_id_obs1_idx ON temp_det_org USING btree(id_obs1);
--ON COMMIT DROP ROWS
--DROP TABLE temp_det_org;
WITH
--	det_org AS(
--		SELECT 
--			r.id_obs1,
--			r.id_org_obs1,
--			o.nom
--		FROM flore.releve r
--		JOIN referentiels.organisme o ON o.id_org = r.id_org_obs1 
--		WHERE
--		(r.meta_id_groupe = 1
--			OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))),
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
o.id_observation AS source_id,
r.id_releve AS source_id_grp,
'Simethis'::text AS code_source,
mj.lib_jdd_court AS code_dataset,
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
o.valid_reg AS code_nomenclature_valid_status,
	CASE
    	WHEN r.sinp_dspublique::text = ANY (ARRAY['Pu'::character varying, 'Re'::character varying, 'Ac'::character varying]::text[]) THEN 5
    ELSE COALESCE(r.sinp_difnivprec::integer, 0)
    END AS code_nomenclature_diffusion_level,
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
    END AS code_nomenclature_sensitivity,
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
o.cd_ref AS cd_nom,
NULL::integer AS cd_hab,
o.nom_taxon AS nom_cite,
NULL::text AS digital_proof,
NULL::text AS non_digital_proof,
LEAST(NULLIF(r.alti_inf, 0), r.alti_calc) AS altitude_min,
GREATEST(NULLIF(r.alti_sup, 0), r.alti_calc) AS altitude_max,
NULL::text AS depth_min,
NULL::text AS depth_max,
	CASE
    	WHEN r.lieudit  != '' 
        	THEN jsonb_build_object('lieudit', jsonb_build_object('lieuditName', r.lieudit, 'locationComment', r.comm_loc))
       ELSE '{"lieudit": null}'
    END AS place_name,
st_geomfromtext(
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
r.date_releve_deb AS date_min,
r.date_releve_fin AS date_max,
	CASE
    	WHEN o.meta_type_valid::text = 'a_v1'::text THEN NULL::text
        ELSE concat(concat_ws(' '::text, val.nom, val.prenom), ' (', COALESCE(ov.abb, ov.nom, 'Inconnu'::character varying), ')')
    END AS "validator", 
    NULL::text AS validation_comment,
    COALESCE(o.meta_date_valid, o.meta_date_maj) AS validation_date,
--flore.obs_plus_orga(r.id_releve, ', '::character varying) AS observers,
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
--	CASE  
--		WHEN o.id_det IS NOT NULL
--			THEN concat(' ', '(', COALESCE(tdo.nom, 'Inconnu'),')')  
--		ELSE 
--			CASE 
--				WHEN o.id_det IS NOT NULL AND tdo.nom IS NULL
--					THEN concat(' ','Indépendant.e')
--			END
--	END,
--	CASE 
--		WHEN o.id_det IS NOT NULL AND ovf.nom IS NULL
--			THEN concat(' ','Indépendant.e')
--	END
	)
AS determiner,
NULL::text AS determination_date,
r.meta_id_user_saisie AS code_digitiser,
1 AS code_nomenclature_determination_method,
r.comm_date AS comment_context,
NULL::text AS comment_description,
jsonb_strip_nulls(
        CASE
        	WHEN r.id_org_f IS NOT NULL
        		THEN jsonb_build_object('fournisseur', jsonb_build_object('idOrgF', r.id_org_f, 'nomOrgF', ovf.nom))
        	ELSE jsonb_build_object('fournisseur', null)
        END ||     
        CASE
        	WHEN r.id_obs1 IS NOT NULL
        		THEN jsonb_build_object('idObs1', r.id_obs1)-- a voir fonction obs_plus_orga
        	ELSE '{"idObs1": null}'
        END ||
        CASE
        	WHEN r.id_obs2 IS NOT NULL 
        		THEN jsonb_build_object('idObs2', r.id_obs2)
        	ELSE '{"idObs2": null}'
        END ||
        CASE
        	WHEN r.id_obs3 IS NOT NULL 
        		THEN jsonb_build_object('idObs3', r.id_obs3)
        	ELSE '{"idObs3": null}'	
        END ||
        CASE
        	WHEN r.id_obs4 IS NOT NULL
        		THEN jsonb_build_object('idObs4', r.id_obs4)
        	ELSE '{"idObs4": null}'
        END ||
        CASE
        	WHEN r.id_obs5 IS NOT NULL
        		THEN jsonb_build_object('idObs5', r.id_obs5)
        	ELSE '{"idObs5": null}'
        END ||       
		CASE
            WHEN c.nom_min != '' 
            	THEN jsonb_build_object('commune', c.nom_min)
            ELSE '{"commune": null}'
        END ||
        CASE
        	WHEN r.meta_id_groupe IS NOT NULL
        		THEN jsonb_build_object('metaIdGroupe', r.meta_id_groupe)
        	ELSE '{"metaIdGroupe": null}'
        END ||
        CASE
        	WHEN r.meta_id_prog IS NOT NULL 
        		THEN jsonb_build_object('metaIdProg', r.meta_id_prog)
        	ELSE '{"metaIdProg": null}'
        END ||
        CASE
        	WHEN r.insee_reg != ''
        		THEN jsonb_build_object('inseeReg', r.insee_reg)
        	ELSE '{"inseeReg": null}'
        END ||
        CASE
	        WHEN h.nom != ''
	        THEN jsonb_build_object('herbier', jsonb_build_object('nomHerbier', h.nom, 'partHerbier', o.part_herbier1, 'idHerbier', o.id_herbier1))
   			else jsonb_build_object('herbier', null)    			
        END ||
        CASE
        	WHEN r.code_perso != ''
        		THEN jsonb_build_object('codePerso', r.code_perso)
        	ELSE '{"codePerso": null}'
        END ||
        CASE
        	WHEN r.code_gps IS NOT NULL
        		THEN jsonb_build_object('codeGps', r.code_gps)
        	ELSE '{"codeGps": null}'
        END ||
        CASE
        	WHEN r.meta_id_prog IS NOT NULL
        		THEN jsonb_build_object('metaNomProg', p.nom)
        	ELSE '{"metaNomProg": null}'
        END ||
        CASE
        	WHEN r.meta_id_user_saisie IS NOT NULL
        		THEN jsonb_build_object('metaIdUserSaisie', r.meta_id_user_saisie)
        	ELSE '{"metaIdUserSaisie": null}'
        END || 
        CASE
        	WHEN r.sinp_dspublique IS NOT NULL
        		THEN jsonb_build_object('sinpDspublique', r.sinp_dspublique)
        	ELSE '{"sinpDspublique": null}'
        END ||
        CASE t.tax_type
        		WHEN 'P'::bpchar THEN '{"taxTypeLabel": "Plantes vasculaires"}'::TEXT
        		WHEN 'B'::bpchar THEN '{"taxTypeLabel": "Bryophytes"}'::TEXT 
            	WHEN 'L'::bpchar THEN '{"taxTypeLabel": "Lichens"}'::text
            	WHEN 'C'::bpchar THEN '{"taxTypeLabel": "Champignons"}'::TEXT
            	WHEN 'A'::bpchar THEN '{"taxTypeLabel": "Algues"}'::TEXT 
        	ELSE '{"taxType": null}'
        END::jsonb)
AS additionnal_data,
r.meta_date_saisie AS meta_create_date,
GREATEST(o.meta_date_maj, r.meta_date_maj) AS meta_update_date,
'I' AS meta_last_action 
FROM flore.releve r
	JOIN flore.observation o ON r.id_releve = o.id_releve
    JOIN sinp.metadata_jdd mj ON r.id_jdd = mj.id_jdd
	LEFT JOIN referentiels.releve_methode rm ON r.id_releve_methode = rm.id_releve_methode
	LEFT JOIN referentiels.biblio b ON r.id_biblio = b.id_biblio
	LEFT JOIN referentiels.nombre_pieds np ON o.id_nombre_pieds = np.id_nombre_pieds
	LEFT JOIN referentiels.observateur det ON det.id_obs = o.id_det
    LEFT JOIN applications.utilisateur val ON val.id_user = o.meta_id_user_valid 
    LEFT JOIN referentiels.organisme ov ON val.id_org = ov.id_org AND det.meta_id_groupe = ov.meta_id_groupe
    LEFT JOIN referentiels.organisme ovf ON r.id_org_f = ovf.id_org
    LEFT JOIN referentiels.catalog_dept cd ON cd.insee_dept = r.insee_dept AND cd.cd_ref = o.cd_ref
	LEFT JOIN referentiels.commune c ON r.insee_comm = c.insee_comm
	LEFT JOIN referentiels.taxref t ON o.cd_nom = t.cd_nom
	LEFT JOIN referentiels.programme p ON r.meta_id_prog = p.id_prog
	LEFT JOIN referentiels.herbier h ON o.id_herbier1 = h.id_herbier
    LEFT JOIN evee e ON e.cd_ref = o.cd_ref
    LEFT JOIN sensi_reg se ON se.cd_ref = o.cd_ref
	--LEFT JOIN det_org dor ON dor.id_obs1 = r.id_obs1
	--LEFT JOIN temp_det_org tdo ON tdo.id_obs1 = r.id_obs1
    LEFT JOIN sensi_dep sed ON sed.cd_ref = o.cd_ref AND sed.dept = r.insee_dept::TEXT AND sed.dept IN ('01', '26', '38', '73', '74')
WHERE
	(r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
--DROP TABLE temp_det_org;
--limit 100
;





