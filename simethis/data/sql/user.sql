--COPY ( 
(
WITH
-- CTE Relevés d'observations produites sur le territoire du CBNA
	releves_siAlp AS( 
		SELECT rel.id_releve 
		FROM flore.releve rel
		WHERE
		(rel.meta_id_groupe = 1
			OR  (rel.meta_id_groupe <> 1 AND rel.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
	)
-- Observateurs du territoire d'agrément du CBNA
SELECT DISTINCT ON (observers.unique_id) *
FROM (  	

	SELECT
	 	concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs1)))::uuid AS unique_id, -- obs1
	 	NULL AS identifier,
	    CASE 
	    	WHEN o.prenom IS NOT NULL AND o.prenom !~* '^\s*$'
	    		THEN o.prenom
	    	ELSE NULL
	    END AS firstname,
	    o.nom AS "name",
	    CASE 
	    	WHEN o.email IS NOT NULL AND o.email !~* '^\s*$'
	    		THEN o.email
	    	ELSE NULL
	    END AS email,
	    COALESCE(org.uuid_national, org.permid::varchar) AS code_organism,
	    CASE 
	    	WHEN o.comm IS NOT NULL AND o.comm !~* '^\s*$'
	    		THEN o.comm
	    	ELSE NULL
	    END AS "comment",
	    NULL::boolean AS "enable",
	    jsonb_build_object(
	    	'code', o.code, 'idGroupe', o.meta_id_groupe, 'anneeNai', o.annee_nai , 'anneeDec', o.annee_dec
	    )::jsonb AS additional_data,
	    o.meta_date_saisie::timestamp AS meta_create_date,
	    o.meta_date_maj::timestamp AS meta_update_date,
	    'I'::char(1) AS meta_last_action
	FROM flore.releve r
		JOIN referentiels.observateur o ON o.id_obs = r.id_obs1
		LEFT JOIN referentiels.organisme org ON org.id_org = r.id_org_f
--	WHERE
--		(r.meta_id_groupe = 1
--			OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs1 IS NOT NULL
		JOIN releves_siAlp relsi ON relsi.id_releve = r.id_releve 
		
	UNION
	
	SELECT
	    concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs2)))::uuid AS unique_id, --obs2
	 	NULL AS identifier,
	    CASE 
	    	WHEN o.prenom IS NOT NULL AND o.prenom !~* '^\s*$'
	    		THEN o.prenom
	    	ELSE NULL
	    END AS firstname,
	    o.nom AS "name",
	    CASE 
	    	WHEN o.email IS NOT NULL AND o.email !~* '^\s*$'
	    		THEN o.email
	    	ELSE NULL
	    END AS email,
	    COALESCE(org.uuid_national, org.permid::varchar) AS code_organism,
	    CASE 
	    	WHEN o.comm IS NOT NULL AND o.comm !~* '^\s*$'
	    		THEN o.comm
	    	ELSE NULL
	    END AS "comment",
	    NULL::boolean AS "enable",
	    jsonb_build_object(
	    	'code', o.code, 'idGroupe', o.meta_id_groupe, 'anneeNai', o.annee_nai , 'anneeDec', o.annee_dec
	    )::jsonb AS additional_data,
	    o.meta_date_saisie::timestamp AS meta_create_date,
	    o.meta_date_maj::timestamp AS meta_update_date,
	    'I'::char(1) AS meta_last_action
	FROM flore.releve r
		JOIN referentiels.observateur o ON o.id_obs = r.id_obs2
		LEFT JOIN referentiels.organisme org ON org.id_org = r.id_org_f
