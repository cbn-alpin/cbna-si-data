--WITH
	
SELECT
 	'simethis'::TEXT AS name,
    'Observations issues de Simethis, la base de données mutualisée des CBN Alpin, Corse et Méditerranéen correspondant à leur observations propres et à celles de leurs partenaires (Parcs nationaux, parcs naturels régionaux, CEN, bureaux d''études, …)'::text AS "desc",
    'id_observation'::text AS entity_source_pk_field,
    NULL::character varying AS url,
    NULL::jsonb AS additional_data,
    '2021-02-24'::timestamp AS meta_create_date,
    now()::timestamp AS meta_update_date,
    'I'::character(1) AS meta_last_action
    
UNION
    
SELECT
	'fournisseurs'::TEXT AS name,
	'Observations issus de bases autre que Simethis à l''origine' AS "desc",
	'id_observation'::text AS entity_source_pk_field,
    NULL::character varying AS url,
    NULL::jsonb AS additional_data,
    '2021-02-24'::timestamp AS meta_create_date,
    now()::timestamp AS meta_update_date,
    'I'::character(1) AS meta_last_action
    
    
UNION 

SELECT 
	'flora_cbna'::TEXT AS name,
	'Observations issus du CBNA' AS "desc",
	'id_observation'::text AS entity_source_pk_field,
    NULL::character varying AS url,
    NULL::jsonb AS additional_data,
    '2021-02-24'::timestamp AS meta_create_date,
    now()::timestamp AS meta_update_date,
    'I'::character(1) AS meta_last_action
    
 
  
    
    
    
 
