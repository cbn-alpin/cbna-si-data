CREATE OR REPLACE FUNCTION flore.generate_observers(id_releve integer, sep character varying DEFAULT ' '::character varying)
    RETURNS text
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $function$
DECLARE
    generate_observers text;
BEGIN
    generate_observers := concat_ws($2,
        CASE
            WHEN rel.id_obs1 IS NOT NULL --obs1
                THEN concat(obs1.nom,' ', obs1.prenom,
                    CASE
                        WHEN obs1.email IS NOT NULL AND obs1.email != '' --si email obs1
                            THEN concat(' <', obs1.email,'>') --email obs1
                        ELSE ''
                    END,
                    ' (',
                    CASE
                        WHEN id_org_obs1 IS NOT NULL --si org1
                            THEN (SELECT coalesce( NULLIF(org1.abb,'') ,org1.nom) --org_obs1
                                FROM referentiels.organisme org1
                                WHERE rel.id_org_obs1 = org1.id_org )
                        ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
                    END,')',
                    concat(' [', flore.check_cbna_agent(rel.id_obs1, rel.date_releve_deb), ']') -- uuid obs1
                )
            ELSE NULL
        END,
        CASE
            WHEN rel.id_obs2 IS NOT NULL --obs2
                THEN concat(obs2.nom,' ', obs2.prenom,
                    CASE
                        WHEN obs2.email IS NOT NULL AND obs2.email != '' --si email obs2
                            THEN concat(' <', obs2.email,'>') --email obs2
                        ELSE ''
                    END,
                    ' (',
                    CASE
                        WHEN id_org_obs2 IS NOT NULL --si org2
                            THEN (SELECT coalesce( NULLIF(org2.abb,'') ,org2.nom) --org_obs2
                                FROM referentiels.organisme org2
                                WHERE rel.id_org_obs2 = org2.id_org )
                        ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
                    END,')',
                    concat(' [', flore.check_cbna_agent(rel.id_obs2, rel.date_releve_deb), ']') -- uuid obs2
                )
            ELSE NULL
        END,
        CASE
            WHEN rel.id_obs3 IS NOT NULL --obs3
                THEN concat(obs3.nom,' ', obs3.prenom,
                    CASE
                        WHEN obs3.email IS NOT NULL AND obs3.email != '' --si email obs3
                            THEN concat(' <', obs3.email,'>') --email obs3
                        ELSE ''
                    END,
                    ' (',
                    CASE
                        WHEN id_org_obs3 IS NOT NULL --si org3
                            THEN (SELECT coalesce( NULLIF(org3.abb,'') ,org3.nom) --org_obs3
                                FROM referentiels.organisme org3
                                WHERE rel.id_org_obs3 = org3.id_org )
                        ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
                    END,')',
                    concat(' [', flore.check_cbna_agent(rel.id_obs3, rel.date_releve_deb), ']') -- uuid obs3
                )
            ELSE NULL
        END,
        CASE
            WHEN rel.id_obs4 IS NOT NULL --obs4
                THEN concat(obs4.nom,' ', obs4.prenom,
                    CASE
                        WHEN obs4.email IS NOT NULL AND obs4.email != '' --si email obs4
                            THEN concat(' <', obs4.email,'>') --email obs4
                        ELSE ''
                    END,
                    ' (',
                    CASE
                        WHEN id_org_obs4 IS NOT NULL --si org4
                            THEN (SELECT coalesce( NULLIF(org4.abb,'') ,org4.nom) --org_obs4
                                FROM referentiels.organisme org4
                                WHERE rel.id_org_obs4 = org4.id_org )
                        ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
                    END,')',
                    concat(' [', flore.check_cbna_agent(rel.id_obs4, rel.date_releve_deb), ']') -- uuid obs4
                )
            ELSE NULL
        END,
        CASE
            WHEN rel.id_obs5 IS NOT NULL --obs5
                THEN concat(obs5.nom,' ', obs5.prenom,
                    CASE
                        WHEN obs5.email IS NOT NULL AND obs5.email != '' --si email obs5
                            THEN concat(' <', obs5.email,'>') --email obs5
                        ELSE ''
                    END,
                    ' (',
                    CASE
                        WHEN id_org_obs5 IS NOT NULL --si org5
                            THEN (SELECT coalesce( NULLIF(org5.abb,'') ,org5.nom) --org_obs5
                                FROM referentiels.organisme org5
                                WHERE rel.id_org_obs5 = org5.id_org )
                        ELSE coalesce(NULLIF(orgf.abb,''),orgf.nom)
                    END,')',
                    concat(' [', flore.check_cbna_agent(rel.id_obs5, rel.date_releve_deb), ']') -- uuid obs5
                )
            ELSE NULL
        END
    )
    FROM flore.releve AS rel
        LEFT JOIN referentiels.observateur AS obs1
            ON rel.id_obs1 = obs1.id_obs
        LEFT JOIN referentiels.observateur AS obs2
            ON rel.id_obs2 = obs2.id_obs
        LEFT JOIN referentiels.observateur AS obs3
            ON rel.id_obs3 = obs3.id_obs
        LEFT JOIN referentiels.observateur AS obs4
            ON rel.id_obs4 = obs4.id_obs
        LEFT JOIN referentiels.observateur AS obs5
            ON rel.id_obs5 = obs5.id_obs
        LEFT JOIN referentiels.organisme AS orgf
            ON rel.id_org_f = orgf.id_org
    WHERE rel.id_releve = $1;

    RETURN generate_observers;