--	WHERE
--		(r.meta_id_groupe = 1
--			OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs2 IS NOT NULL
		JOIN releves_siAlp relsi ON relsi.id_releve = r.id_releve 
	
	UNION
	
	SELECT
	 	concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs3)))::uuid AS unique_id, --obs3
	 	NULL AS identifier,
	    CASE 
	    	WHEN o.prenom IS NOT NULL AND o.prenom !~* '^\s*$'
	    		THEN o.prenom
	    	ELSE NULL
	    END AS firstname,
	    o.nom AS "name",
	    CASE 
	    	WHEN o.email IS NOT NULL AND o.email !~* '^\s*$'
	    		THEN o.email
	    	ELSE NULL
	    END AS email,
	    COALESCE(org.uuid_national, org.permid::varchar) AS code_organism,
	    CASE 
	    	WHEN o.comm IS NOT NULL AND o.comm !~* '^\s*$'
	    		THEN o.comm
	    	ELSE NULL
	    END AS "comment",
	    NULL::boolean AS "enable",
	    jsonb_build_object(
	    	'code', o.code, 'idGroupe', o.meta_id_groupe, 'anneeNai', o.annee_nai , 'anneeDec', o.annee_dec
	    )::jsonb AS additional_data,
	    o.meta_date_saisie::timestamp AS meta_create_date,
	    o.meta_date_maj::timestamp AS meta_update_date,
	    'I'::char(1) AS meta_last_action
	FROM flore.releve r
		JOIN referentiels.observateur o ON o.id_obs = r.id_obs3
		LEFT JOIN referentiels.organisme org ON org.id_org = r.id_org_f
--	WHERE
--		(r.meta_id_groupe = 1
--			OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs3 IS NOT NULL
		JOIN releves_siAlp relsi ON relsi.id_releve = r.id_releve 
	
	UNION
	
	SELECT
	 	concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs4)))::uuid AS unique_id, --obs4
	 	NULL AS identifier,
	    CASE 
	    	WHEN o.prenom IS NOT NULL AND o.prenom !~* '^\s*$'
	    		THEN o.prenom
	    	ELSE NULL
        END AS firstname,
	    o.nom AS "name",
	    CASE 
	    	WHEN o.email IS NOT NULL AND o.email !~* '^\s*$'
	    		THEN o.email
	    	ELSE NULL
	    END AS email,
	    COALESCE(org.uuid_national, org.permid::varchar) AS code_organism,
	    CASE 
	    	WHEN o.comm IS NOT NULL AND o.comm !~* '^\s*$'
	    		THEN o.comm
	    	ELSE NULL
	    END AS "comment",
	    NULL::boolean AS "enable",
	    jsonb_build_object(
	    	'code', o.code, 'idGroupe', o.meta_id_groupe, 'anneeNai', o.annee_nai , 'anneeDec', o.annee_dec
	    )::jsonb AS additional_data,
	    o.meta_date_saisie::timestamp AS meta_create_date,
	    o.meta_date_maj::timestamp AS meta_update_date,
	    'I'::char(1) AS meta_last_action
	FROM flore.releve r
		JOIN referentiels.observateur o ON o.id_obs = r.id_obs4
		LEFT JOIN referentiels.organisme org ON org.id_org = r.id_org_f
--	WHERE
--		(r.meta_id_groupe = 1
--			OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs4 IS NOT NULL
		JOIN releves_siAlp relsi ON relsi.id_releve = r.id_releve 
		
	UNION
	
	SELECT
	 	concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs5)))::uuid AS unique_id, --obs5
	 	NULL AS identifier,
	    CASE 
	    	WHEN o.prenom IS NOT NULL AND o.prenom !~* '^\s*$'
	    		THEN o.prenom
	    	ELSE NULL
	    END AS firstname,
	    o.nom AS "name",
	    CASE 
	    	WHEN o.email IS NOT NULL AND o.email !~* '^\s*$'
	    		THEN o.email
	    	ELSE NULL
	    END AS email,
	    COALESCE(org.uuid_national, org.permid::varchar) AS code_organism,
	    CASE 
	    	WHEN o.comm IS NOT NULL AND o.comm !~* '^\s*$'
	    		THEN o.comm
	    	ELSE NULL
	    END AS "comment",
	    NULL::boolean AS "enable",
	    jsonb_build_object(
	    	'code', o.code, 'idGroupe', o.meta_id_groupe, 'anneeNai', o.annee_nai , 'anneeDec', o.annee_dec
	    )::jsonb AS additional_data,
	    o.meta_date_saisie::timestamp AS meta_create_date,
	    o.meta_date_maj::timestamp AS meta_update_date,
	    'I'::char(1) AS meta_last_action
	FROM flore.releve r
		JOIN referentiels.observateur o ON o.id_obs = r.id_obs5
		LEFT JOIN referentiels.organisme org ON org.id_org = r.id_org_f
