-- Création d'une table, laquelle sera supprimée en fin de script, des agents du CBNA des services Conservation et Connaissance
CREATE TABLE flore.cbna_agent(
	gid serial PRIMARY KEY,
	uuid uuid,
	last_name varchar(100),
	first_name varchar(100),
	entry_date date,
	release_date date
);

-- Insertion des données du fichier CSV dans la table
COPY flore.cbna_agent(last_name, first_name, entry_date, release_date)
	FROM :cbnaAgentCsvFilePath
DELIMITER ','
CSV HEADER;

-- Récupération des uuid des agents
UPDATE flore.cbna_agent AS ca
SET uuid = u.permid
FROM applications.utilisateur AS u
WHERE u.id_groupe = 1 AND lower(unaccent(u.nom)) = lower(unaccent(ca.last_name)) AND lower(unaccent(u.prenom)) = lower(unaccent(ca.first_name));

COPY (
	WITH
	-- CTE Relevés d'observations produites sur le territoire du CBNA, observateurs du territoire du CBNA
		releves_sialp AS( 
			SELECT 
				rel.id_releve,
				rel.date_releve_deb,
				rel.date_releve_fin,
				rel.id_obs1, 
				rel.id_obs2,
				rel.id_obs3,
				rel.id_obs4,
				rel.id_obs5, 
				COALESCE(org.uuid_national, org.permid::varchar) AS code_organism
			FROM flore.releve rel
				LEFT JOIN referentiels.organisme org ON org.id_org = rel.id_org_f
			WHERE
			(rel.meta_id_groupe = 1
				OR  (rel.meta_id_groupe <> 1 AND rel.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
		)
	-- Observateurs du territoire d'agrément du CBNA
	SELECT DISTINCT ON (observers.unique_id) *
	FROM (  	

		SELECT
			flore.check_cbna_agent(r.id_obs1, r.date_releve_deb) AS unique_id, --obs1
			NULL AS identifier,
			public.delete_space(o.prenom) AS firstname,
			o.nom AS "name",
			public.delete_space(o.email) AS email,
			r.code_organism,
			public.delete_space(o.comm) AS "comment",
			NULL::boolean AS "enable",
			jsonb_build_object(
				'code', o.code,
			    'idGroupe', o.meta_id_groupe, 
				'anneeNai', o.annee_nai , 
				'anneeDec', o.annee_dec, 
				'idObs', r.id_obs1
			)::jsonb AS additional_data,
			o.meta_date_saisie::timestamp AS meta_create_date,
			o.meta_date_maj::timestamp AS meta_update_date,
			'I'::char(1) AS meta_last_action   	
		FROM releves_sialp AS r
			JOIN referentiels.observateur o ON o.id_obs = r.id_obs1 
			
		UNION
		
		SELECT
			flore.check_cbna_agent(r.id_obs2, r.date_releve_deb ) AS unique_id, --obs2
			NULL AS identifier,
			public.delete_space(o.prenom) AS firstname,
			o.nom AS "name",
			public.delete_space(o.email) AS email,
			r.code_organism,
			public.delete_space(o.comm) AS "comment",
			NULL::boolean AS "enable",
			jsonb_build_object(
				'code', o.code, 
				'idGroupe', o.meta_id_groupe, 
				'anneeNai', o.annee_nai , 
				'anneeDec', o.annee_dec, 
				'idObs', r.id_obs2
			)::jsonb AS additional_data,
			o.meta_date_saisie::timestamp AS meta_create_date,
			o.meta_date_maj::timestamp AS meta_update_date,
			'I'::char(1) AS meta_last_action
		FROM releves_sialp AS r
			JOIN referentiels.observateur o ON o.id_obs = r.id_obs2
		
		UNION
		
		SELECT
			flore.check_cbna_agent(r.id_obs3, r.date_releve_deb) AS unique_id, --obs3
			NULL AS identifier,
			public.delete_space(o.prenom) AS firstname,
			o.nom AS "name",
			public.delete_space(o.email) AS email,
			r.code_organism,
			public.delete_space(o.comm) AS "comment",
			NULL::boolean AS "enable",
			jsonb_build_object(
				'code', o.code, 
				'idGroupe', o.meta_id_groupe, 
				'anneeNai', o.annee_nai , 
				'anneeDec', o.annee_dec,
				'idObs', r.id_obs3
			)::jsonb AS additional_data,
			o.meta_date_saisie::timestamp AS meta_create_date,
			o.meta_date_maj::timestamp AS meta_update_date,
			'I'::char(1) AS meta_last_action
		FROM releves_sialp AS r
			JOIN referentiels.observateur o ON o.id_obs = r.id_obs3 
		
		UNION
		
		SELECT
			flore.check_cbna_agent(r.id_obs4, r.date_releve_deb) AS unique_id, --obs4
			NULL AS identifier,
			public.delete_space(o.prenom) AS firstname,
			o.nom AS "name",
			public.delete_space(o.email) AS email,
			r.code_organism,
			public.delete_space(o.comm) AS "comment",
			NULL::boolean AS "enable",
			jsonb_build_object(
				'code', o.code, 
				'idGroupe', o.meta_id_groupe, 
				'anneeNai', o.annee_nai , 
				'anneeDec', o.annee_dec,
				'idObs', r.id_obs4
			)::jsonb AS additional_data,
			o.meta_date_saisie::timestamp AS meta_create_date,
			o.meta_date_maj::timestamp AS meta_update_date,
			'I'::char(1) AS meta_last_action
		FROM releves_sialp AS r
			JOIN referentiels.observateur o ON o.id_obs = r.id_obs4 
			
		UNION
		
		SELECT
			flore.check_cbna_agent(r.id_obs5, r.date_releve_deb) AS unique_id, --obs5
			NULL AS identifier,
			public.delete_space(o.prenom) AS firstname,
			o.nom AS "name",
			public.delete_space(o.email) AS email,
			r.code_organism,
			public.delete_space(o.comm) AS "comment",
			NULL::boolean AS "enable",
			jsonb_build_object(
				'code', o.code, 
				'idGroupe', o.meta_id_groupe, 
				'anneeNai', o.annee_nai , 
				'anneeDec', o.annee_dec,
				'idObs', r.id_obs5
			)::jsonb AS additional_data,
			o.meta_date_saisie::timestamp AS meta_create_date,
			o.meta_date_maj::timestamp AS meta_update_date,
			'I'::char(1) AS meta_last_action
		FROM releves_sialp AS r
			JOIN referentiels.observateur o ON o.id_obs = r.id_obs5
			
		) AS observers

	UNION

	-- Utilisateurs du CBNA
	(
	SELECT DISTINCT ON (u.permid)
		u.permid AS unique_id,
		u.login AS identifier,
		public.delete_space(u.prenom) AS firstname,
		u.nom AS "name",
		public.delete_space(u.email) AS email,
		COALESCE(o.uuid_national, o.permid::varchar) AS code_organism, 
		public.delete_space(u.comm) AS "comment",
		NULL::boolean AS "enable",
		jsonb_build_object(
			'code', u.code, 
			'idGroupe', u.id_groupe, 
			'password', u.pass, 
			'lastLogin', u.last_login, 
			'key', u."key"
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
		public.delete_space(u.prenom) AS firstname,
		u.nom AS "name",
		public.delete_space(u.email) AS email,
		COALESCE(o.uuid_national, o.permid::varchar) AS code_organism, 
		public.delete_space(u.comm) AS "comment",
		NULL::boolean AS "enable",
		jsonb_build_object(
			'code', u.code, 
			'idGroupe', u.id_groupe, 
			'password', u.pass, 
			'lastLogin', u.last_login, 
			'key', u."key"
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
) TO '/tmp/user.csv' WITH(format csv, header, delimiter E'\t', null '\N');

DROP TABLE IF EXISTS flore.cbna_agent;
