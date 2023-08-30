COPY( 
	WITH others_cbn AS ( 
		SELECT DISTINCT ON (o.nom)
		o.meta_date_saisie, 
		o.nom,
		o.meta_date_maj 
		FROM flore.releve r 
		JOIN referentiels.organisme o ON o.id_org = r.id_org_f 
		WHERE r.id_org_f IS NOT NULL 
			AND r.meta_id_groupe <> 1 
			AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')
	),
	partners_cbna AS ( 
		SELECT DISTINCT ON (o.nom)
		o.nom,
		o.meta_date_saisie,
		o.meta_date_maj
		FROM flore.releve r 
		JOIN referentiels.organisme o ON o.id_org = r.id_org_f 
		WHERE r.id_org_f IS NOT NULL 
			AND r.meta_id_groupe = 1 
			AND r.id_org_f <> 2785 
			AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')
	)
SELECT DISTINCT ON (unique_source."name") * 
	FROM( 
		SELECT
			oc.nom::TEXT AS "name",
			'Observations issues de Simethis et produites par les CBN Corse et Méditerranéen et leurs partenaires (Parcs nationaux, parcs naturels régionaux, CEN, bureaux d''études, …)'::text AS "desc",
			NULL::text AS entity_source_pk_field,
			NULL::character varying AS url, 
			NULL AS additional_data,
			oc.meta_date_saisie::timestamp AS meta_create_date,
			oc.meta_date_maj::timestamp AS meta_update_date,
			'I'::character(1) AS meta_last_action
		FROM others_cbn oc
			
		UNION

		SELECT
			pc.nom::TEXT AS "name",
			'Observations produites par les partenaires du CBNA' AS "desc",
			NULL::text AS entity_source_pk_field,
			NULL::character varying AS url,
			NULL AS additional_data,
			pc.meta_date_saisie::timestamp AS meta_create_date,
			pc.meta_date_maj::timestamp AS meta_update_date,
			'I'::character(1) AS meta_last_action
		FROM partners_cbna pc

		UNION 

		SELECT
			'flora_cbna'::TEXT AS "name",
			'Observations produites par le CBNA' AS "desc",
			NULL::text AS entity_source_pk_field,
			NULL::character varying AS url,
			NULL AS additional_data,
			'2021-01-28'::timestamp AS meta_create_date,
			'2023-04-21'::timestamp AS meta_update_date,
			'I'::character(1) AS meta_last_action
			
	) AS unique_source
) TO stdout
WITH (format csv, header, delimiter E'\t', null '\N')
;    
    
    
   
