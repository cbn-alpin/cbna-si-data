COPY (
    INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role)
        SELECT distinct
            s.id_synthese,
            t.id_role
        from gn_imports.test_synthese_1 ts
        JOIN gn_synthese.synthese s
                ON s.unique_id_sinp = ts.unique_id_sinp
        JOIN utilisateurs.t_roles t
            ON upper(t.nom_role) = ANY(ARRAY(SELECT array_to_string(regexp_matches(ts.observers, '[[:upper:]]{2,}', 'g'),'')))
            
        UNION 

        SELECT
            s.id_synthese,
            t.id_role
        from gn_imports.test_synthese_1 ts
        JOIN gn_synthese.synthese s
                ON s.unique_id_sinp = ts.unique_id_sinp
        cross join lateral regexp_matches(ts.observers, '\[(.*?)\]', 'g') as MATCH
        JOIN utilisateurs.t_roles t
                ON t.uuid_role::text = match[1]
    ON CONFLICT ON CONSTRAINT pk_cor_observer_synthese DO NOTHING 
    ;
) TO stdout
WITH (format csv, header, delimiter E'\t')
;