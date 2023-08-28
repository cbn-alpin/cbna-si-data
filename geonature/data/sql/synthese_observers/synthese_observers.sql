COPY (
    SELECT 
        s.id_synthese,
        tr1.id_role AS id_role
    FROM gn_synthese.synthese s
    LEFT JOIN utilisateurs.t_roles tr1
        ON tr1.champs_addi ->> 'idObs' = s.additional_data ->> 'idObs1'

    UNION 

    SELECT 
        s.id_synthese,
        tr2.id_role ->> 'idObs' AS id_role
    FROM gn_synthese.synthese s
    LEFT JOIN utilisateurs.t_roles tr2
        ON tr2.champs_addi ->> 'idObs' = s.additional_data ->> 'idObs2'
        
    UNION 

    SELECT 
        s.id_synthese,
        tr3.id_role ->> 'idObs' AS id_role
    FROM gn_synthese.synthese s
    LEFT JOIN utilisateurs.t_roles tr3
        ON tr3.champs_addi ->> 'idObs' = s.additional_data ->> 'idObs3'
        
    UNION 

    SELECT 
        s.id_synthese,
        tr4.id_role ->> 'idObs' AS id_role
    FROM gn_synthese.synthese s
    LEFT JOIN utilisateurs.t_roles tr4
        ON tr4.champs_addi ->> 'idObs' = s.additional_data ->> 'idObs4'

    UNION 

    SELECT 
        s.id_synthese,
        tr5.id_role ->> 'idObs' AS id_role
    FROM gn_synthese.synthese s
    LEFT JOIN utilisateurs.t_roles tr5
        ON tr5.champs_addi ->> 'idObs' = s.additional_data ->> 'idObs5'
) TO stdout 
WITH(format csv, header, delimiter E'\t');
;