--	WHERE
--		(r.meta_id_groupe = 1
--			OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs5 IS NOT NULL
		JOIN releves_siAlp relsi ON relsi.id_releve = r.id_releve 
	) AS observers

UNION

-- Utilisateurs du CBNA
(
SELECT DISTINCT ON (u.permid)
 	u.permid AS unique_id,
 	u.login AS identifier,
    CASE 
    	WHEN u.prenom IS NOT NULL AND u.prenom !~* '^\s*$'
    		THEN u.prenom
    	ELSE NULL
    END AS firstname,
    u.nom AS "name",
    CASE 
    	WHEN u.email IS NOT NULL AND u.email !~* '^\s*$'
    		THEN u.email
    	ELSE NULL
    END AS email,
    COALESCE(o.uuid_national, o.permid::varchar) AS code_organism, 
    CASE 
    	WHEN u.comm IS NOT NULL AND u.comm !~* '^\s*$'
    		THEN u.comm
    	ELSE NULL
    END AS "comment",
    NULL::boolean AS "enable",
    jsonb_build_object(
    	'code', u.code, 'idGroupe', u.id_groupe, 'password', u.pass, 'lastLogin', u.last_login, 'key', u."key"
    )::jsonb AS additional_data,
    u.meta_date_saisie::timestamp AS meta_create_date,
    u.meta_date_maj::timestamp AS meta_update_date,
    'I'::char(1) AS meta_last_action
FROM applications.utilisateur u
   JOIN referentiels.organisme o ON o.id_org = u.id_org 
WHERE u.id_groupe = 1
)

UNION 

-- Utilisateurs hors CBNA mais dont les observations se situent sur le territoire d'agrément
(
SELECT DISTINCT ON (u.permid) 
 	u.permid AS unique_id,
 	u.login AS identifier,
    CASE 
    	WHEN u.prenom IS NOT NULL AND u.prenom !~* '^\s*$'
    		THEN u.prenom
    	ELSE NULL
    END AS firstname,
    u.nom AS "name",
    CASE 
    	WHEN u.email IS NOT NULL AND u.email !~* '^\s*$'
    		THEN u.email
    	ELSE NULL
    END AS email,
    COALESCE(o.uuid_national, o.permid::varchar) AS code_organism, 
    CASE 
    	WHEN u.comm IS NOT NULL AND u.comm !~* '^\s*$'
    		THEN u.comm
    	ELSE NULL
    END AS "comment",
    NULL::boolean AS "enable",
    jsonb_build_object(
    	'code', u.code, 'idGroupe', u.id_groupe, 'password', u.pass, 'lastLogin', u.last_login, 'key', u."key"
    )::jsonb AS additional_data,
    u.meta_date_saisie::timestamp AS meta_create_date,
    u.meta_date_maj::timestamp AS meta_update_date,
    'I'::char(1) AS meta_last_action
FROM applications.utilisateur u
   JOIN flore.releve r ON r.meta_id_user_saisie  = u.id_user
   JOIN referentiels.organisme o ON o.id_org = u.id_org 
WHERE
	r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')
)
)
--) TO stdout
--WITH (format csv, header, delimiter E'\t')			
;
