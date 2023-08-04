WITH 
--	--j AS (
----         SELECT pej.cor_actors_user[1][1] AS j_user
----           FROM sinp.paca_export_jdd_1 pej
----          GROUP BY (pej.cor_actors_user[1][1])
----        )
	list_user AS (
         SELECT 
         	CASE
	         	WHEN r.id_obs1 IS NOT NULL THEN r.id_obs1
	         	WHEN r.id_obs2 IS NOT NULL THEN r.id_obs2
	         	WHEN r.id_obs3 IS NOT NULL THEN r.id_obs3
	         	WHEN r.id_obs4 IS NOT NULL THEN r.id_obs4
	         	WHEN r.id_obs5 IS NOT NULL THEN r.id_obs5
	         	ELSE NULL
	        END AS id_obs
         FROM flore.releve r)
----        	WHERE r.insee_dept = ANY (ARRAY['04'::bpchar, '05'::bpchar]))
--         WHERE
--			(r.meta_id_groupe != 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
 SELECT DISTINCT 
 	u.permid AS unique_id,
 	u.login AS identifier,
--    j.j_user AS identifier,
    u.prenom AS firstname,
    u.nom AS name,
    u.email,
    CASE
	    WHEN u.id_org IS NOT NULL
	    	THEN u.id_org::varchar(100)
	    ELSE NULL
    END AS code_organism,
    CASE 
    	WHEN u.comm IS NOT NULL OR u.comm != ''
    		THEN u.comm
    	ELSE NULL
    END AS "comment",
    NULL::boolean AS enable,
    jsonb_build_object(
    	'code', u.code, 'idGroupe', u.id_groupe, 'password', u.pass, 'lastLogin', u.last_login, 'key', u."key"
    )::jsonb AS additional_data,
    u.meta_date_saisie::timestamp AS meta_create_date,
    u.meta_date_maj::timestamp AS meta_update_date,
    'I'::char(1) AS meta_last_action
   FROM applications.utilisateur u
   JOIN flore.releve r ON r.meta_id_groupe = u.id_groupe
--   JOIN list_user l ON l.id_obs = u.id_user 
	WHERE
			(r.meta_id_groupe != 1 AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74'))
--  ORDER BY u.permid;
    ; 
