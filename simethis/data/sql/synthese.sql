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

-- Create table, drop at the end of the script, in order to list CBNA agents of the conservation and knowledge services of the CBNA
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


-- Requête export_synthese_initialisation
COPY (
    WITH evee AS (
        SELECT cd_ref
        FROM referentiels.reglementation_taxon
        WHERE id_reglementation::text = ANY (ARRAY['EVEE_EME', 'EVEE_MAJ', 'EVEE_MOD'])
        GROUP BY cd_ref
    ),
    sensi_reg AS (
        SELECT cd_ref
        FROM referentiels.reglementation_taxon
        WHERE id_reglementation::varchar = 'SENSI_PACA'
            OR id_reglementation::varchar = 'SENSI_AURA'
        GROUP BY cd_ref
    ),
    sensi_dep AS (
        SELECT cd_ref,
            "right"(id_reglementation::text, 2) AS dept
        FROM referentiels.reglementation_taxon
        WHERE id_reglementation ILIKE '%SENSI_AURA_%'
        GROUP BY cd_ref, ("right"(id_reglementation::text, 2))
    ),
    duplicate_jdd_shortnames AS (
        SELECT lib_jdd_court AS shortname
        FROM referentiels.metadata_jdd
        GROUP BY lib_jdd_court
        HAVING COUNT(*) > 1
    )
    SELECT DISTINCT ON (unique_id_sinp)
        o.id_observation_sinp AS unique_id_sinp,
        r.id_releve_sinp AS unique_id_sinp_grp,
        o.id_observation::varchar AS source_id,
        r.id_releve::varchar AS source_id_grp,
        CASE
            WHEN r.id_org_f = 2785 THEN 'flora_cbna' -- 2785 : CBNA organisme
            WHEN r.meta_id_groupe = 1 -- 1 : CBNA groupe
                AND r.id_org_f <> 2785
                    THEN ovf.nom
            WHEN r.id_org_f IS NOT NULL
                AND r.meta_id_groupe <> 1
                AND r.id_org_f <> 2785
                AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')
                    THEN ovf.nom
            ELSE NULL
        END AS code_source,
        coalesce(
            (
                SELECT concat(jdd.lib_jdd_court, ' - ', jdd.id_jdd)
                FROM referentiels.metadata_jdd AS jdd
                WHERE jdd.id_jdd = mj.id_jdd
                    AND mj.lib_jdd_court IN (SELECT shortname FROM duplicate_jdd_shortnames)
            ),
            mj.lib_jdd_court
        ) AS code_dataset,
        CASE
            WHEN r.id_precision = 'P' -- P : Pointage précis
                OR r.id_releve_methode = 10
                    THEN 'St' -- St : Stationnel
            WHEN r.id_precision = ANY (ARRAY['T', 'C'])
                THEN 'In' -- In : Inventoriel
            ELSE 'NSP'
        END AS code_nomenclature_geo_object_nature,
        'REL' AS code_nomenclature_grp_typ,
        rm.lib AS grp_method,
        '0' AS code_nomenclature_obs_technique, -- 0 : Vu
        '1' AS code_nomenclature_bio_status, -- 1 : Non renseigné
        '2' AS code_nomenclature_bio_condition, -- 2 : vivant
        CASE
            WHEN o.id_deg_nat = ANY (ARRAY[1, 2, 3]) THEN '5' -- 5 : Subspontané
            WHEN o.id_deg_nat = 4 THEN '3'  -- 3 : Planté
            WHEN o.id_deg_nat = 5 THEN '0'  -- 0 : Inconnu
            WHEN o.id_deg_nat IS NULL THEN '1' --1 : Sauvage
            ELSE NULL
        END AS code_nomenclature_naturalness,
        CASE
            WHEN o.id_herbier1 > 0 THEN '1' -- 1 : Oui
            ELSE '2' -- 2 : Non
        END AS code_nomenclature_exist_proof,
        CASE
            WHEN o.valid_reg IS NOT NULL
                THEN o.valid_reg::varchar
            ELSE  '0' -- 1: certain, 2: probable, 3: douteux, 4: invalide, 5:non validable, null: dans l'espace de saisie, 0: dans l'espace de validation
        END AS code_nomenclature_valid_status,
        CASE
            WHEN r.sinp_dspublique::varchar = ANY (ARRAY['Pu', 'Re', 'Ac']) --PU: Publique, Re: Publique Régie, Ac: Publique acquise
                THEN '5' -- diffusion telle quelle
            ELSE coalesce(r.sinp_difnivprec::varchar, '0') -- diffusion standard
        END AS code_nomenclature_diffusion_level,
        '0' AS code_nomenclature_life_stage, -- 0 : Inconnu
        CASE
            WHEN o.sexe = 'M' THEN '3' -- 3 : Mâle
            WHEN o.sexe = 'F' THEN '2' -- 2 : Femelle
            WHEN o.sexe = 'H' THEN '4' -- 4 : Hermaphrodite
            ELSE '6' -- 6 : Non renseigné
        END AS code_nomenclature_sex,
        'NSP' AS code_nomenclature_obj_count,
        'NSP' AS code_nomenclature_type_count,
        CASE
            WHEN COALESCE(se.cd_ref, sed.cd_ref) IS NOT NULL THEN '1' -- Département, maille, espace, commune, ZNIEFF
            ELSE '0' -- Précision maximale telle que saisie(non sensible)
        END AS code_nomenclature_sensitivity,
        'Pr' AS code_nomenclature_observation_status, -- Pr : Présent
        NULL AS code_nomenclature_blurring,
        CASE
            WHEN r.id_releve_type = 'BIB'
                OR r.id_releve_type = 'NM'
                    AND r.id_biblio IS NOT NULL
                        THEN 'Li' -- Li : Littérature
            WHEN (r.id_releve_type = ANY (ARRAY['RT', 'COM']))
                OR r.id_releve_type = 'NM'
                    AND r.id_biblio IS NULL
                        THEN 'Te' -- Te : Terrain
            WHEN r.id_releve_type = 'HB'
                THEN 'Co' -- Co : Collection
            WHEN r.id_releve_type = 'I'
                THEN 'NSP'
            ELSE NULL
        END AS code_nomenclature_source_status,
        CASE
            WHEN r.id_precision = ANY (ARRAY['P', 'T', 'A'])
                THEN '1' -- 1 : Géoréférencement
            WHEN r.id_precision = 'C'
                AND r.insee_comm IS NOT NULL
                AND r.insee_dept IS NOT NULL
                    THEN '2' -- 2 : Rattachement
            ELSE NULL
        END AS code_nomenclature_info_geo_type,
        '0' AS code_nomenclature_behaviour, -- 0 : Inconnu, le statut biologie de l'individu n'est pas connu
        CASE cd.id_indigenat
            WHEN 1 THEN '2' -- 2 : Présent, 1 : indigène
            WHEN 2 THEN '0' -- 0 : Inconnu, 2 : indigène ?
            WHEN 3 THEN '2' -- 2 : Présent, 3 : archéophyte
            WHEN 4 THEN -- 4 : exogène
                CASE
                    WHEN e.cd_ref IS NOT NULL THEN '4' -- 4 : Introduit envahissant
                    ELSE '3' -- 3 : Introduit
                END
            ELSE '1' -- 1 : Non renseigné
        END AS code_nomenclature_biogeo_status,
        CASE
            WHEN r.id_biblio IS NOT NULL
                THEN concat(b.auteurs, ', ', b.annee, '. ', b.titre)
            ELSE NULL
        END AS reference_biblio,
        coalesce(o.nombre_pieds::integer, np.nb_min) AS count_min,
        coalesce(o.nombre_pieds::integer, np.nb_max) AS count_max,
        CASE
            WHEN o.cd_ref < 15
                THEN o.cd_ref + 30000000
            ELSE o.cd_ref
        END AS cd_nom,
        NULL AS cd_hab,
        CASE
            WHEN o.nom_taxon IS NOT NULL
                THEN o.nom_taxon
            ELSE ''
        END AS nom_cite,
        NULL AS digital_proof,
        NULL AS non_digital_proof,
        least(nullif(r.alti_inf, 0) , r.alti_calc) AS altitude_min,
        greatest(nullif(r.alti_sup, 0), r.alti_calc) AS altitude_max,
        NULL AS depth_min,
        NULL AS depth_max,
        concat(public.delete_space(r.lieudit), public.delete_space(r.comm_loc)) AS place_name,
        st_geomfromewkt(
            CASE
                WHEN r.id_precision = 'P' -- P : Pointage précis
                    THEN st_asewkt(
                            coalesce(
                                st_transform(
                                    flore.blur_geom(r.geom_pres_4326, o.id_observation, COALESCE(se.cd_ref, sed.cd_ref)),
                                    2154
                                    ),
                                flore.blur_geom(r.geom_2154, o.id_observation, COALESCE(se.cd_ref, sed.cd_ref))
                                )
                            )
                WHEN r.id_precision = ANY (ARRAY['T', 'A', 'C']) -- T : Pointage approximatif, A : Précision inconnue, C : Commune
                    THEN st_asewkt(
                            coalesce(
                                flore.blur_geom(r.geom_2154, o.id_observation, COALESCE(se.cd_ref, sed.cd_ref)),
                                st_centroid(
                                    st_transform(
                                        flore.blur_geom(r.geom_prosp_4326, o.id_observation, COALESCE(se.cd_ref, sed.cd_ref)),
                                        2154
                                        )
                                    )
                                )
                            )
                ELSE NULL
            END
        ) AS geom,
        coalesce(r.resolution,
            CASE r.id_precision
                WHEN 'P' THEN 10
                WHEN 'T' THEN 800
                ELSE NULL
            END
        ) AS "precision",
        CASE
            WHEN r.id_precision = 'C' AND char_length(r.insee_comm) = 5
                THEN concat('COM.', r.insee_comm)
            WHEN r.id_precision = 'C' AND char_length(r.insee_comm) = 2 AND r.insee_dept IS NOT NULL
                THEN concat('DEP.', r.insee_dept)
            WHEN r.id_precision = 'C' AND r.insee_comm IS NULL AND r.insee_dept IS NOT NULL
                THEN concat('DEP.', r.insee_dept)
            ELSE NULL
        END AS code_area_attachment,
        r.date_releve_deb::timestamp AS date_min,
        r.date_releve_fin::timestamp AS date_max,
        CASE
            WHEN o.meta_type_valid = 'a_v1' -- a_v1 : automatiquement
                THEN '-- AUTO --'
            ELSE
                CASE
                    WHEN o.meta_id_user_valid IS NOT NULL
                        THEN concat(
                            val.nom, ' ', val.prenom,
                            CASE
                                WHEN val.email IS NOT NULL AND val.email != ''
                                    THEN concat(' <', val.email, '>')
                                ELSE ''
                            END,
                            ' (',
                            CASE
                                WHEN val.id_org IS NOT NULL
                                    THEN (SELECT coalesce(nullif(orgv.abb, ''), orgv.nom)
                                        FROM referentiels.organisme AS orgv
                                        WHERE val.id_org = orgv.id_org)
                                ELSE 'Inconnu'
                            END,
                            ') ',
                            concat('[', val.permid, ']')
                        )
                    ELSE NULL
               END
        END AS "validator",
        concat_ws(
            '\n',
            nullif(trim(o.comm_validation), ''),
            nullif(trim(v.comm_analyse), '')
        ) AS validation_comment,
        coalesce(o.meta_date_valid, o.meta_date_maj)::timestamp AS validation_date,
        flore.generate_observers(r.id_releve, ', ') AS observers,
        concat(
            CASE
                WHEN o.id_det IS NOT NULL
                    THEN concat(upper(det.nom), ' ', coalesce(det.prenom, ''))
                ELSE 'INCONNU'
            END
        ) AS determiner,
        NULL AS determination_date,
        dig.permid::varchar AS code_digitiser,
        '1' AS code_nomenclature_determination_method,
        public.delete_space(r.comm_date) AS comment_context,
        NULL AS comment_description,
        jsonb_strip_nulls(
            CASE
                WHEN r.id_org_f IS NOT NULL
                    THEN jsonb_build_object(
                        'fournisseur',
                        jsonb_build_object('idOrgF', r.id_org_f, 'nomOrgF', ovf.nom)
                    )
                ELSE jsonb_build_object('fournisseur', null)
            END ||
            public.build_simple_json_object('metaIdGroupe', r.meta_id_groupe) ||
            public.build_simple_json_object('metaIdProg', r.meta_id_prog) ||
            public.build_simple_json_object('inseeReg', r.insee_reg) ||
            CASE
                WHEN h.nom != ''
                    THEN jsonb_build_object(
                        'herbier', jsonb_build_object(
                                'nomHerbier', h.nom,
                                'partHerbier', o.part_herbier1,
                                'idHerbier', o.id_herbier1
                            )
                        )
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
                WHEN 'P' THEN '{"taxTypeLabel": "Plantes vasculaires"}'
                WHEN 'B' THEN '{"taxTypeLabel": "Bryophytes"}'
                WHEN 'L' THEN '{"taxTypeLabel": "Lichens"}'
                WHEN 'C' THEN '{"taxTypeLabel": "Champignons"}'
                WHEN 'A' THEN '{"taxTypeLabel": "Algues"}'
                ELSE '{"taxType": null}'
            END::jsonb||
            jsonb_build_object('cd_nom', o.cd_nom) ||
            CASE
                WHEN r.meta_id_user_saisie IN (21, 47, 394, 75, 4, 40,48)
                        THEN jsonb_build_object(
                            'digitisers', json_build_object(
                                'nom', dig.nom,
                                'prénom', dig.prenom,
                                'email', dig.email,
                                'org', dig.id_org
                            )
                        )
                ELSE jsonb_build_object ('digitisers', null)
            END
        ) AS additional_data,
        r.meta_date_saisie::timestamp AS meta_create_date,
        greatest(o.meta_date_maj, r.meta_date_maj)::timestamp AS meta_update_date,
        'I' AS meta_last_action
    FROM flore.releve AS r
        JOIN flore.observation AS o
            ON r.id_releve = o.id_releve
        JOIN referentiels.metadata_jdd AS mj
            ON r.id_jdd = mj.id_jdd
        LEFT JOIN referentiels.releve_methode AS rm
            ON r.id_releve_methode = rm.id_releve_methode
        LEFT JOIN referentiels.biblio AS b
            ON r.id_biblio = b.id_biblio
        LEFT JOIN referentiels.nombre_pieds AS np
            ON o.id_nombre_pieds = np.id_nombre_pieds
        LEFT JOIN referentiels.observateur AS det
            ON det.id_obs = o.id_det
        LEFT JOIN applications.utilisateur AS val
            ON val.id_user = o.meta_id_user_valid
        LEFT JOIN flore.cbna_agent AS ca
            ON ca.uuid = val.permid
        LEFT JOIN applications.utilisateur AS dig
            ON dig.id_user = r.meta_id_user_saisie
        LEFT JOIN referentiels.organisme AS ov
            ON val.id_org = ov.id_org AND det.meta_id_groupe = ov.meta_id_groupe
        LEFT JOIN referentiels.organisme AS ovf
            ON r.id_org_f = ovf.id_org
        LEFT JOIN referentiels.catalog_dept AS cd
            ON cd.insee_dept = r.insee_dept AND cd.cd_ref = o.cd_ref
        LEFT JOIN referentiels.commune AS c
            ON r.insee_comm = c.insee_comm
        LEFT JOIN referentiels.taxref AS t
            ON o.cd_nom = t.cd_nom
        LEFT JOIN referentiels.programme AS p
            ON r.meta_id_prog = p.id_prog
        LEFT JOIN referentiels.herbier AS h
            ON o.id_herbier1 = h.id_herbier
        LEFT JOIN evee AS e
            ON e.cd_ref = o.cd_ref
        LEFT JOIN sensi_reg AS se
            ON se.cd_ref = o.cd_ref
        LEFT JOIN sensi_dep AS sed
            ON sed.cd_ref = o.cd_ref AND sed.dept = r.insee_dept::varchar AND sed.dept IN ('01', '26', '38', '73', '74')
        LEFT JOIN flore.validation AS v
            ON v.id_observation = o.id_observation
    WHERE (
        r.meta_id_groupe = 1 AND r.id_precision != 'N' -- non localisable
        OR  (
            r.meta_id_groupe <> 1
            AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')
            AND r.id_precision != 'N'
        )
    )
) TO '/tmp/synthese.csv'
WITH(format csv, header, delimiter E'\t', null '\N');
