
-- Return precise geometry

CREATE OR REPLACE FUNCTION flore.blur_geom(geom4326 geometry, idObs integer, cdSensitivity integer)
    RETURNS geometry
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $function$
    BEGIN
        RETURN geom4326;
    END;
$function$;

