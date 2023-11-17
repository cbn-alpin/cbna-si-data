COPY (
    -- Taxon added to TaxRef
    SELECT
        CASE
            WHEN t.cd_nom < 15
                THEN t.cd_nom + 30000000
            ELSE t.cd_nom
        END AS sciname_code,
        NULL AS biogeographic_status_code,
        CASE
            WHEN t.habitat ILIKE '0' THEN NULL
            ELSE t.habitat
        END AS habitat_type_code,
        t.rang AS rank_code,
        t.regne AS kingdom,
        t.phylum AS phylum,
        t.classe AS class,
        t.ordre AS order,
        t.famille AS family,
        t.sous_famille AS subfamily,
        t.tribu AS tribe,
        t.cd_taxsup AS higher_taxon_code_short,
        t.cd_sup AS higher_taxon_code_full,
        CASE
            WHEN t.cd_ref < 15
                THEN t.cd_ref + 30000000
            ELSE t.cd_ref
        END AS taxon_code,
        t.lib_nom AS sciname_short,
        t.lib_auteur AS sciname_author,
        t.nom_complet AS sciname,
        t.nom_complet_html AS sciname_html,
        t.nom_valide AS sciname_valid,
        t.nom_vern AS vernacular_name,
        t.nom_vern_eng AS vernacular_name_en,
        t.group1_inpn AS inpn_group1_label,
        t.group2_inpn AS inpn_group2_label,
        NULL AS inpn_group3_label,
        t.url_inpn AS inpn_url,
        jsonb_build_object(
            'updateComment', jsonb_build_object(
                'commentUpdate', t.comm_modif,
                'comment', t.comm,
                'cdRefOrigine', t.cd_ref_origine,
                'updatedBy', concat_ws(' ', u.prenom, u.nom, u.email),
                'source', t.meta_source
            )
        )::jsonb AS additional_data,
        t.meta_date_saisie::timestamp AS meta_create_date,
        t.meta_date_maj::timestamp AS meta_update_date,
        'I'::character(1) AS meta_last_action
    FROM referentiels.taxref AS t
        LEFT JOIN applications.utilisateur AS u
            ON u.id_user = t.meta_id_user_maj
    WHERE t.cd_ref < 15
        OR (t.cd_ref > 20000000 AND t.cd_nom > 20000000)
        OR t.cd_ref IN (787051, 721916, 101626) -- nouveaux taxons dans Taxref v17

    UNION

    -- Taxon updated in TaxRef
    SELECT
        t.cd_nom AS sciname_code,
        NULL AS biogeographic_status_code,
        CASE
            WHEN t.habitat ILIKE '0' THEN NULL
            ELSE t.habitat
        END AS habitat_type_code,
        t.rang AS rank_code,
        t.regne AS kingdom,
        t.phylum AS phylum,
        t.classe AS class,
        t.ordre AS order,
        t.famille AS family,
        t.sous_famille AS subfamily,
        t.tribu AS tribe,
        t.cd_taxsup AS higher_taxon_code_short,
        t.cd_sup AS higher_taxon_code_full,
        t.cd_ref AS taxon_code,
        t.lib_nom AS sciname_short,
        t.lib_auteur AS sciname_author,
        t.nom_complet AS sciname,
        t.nom_complet_html AS sciname_html,
        t.nom_valide AS sciname_valid,
        t.nom_vern AS vernacular_name,
        t.nom_vern_eng AS vernacular_name_en,
        t.group1_inpn AS inpn_group1_label,
        t.group2_inpn AS inpn_group2_label,
        NULL AS inpn_group3_label,
        t.url_inpn AS inpn_url,
        jsonb_build_object(
            'updateComment', jsonb_build_object(
                'commentUpdate', t.comm_modif,
                'comment', t.comm,
                'cdRefOrigine', t.cd_ref_origine,
                'updatedBy', concat_ws(' ', u.prenom, u.nom, u.email),
                'source', t.meta_source
            )
        )::jsonb AS additional_data,
        t.meta_date_saisie::timestamp AS meta_create_date,
        t.meta_date_maj::timestamp AS meta_update_date,
        'U'::character(1) AS meta_last_action
    FROM referentiels.taxref AS t
        LEFT JOIN applications.utilisateur AS u
            ON u.id_user = t.meta_id_user_maj
    WHERE t.cd_ref_origine != t.cd_ref
        AND t.cd_ref > 14
        AND t.cd_ref < 20000000
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
