--COPY (
( 
SELECT DISTINCT
 	concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs1))) AS unique_id, -- obs1
 	NULL AS identifier,
    o.prenom AS firstname,
    o.nom AS "name",
    o.email,
    org.nom::varchar(100) AS code_organism,
    CASE 
    	WHEN o.comm IS NOT NULL OR o.comm ~* '^\s*$'
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
WHERE
	(r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs1 IS NOT NULL 
	
UNION

SELECT DISTINCT
    concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs2))) AS unique_id, --obs2
 	NULL AS identifier,
    o.prenom AS firstname,
    o.nom AS "name",
    o.email,
    org.nom::varchar(100) AS code_organism,
    CASE 
    	WHEN o.comm IS NOT NULL OR o.comm ~* '^\s*$'
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
WHERE
	(r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs2 IS NOT NULL

UNION

SELECT DISTINCT
 	concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs3))) AS unique_id, --obs3
 	NULL AS identifier,
    o.prenom AS firstname,
    o.nom AS "name",
    o.email,
    org.nom::varchar(100) AS code_organism,
    CASE 
    	WHEN o.comm IS NOT NULL OR o.comm ~* '^\s*$'
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
WHERE
	(r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs3 IS NOT NULL

UNION

SELECT DISTINCT
 	concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs4))) AS unique_id, --obs4
 	NULL AS identifier,
    o.prenom AS firstname,
    o.nom AS "name",
    o.email,
    org.nom::varchar(100) AS code_organism,
    CASE 
    	WHEN o.comm IS NOT NULL OR o.comm ~* '^\s*$'
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
WHERE
	(r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs4 IS NOT NULL
	
UNION

SELECT DISTINCT
 	concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', r.id_obs5))) AS unique_id, --obs5
 	NULL AS identifier,
    o.prenom AS firstname,
    o.nom AS "name",
    o.email,
    org.nom::varchar(100) AS code_organism,
    CASE 
    	WHEN o.comm IS NOT NULL OR o.comm ~* '^\s*$'
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
WHERE
	(r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))) AND r.id_obs5 IS NOT NULL
)

UNION

( 
SELECT DISTINCT 
 	u.permid AS unique_id,
 	u.login AS identifier,
    u.prenom AS firstname,
    u.nom AS "name",
    u.email,
    CASE
	    WHEN u.id_org IS NOT NULL
	    	THEN u.id_org::varchar(100)
	    ELSE NULL
    END AS code_organism,
    CASE 
    	WHEN u.comm IS NOT NULL OR u.comm ~* '^\s*$'
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
   JOIN flore.releve r ON r.meta_id_groupe = u.id_groupe
   
WHERE
	(r.meta_id_groupe = 1
		OR  (r.meta_id_groupe <> 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
)
--) TO stdout
--WITH (format csv, header, delimiter E'\t')			
;
