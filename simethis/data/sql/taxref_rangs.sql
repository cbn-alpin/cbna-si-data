 
COPY (
    SELECT
        t.rang AS id_rang,
        t.detail AS nom_rang,
        'Group' AS nom_rang_en,
        t.rg_level AS tri_rang,
        NULL AS meta_create_date,
        NULL AS meta_update_date,
        'I'::character(1) AS meta_last_action
    FROM referentiels.taxref_rang t 
    WHERE t.rang = 'GPE'

    UNION 

    SELECT
        t.rang AS id_rang,
        t.detail AS nom_rang,
        t.detail AS nom_rang_en,
        t.rg_level AS tri_rang,
        NULL AS meta_create_date,
        NULL AS meta_update_date,
        'I'::character(1) AS meta_last_action
    FROM referentiels.taxref_rang t 
    WHERE t.rang = 'SECT'
)
TO stdout
WITH (format csv, header, delimiter E'\t');
;