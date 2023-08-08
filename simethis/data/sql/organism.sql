SELECT DISTINCT
	COALESCE (
		(CASE
			WHEN ov.uuid_national ~* '^\s*$'
			THEN NULL 
			WHEN ov.uuid_national IS NOT NULL 
			THEN ov.uuid_national
		 END), ov.permid::varchar)
	AS unique_id,
	ov.nom AS name,
	ov.adresse AS adress,
	CASE
		WHEN ov.cp ~* '^\s*$'
			THEN NULL
		WHEN ov.cp IS NOT NULL
			THEN ov.cp
		ELSE NULL
	END AS postal_code,
	CASE
		WHEN ov.ville ~* '^\s*$'
			THEN NULL
		WHEN ov.ville IS NOT NULL
			THEN ov.ville
		ELSE NULL
	END AS city,
	CASE
		WHEN ov.tel ~* '^\s*$'
			THEN NULL
		WHEN ov.tel IS NOT NULL 
			THEN ov.tel
		ELSE NULL
	END AS phone,
	NULL::bpchar AS fax,
	CASE
		WHEN ov.email ~* '^\s*$'
			THEN NULL
		WHEN ov.email IS NOT NULL
			THEN ov.email
		ELSE NULL
	END AS email,	
	CASE
		WHEN ov.web ~* '^\s*$'
			THEN NULL
		WHEN ov.web IS NOT NULL
			THEN ov.web
		ELSE NULL
	END AS url,
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
JOIN flore.releve r ON r.id_org_f = ov.id_org 
	OR r.id_org_obs1 = ov.id_org OR r.id_org_obs2 = ov.id_org OR r.id_org_obs3 = ov.id_org OR r.id_org_obs4 = ov.id_org OR r.id_org_obs5 = ov.id_org
WHERE (r.meta_id_groupe = 1
	OR  (r.meta_id_groupe <> 1
	AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
;

