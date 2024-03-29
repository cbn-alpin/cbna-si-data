CREATE OR REPLACE FUNCTION flore.check_cbna_agent(observer_id integer, date_releve date)
    RETURNS uuid
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $function$
    --Check cbna agent uuid/observers and generate observers uuid when uuid is null.
    -- Return an unique_id uuid.
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

CREATE OR REPLACE FUNCTION public.build_simple_json_object(fieldkey character varying, fieldvalue anyelement)
    RETURNS jsonb
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $function$
    -- Build a simple json object with a CASE WHEN.
    -- Return a json object.
    DECLARE
        jsonObject jsonb;

    BEGIN
           SELECT
            CASE
                WHEN (pg_typeof(fieldValue) = 'integer'::regtype AND fieldValue IS NOT NULL) OR (pg_typeof(fieldValue) = 'character varying'::regtype AND fieldValue::varchar != '')
                    THEN jsonb_build_object(fieldKey, fieldValue)
                ELSE jsonb_build_object(fieldKey, NULL)
            END::jsonb INTO jsonObject;

        RETURN jsonObject;
    END;
$function$
;


CREATE OR REPLACE FUNCTION public.delete_space(txtWithSpace varchar)
    RETURNS text
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $function$
    DECLARE
        txtWithoutSpace text;

    BEGIN
        txtWithoutSpace := '';

        SELECT INTO txtWithoutSpace
            CASE
                WHEN txtWithSpace IS NOT NULL AND txtWithSpace !~* '^\s*$'
                    THEN txtWithSpace
                ELSE NULL
            END;

        RETURN txtWithoutSpace;
    END;
$function$
;