END;
$function$ ;

DROP TABLE IF EXISTS flore.cbna_agent;

--Create table, drop at the end of the script, in order to list CBNA agents of the conservation and knowledge services of the CBNA
CREATE TABLE flore.cbna_agent (
    gid SERIAL PRIMARY KEY,
    uuid UUID,
    last_name VARCHAR(100),
    first_name VARCHAR(100),
    entry_date DATE,
    release_date DATE
);

-- Insert datas from CSV file to table
COPY flore.cbna_agent(last_name, first_name, entry_date, release_date)
FROM :'cbnaAgentCsvFilePath'
DELIMITER ','
CSV HEADER;

-- Agent uuid recovery in the table
UPDATE flore.cbna_agent AS ca
SET uuid = u.permid
FROM applications.utilisateur AS u
WHERE u.id_groupe = 1
    AND lower(unaccent(u.nom)) = lower(unaccent(ca.last_name))
    AND lower(unaccent(u.prenom)) = lower(unaccent(ca.first_name));


-- Requête occtax
COPY (
    SELECT DISTINCT ON (unique_id_sinp_grp)

    -- t_releves_occtax

        r.id_releve_sinp AS unique_id_sinp_grp,
        mj.lib_jdd_court::varchar(255) AS code_dataset,
        dig.permid::varchar(50) AS code_digitiser,
        flore.generate_observers(r.id_releve, ', '::character varying) AS observers,
        NULL AS code_nomenclature_tech_collect_campanule, -- 0 : Vu Observation directe d'un individu vivant.
        -- Attention : MethodeObservation devient techniqueObservation renommé "Technique de collecte(Campanule) (2018)"
        -- Ne pas utiliser
        'REL'::text AS code_nomenclature_grp_typ, -- Relevé (qu'il soit phytosociologique, d'observation, ou autre...)
        rm.lib AS grp_method,
        r.date_releve_deb::timestamp AS date_min,
        r.date_releve_fin::timestamp AS date_max,
        NULL AS hour_min,
        NULL AS hour_max,
        hr.cd_hab AS cd_hab,
        LEAST(NULLIF(r.alti_inf, 0) , r.alti_calc) AS altitude_min,
        GREATEST(NULLIF(r.alti_sup, 0), r.alti_calc) AS altitude_max,
        NULL AS depth_min,
        NULL AS depth_max,
        r.lieudit AS place_name,
        NULL AS meta_device_entry,
        public.delete_space(r.comm_loc) AS comment_context,
        st_geomfromewkt(
            CASE
                WHEN r.id_precision = 'P'::bpchar -- P : Pointage précis
                    THEN st_asewkt(COALESCE(st_transform(r.geom_pres_4326, 2154), r.geom_2154))
                WHEN r.id_precision = ANY (ARRAY['T'::bpchar, 'A'::bpchar, 'C'::bpchar]) -- T : Pointage approximatif, A : Précision inconnue, C : Commune
                    THEN st_asewkt(COALESCE(r.geom_2154, st_centroid(st_transform(r.geom_prosp_4326, 2154))))
                ELSE NULL
            END
        )
        AS geom,
        CASE
            WHEN r.id_precision = 'P'::bpchar -- P : Pointage précis
                OR r.id_releve_methode = 10
                    THEN 'St'::TEXT -- St : Stationnel
            WHEN r.id_precision = ANY (ARRAY['T'::bpchar, 'C'::bpchar])
                THEN 'In'::TEXT -- In : Inventoriel
            ELSE 'NSP'::text
        END AS code_nomenclature_geo_object_nature,
        COALESCE(r.resolution,
            CASE r.id_precision
                WHEN 'P'::bpchar THEN 10
                WHEN 'T'::bpchar THEN 800
                ELSE NULL
            END
        )
        AS "precision",

        -- t_occurences_occtax

        o.id_observation_sinp AS unique_id_occurrence_occtax,
        '0'::text AS code_nomenclature_obs_technique, -- 0 : Vu Observation directe d'un individu vivant.
        -- Attention : MethodeObservation devient techniqueObservation renommé "Technique de collecte(Campanule) (2018)"
        -- Se référer au type de nomenclature 'meth_obs'
        '2'::text AS code_nomenclature_bio_condition, -- 2 : vivant
        '1'::text AS code_nomenclature_bio_status, -- 1 : Non renseigné
        CASE
            WHEN o.id_deg_nat = ANY (ARRAY[1, 2, 3]) THEN '5'::TEXT -- 5 : Subspontané
            WHEN o.id_deg_nat = 4 THEN '3'::TEXT  -- 3 : Planté
            WHEN o.id_deg_nat = 5 THEN '0'::TEXT  -- 0 : Inconnu
            WHEN o.id_deg_nat IS NULL THEN '1'::TEXT --1 : Sauvage
            ELSE NULL
        END AS code_nomenclature_naturalness,
        CASE
            WHEN o.id_herbier1 > 0 THEN '1'::TEXT -- 1 : Oui
            ELSE '2'::TEXT -- 2 : Non
        END AS code_nomenclature_exist_proof,
        CASE
            WHEN r.sinp_dspublique::text = ANY (ARRAY['Pu'::character varying, 'Re'::character varying, 'Ac'::character varying]::text[]) --PU: Publique, Re: Publique Régie, Ac: Publique acquise
                THEN 5 -- diffusion telle quelle
            ELSE COALESCE(r.sinp_difnivprec::integer, 0) -- diffusion standard
        END::varchar(25) AS code_nomenclature_diffusion_level,
        'Pr'::text AS code_nomenclature_observation_status, -- Pr : Présent
        NULL AS code_nomenclature_blurring,
        CASE
            WHEN r.id_releve_type::text = 'BIB'::text
                OR r.id_releve_type::text = 'NM'::text
                    AND r.id_biblio IS NOT NULL
                        THEN 'Li'::TEXT -- Li : Littérature
            WHEN (r.id_releve_type::text = ANY (ARRAY['RT'::character varying, 'COM'::character varying]::text[]))
                OR r.id_releve_type::text = 'NM'::text
                    AND r.id_biblio IS NULL
                        THEN 'Te'::TEXT -- Te : Terrain
            WHEN r.id_releve_type::text = 'HB'::text
                THEN 'Co'::TEXT -- Co : Collection
            WHEN r.id_releve_type::text = 'I'::text
                THEN 'NSP'::text
            ELSE NULL
        END AS code_nomenclature_source_status,
        '0'::text AS code_nomenclature_behaviour, -- 0 : Inconnu, le statut biologie de l'individu n'est pas connu
        concat(
            CASE
                WHEN o.id_det IS NOT NULL
                    THEN concat(upper(det.nom),' ', COALESCE (det.prenom, ''))
                ELSE 'INCONNU'
            END
        )
        AS determiner,
         1::varchar(25) AS code_nomenclature_determination_method,
         CASE
            WHEN o.cd_ref < 15
                THEN o.cd_ref + 30000000
            ELSE o.cd_ref
        END AS cd_nom,
        CASE
            WHEN o.nom_taxon IS NOT NULL
                THEN o.nom_taxon::varchar(1000)
            ELSE ''
        END AS nom_cite,
        'Taxref v16.0' AS meta_v_taxref,
        NULL AS sample_number_proof,
        NULL AS digital_proof,
        NULL AS non_digital_proof,
        public.delete_space(o.comm_taxon) AS comment_description,

        -- cor_counting_occtax

        o.id_observation_sinp AS unique_id_sinp_occtax,
        '0'::text AS code_nomenclature_life_stage, -- 0 : Inconnu
        CASE
            WHEN o.sexe = 'M'::bpchar THEN '3'::TEXT -- 3 : Mâle
            WHEN o.sexe = 'F'::bpchar THEN '2'::TEXT -- 2 : Femelle
            WHEN o.sexe = 'H'::bpchar THEN '4'::TEXT -- 4 : Hermaphrodite
            ELSE '6'::TEXT -- 6 : Non renseigné
        END AS code_nomenclature_sex,
        'NSP'::text AS code_nomenclature_obj_count,
        'NSP'::text AS code_nomenclature_type_count, -- La méthode de dénombrement n'est pas connue
        COALESCE(o.nombre_pieds::integer, np.nb_min) AS count_min,
        COALESCE(o.nombre_pieds::integer, np.nb_max) AS count_max,

        jsonb_strip_nulls(
            CASE
                WHEN r.id_org_f IS NOT NULL
                    THEN jsonb_build_object('fournisseur',
                            jsonb_build_object('idOrgF', r.id_org_f, 'nomOrgF', ovf.nom))
                ELSE jsonb_build_object('fournisseur', null)
            END ||
            public.build_simple_json_object('metaIdGroupe', r.meta_id_groupe) ||
            public.build_simple_json_object('metaIdProg', r.meta_id_prog) ||
            public.build_simple_json_object('inseeReg', r.insee_reg) ||
            CASE
                WHEN h.nom != ''
                    THEN jsonb_build_object('herbier',
                            jsonb_build_object('nomHerbier', h.nom, 'partHerbier', o.part_herbier1, 'idHerbier', o.id_herbier1))
                ELSE jsonb_build_object('herbier', null)
            END ||
            public.build_simple_json_object('codePerso', r.code_perso) ||
            public.build_simple_json_object('codeGps', r.code_gps) ||
            CASE
                WHEN r.meta_id_prog IS NOT NULL
                    THEN jsonb_build_object('metaNomProg', p.nom)
                ELSE '{"metaNomProg": null}'
            END ||
            public.build_simple_json_object('metaIdUserSaisie', r.meta_id_user_saisie) ||
            public.build_simple_json_object('sinpDspublique', r.sinp_dspublique) ||
            CASE t.tax_type
                WHEN 'P'::bpchar THEN '{"taxTypeLabel": "Plantes vasculaires"}'::TEXT
                WHEN 'B'::bpchar THEN '{"taxTypeLabel": "Bryophytes"}'::TEXT
                WHEN 'L'::bpchar THEN '{"taxTypeLabel": "Lichens"}'::text
                WHEN 'C'::bpchar THEN '{"taxTypeLabel": "Champignons"}'::TEXT
                WHEN 'A'::bpchar THEN '{"taxTypeLabel": "Algues"}'::TEXT
                ELSE '{"taxType": null}'
            END::jsonb||
            CASE
	            	WHEN r.meta_id_user_saisie IN (21, 47, 394, 75, 4, 40,48)
                        THEN jsonb_build_object('digitisers', json_build_object(
                            'nom', dig.nom,
                            'prénom', dig.prenom,
                            'email', dig.email,
                            'org', dig.id_org
                            ))
                ELSE jsonb_build_object ('digitisers', null)
            END
        ) AS additional_fields,
        r.meta_date_saisie::timestamp AS meta_create_date,
        GREATEST(o.meta_date_maj, r.meta_date_maj)::timestamp AS meta_update_date,
        'I' AS meta_last_action

    FROM flore.releve r
        JOIN flore.observation o ON r.id_releve = o.id_releve
        JOIN referentiels.metadata_jdd mj ON r.id_jdd = mj.id_jdd
        LEFT JOIN referentiels.releve_methode rm ON r.id_releve_methode = rm.id_releve_methode
        LEFT JOIN referentiels.biblio b ON r.id_biblio = b.id_biblio
        LEFT JOIN referentiels.nombre_pieds np ON o.id_nombre_pieds = np.id_nombre_pieds
        LEFT JOIN referentiels.observateur det ON det.id_obs = o.id_det
        LEFT JOIN applications.utilisateur val ON val.id_user = o.meta_id_user_valid
        LEFT JOIN flore.cbna_agent ca ON ca.uuid = val.permid
        LEFT JOIN applications.utilisateur dig ON dig.id_user = r.meta_id_user_saisie
        LEFT JOIN referentiels.organisme ovf ON r.id_org_f = ovf.id_org
        LEFT JOIN referentiels.commune c ON r.insee_comm = c.insee_comm
        LEFT JOIN referentiels.taxref t ON o.cd_nom = t.cd_nom
        LEFT JOIN referentiels.programme p ON r.meta_id_prog = p.id_prog
        LEFT JOIN referentiels.herbier h ON o.id_herbier1 = h.id_herbier
        LEFT JOIN referentiels.ecologie_eunis ee ON ee.cd_ref = o.cd_ref
        LEFT JOIN referentiels.habref hr ON hr.cd_hab = ee.cd_hab_eunis
    WHERE
        r.id_org_f = 2785 -- CBNA

) TO '/tmp/occtax.csv'
WITH(format csv, header, delimiter E'\t', null '\N');

