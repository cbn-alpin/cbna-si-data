CREATE OR REPLACE FUNCTION flore.blur_geom(geom4326 geometry, idObs integer, cdSensitivity integer)
    RETURNS geometry
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $function$
-- Return 10km mesh geometry
    DECLARE
        geom4326 geometry;
    BEGIN
        SELECT
            CASE
                WHEN cdSensitivity IS NOT NULL THEN
                	CASE
	                	WHEN s.geom_maille10_4326 IS NOT NULL THEN s.geom_maille10_4326
	                	ELSE (
                            SELECT mi.geom_4326
                            FROM flore.releve r
                                JOIN referentiels.maille_inpn_10 mi
                                    ON mi.geom_4326 && r.geom_4326
                            LIMIT 1
                            )
                        END
                    ELSE r.geom_4326
                END
            INTO geom4326
        FROM flore.releve r
            JOIN flore.observation o
                ON o.id_releve = r.id_releve
            LEFT JOIN flore.synthese s
                ON s.id_observation = o.id_observation
        WHERE idObs = o.id_observation;

        RETURN geom4326;
    END;
$function$;
