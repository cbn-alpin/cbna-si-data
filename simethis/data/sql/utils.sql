-- function check cbna agent uuid/observers and generate observers uuid when uuid is null

CREATE OR REPLACE FUNCTION flore.check_cbna_agent(observer_id integer, date_releve date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
	DECLARE
		cbna_agent_unique_id uuid;
	
	BEGIN 
		cbna_agent_unique_id := NULL;
	
		SELECT INTO cbna_agent_unique_id
			CASE 
		    	WHEN ca.gid IS NOT NULL 
		    			THEN ca.uuid 
		    			ELSE concat(uuid_generate_v5(uuid_ns_url(), concat('https://simethis.eu/referentiels/observateur/', observer_id)))::uuid
		    END AS unique_id
		FROM referentiels.observateur o 
			LEFT JOIN flore.cbna_agent ca 
				ON (
					lower(unaccent(o.nom)) = lower(unaccent(ca.last_name))
					AND lower(unaccent(o.prenom)) = lower(unaccent(ca.first_name))
					AND (date_releve > ca.entry_date OR date_releve < coalesce(ca.release_date, now()))	
				)
		WHERE o.id_obs = observer_id;
	
		RETURN cbna_agent_unique_id;
	END;
$function$
; 
