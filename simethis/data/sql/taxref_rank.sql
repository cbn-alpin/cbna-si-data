
COPY (
    SELECT
        t.rang AS code,
        t.detail AS label,
        'Group' AS label_en,
        t.rg_level AS "level",
        NULL AS additional_data,
        NULL AS meta_create_date,
        NULL AS meta_update_date,
        'I'::character(1) AS meta_last_action
    FROM referentiels.taxref_rang t
    WHERE t.rang = 'GPE'

    UNION

    SELECT
        t.rang AS code,
        t.detail AS label,
        t.detail AS label_en,
        t.rg_level AS "level",
        NULL AS additional_data,
        NULL AS meta_create_date,
        NULL AS meta_update_date,
        'I'::character(1) AS meta_last_action
    FROM referentiels.taxref_rang t
    WHERE t.rang = 'SECT'
) TO stdout
WITH (format csv, header, delimiter E'\t');
