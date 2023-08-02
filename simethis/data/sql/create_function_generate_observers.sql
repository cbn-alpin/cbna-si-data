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
		concat( concat(obs1.nom,' ', obs1.prenom), --obs1
		  		CASE
					WHEN obs1.email IS NOT NULL AND obs1.email != '' --si email obs1
						THEN concat(' ','<', obs1.email,'>') --email obs1
					ELSE ''
				END,
			  	CASE 
					WHEN rel.id_obs1 IS NOT NULL
						THEN concat(' (',
						  		CASE
									WHEN id_org_obs1 IS NOT NULL --si org1
										THEN (SELECT coalesce( NULLIF(org1.abb,'') ,org1.nom) --org_obs1
											FROM referentiels.organisme org1
											WHERE rel.id_org_obs1 = org1.id_org )
									ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
								END,')'
							 )
					ELSE ''
				END,
				CASE 
					WHEN rel.id_obs1 IS NOT NULL 
						THEN concat(' ','[',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs1)),']') -- uuid obs1
				END),		
        concat( CASE
	        		WHEN rel.id_obs2 IS NOT NULL -- si obs2
	        			THEN concat(', ', obs2.nom,' ', obs2.prenom) --obs2
	        		ELSE ''
	        	END,
		  		CASE
					WHEN obs2.email IS NOT NULL AND obs2.email != '' --si email obs2
						THEN concat(' ','<', obs2.email,'>') --email obs2
					ELSE ''
				END, 
				CASE 
					WHEN rel.id_obs2 IS NOT NULL
						THEN concat(' (',
						  		CASE
									WHEN id_org_obs2 IS NOT NULL --si org2
										THEN (SELECT coalesce( NULLIF(org2.abb,'') ,org2.nom) --org_obs2
											FROM referentiels.organisme org2
											WHERE rel.id_org_obs2 = org2.id_org )
									ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
								END,')'
							 )
					ELSE ''
				END,
				CASE 
					WHEN rel.id_obs2 IS NOT NULL 
						THEN concat(' ','[',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs2)),']') --uuid obs2
				END),
		concat( CASE
					WHEN rel.id_obs3 IS NOT NULL -- si obs3
						THEN concat(', ', obs3.nom,' ', obs3.prenom) -- obs3
					ELSE ''
					END,
		  		CASE
					WHEN obs3.email IS NOT NULL AND obs3.email != '' --si email obs3
						THEN concat(' ','<', obs3.email,'>') --email obs3
					ELSE ''
				END,
			  	CASE 
					WHEN rel.id_obs3 IS NOT NULL
						THEN concat(' (',
							   CASE
								   WHEN id_org_obs3 IS NOT NULL --si org3
									   THEN (SELECT coalesce( NULLIF(org3.abb,'') ,org3.nom) --org_obs3
										  FROM referentiels.organisme org3
										  WHERE rel.id_org_obs3 = org3.id_org )
								   ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
							   END,')'
							  )
					ELSE ''
				END,
				CASE 
					WHEN rel.id_obs3 IS NOT NULL 
						THEN concat(' ','[',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs3)),']')--uuid obs3
				END),
		concat( CASE
					WHEN rel.id_obs4 IS NOT NULL -- si obs4
						THEN concat(', ', obs4.nom,' ', obs4.prenom) --obs4
						ELSE ''
						END,
		  		CASE
					WHEN obs4.email IS NOT NULL AND obs4.email != '' --si email obs4
						THEN concat(' ','<', obs4.email,'>') --email obs4
					ELSE ''
				END,
				CASE 
					WHEN rel.id_obs4 IS NOT NULL
						 THEN concat(' (',
						  		CASE
									WHEN id_org_obs4 IS NOT NULL --si org4
										THEN (SELECT coalesce( NULLIF(org4.abb,'') ,org4.nom) --org_obs4
											FROM referentiels.organisme org4
											WHERE rel.id_org_obs4 = org4.id_org )
									ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
								END,')'
							  )
					ELSE ''
				END,	
				CASE 
					WHEN rel.id_obs4 IS NOT NULL 
						THEN concat(' ','[',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs4)),']')--uuid obs4
				END),
		concat( CASE
					WHEN rel.id_obs5 IS NOT NULL -- si obs5
						THEN concat(', ', obs5.nom,' ', obs5.prenom)--obs5
					ELSE ''
				END,
		  		CASE
					WHEN obs5.email IS NOT NULL AND obs5.email != '' --si email obs5
						THEN concat(' ','<', obs5.email,'>') --email obs5
					ELSE ''
				END,
		  	    CASE 
					WHEN rel.id_obs5 IS NOT NULL
						 THEN concat(' (',
						  		CASE
									WHEN id_org_obs5 IS NOT NULL --si org5
										THEN (SELECT coalesce( NULLIF(org5.abb,'') ,org5.nom) --org_obs5
											FROM referentiels.organisme org5
											WHERE rel.id_org_obs5 = org5.id_org )
									ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
								END,')'
				              )
					ELSE ''
				END,
				CASE 
					WHEN rel.id_obs5 IS NOT NULL 
						THEN concat(' ','[',uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', rel.id_obs5)),']')--uuid obs5
				END)
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
