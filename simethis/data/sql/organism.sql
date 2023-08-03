--WITH unique_organism AS (
--    SELECT
--        r.id_org_f AS id_org
--    FROM flore.releve r
--    
--    UNION
--    
--    SELECT
--        r.id_org_obs1 AS id_org
--    FROM flore.releve r
--
--    UNION
--    
--    SELECT
--        r.id_org_obs2 AS id_org
--    FROM flore.releve r
--    
--    UNION
--    
--    SELECT
--        r.id_org_obs3 AS id_org
--    FROM flore.releve r
--    
--    UNION
--    
--    SELECT
--        r.id_org_obs4 AS id_org
--    FROM flore.releve r
--    
--    UNION
--    
--    SELECT
--        r.id_org_obs5 AS id_org
--    FROM flore.releve r
--)

SELECT DISTINCT
	CASE 
		WHEN ov.id_org IS NOT NULL
		THEN COALESCE (ov.uuid_national, ov.permid::TEXT)
		ELSE NULL
	END AS unique_id,
	ov.nom AS name,
	ov.adresse AS adress,
	ov.cp AS postal_code,
	ov.ville AS city,
	ov.tel AS phone,
	NULL::bpchar AS fax,
	ov.email AS email,
	ov.web AS url,
	NULL::bpchar AS logo_url,
	jsonb_strip_nulls(
		CASE
        	WHEN ov.id_org IS NOT NULL
        		THEN jsonb_build_object('infoSup',
        			jsonb_build_object('idOrg', ov.id_org, 'code', ov.code, 'pays', ov.pays, 'sinpDspublique', ov.sinp_dspublique, 'metaIdGroupe', ov.meta_id_groupe, 'comm', ov.comm, 'permid', ov.permid, 'fichier1', ov.fichier1))
        	ELSE jsonb_build_object('infoSup', null)
        END::jsonb) AS additional_data,	
	ov.meta_date_saisie::timestamp AS meta_create_date,
	ov.meta_date_maj::timestamp AS meta_update_date,
	'I' AS meta_last_action
FROM referentiels.organisme ov
--JOIN unique_organism uo ON ov.id_org = uo.id_org
--JOIN flore.releve r ON id_org_f = uo.id_org
	JOIN flore.releve r ON r.id_org_f = ov.id_org 
		OR r.id_org_obs1 = ov.id_org OR r.id_org_obs2 = ov.id_org OR r.id_org_obs3 = ov.id_org OR r.id_org_obs4 = ov.id_org OR r.id_org_obs5 = ov.id_org
--		AND r.meta_id_groupe = ov.meta_id_groupe 
--	LEFT JOIN flore.releve rgrp ON rgrp.meta_id_groupe = ov.meta_id_groupe 
WHERE (r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1
		AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
;

 
