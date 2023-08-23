COPY (
	SELECT
		t.cd_nom,
		NULL AS id_statut,
		CASE 
			WHEN t.habitat ILIKE '0' THEN NULL
			ELSE t.habitat
		END AS id_habitat,
		t.rang AS id_rang,
		t.regne AS regne,
		t.phylum AS phylum,
		t.classe AS classe,
		t.ordre AS ordre,
		t.famille AS famille,
		t.sous_famille AS sous_famille,
		t.tribu AS tribu,
		t.cd_taxsup AS cd_taxsup,
		t.cd_sup AS cd_sup,
		t.cd_ref AS cd_ref,
		t.lib_nom AS lb_nom,
		t.lib_auteur AS lb_auteur,
		t.nom_complet AS nom_complet,
		t.nom_complet_html AS nom_complet_html,
		t.nom_valide AS nom_valide,
		t.nom_vern AS nom_vern,
		t.nom_vern_eng AS nom_vern_eng,
		t.group1_inpn AS group1_inpn,
		t.group2_inpn AS group2_inpn,
		t.url_inpn AS url,
		NULL AS group3_inpn,
		t.meta_date_saisie::timestamp AS meta_create_date,
		t.meta_date_maj::timestamp AS meta_update_date,
		jsonb_build_object(
			'cd_ref_origine', t.cd_ref_origine,
			'user_maj', concat_ws(' ',u.prenom, u.nom, u.email),
			'version', '15.0'
			)::jsonb AS meta_update_comment,
		'I'::character(1) AS meta_last_action
	FROM referentiels.taxref t 
	LEFT JOIN applications.utilisateur u 
		ON u.id_user = t.meta_id_user_maj 
	WHERE cd_ref < 15 OR cd_ref > 20000000

	UNION

	SELECT
		t.cd_nom,
		NULL AS id_statut,
		CASE 
			WHEN t.habitat ILIKE '0' THEN NULL
			ELSE t.habitat
		END AS id_habitat,
		t.rang AS id_rang,
		t.regne AS regne,
		t.phylum AS phylum,
		t.classe AS classe,
		t.ordre AS ordre,
		t.famille AS famille,
		t.sous_famille AS sous_famille,
		t.tribu AS tribu,
		t.cd_taxsup AS cd_taxsup,
		t.cd_sup AS cd_sup,
		t.cd_ref AS cd_ref,
		t.lib_nom AS lb_nom,
		t.lib_auteur AS lb_auteur,
		t.nom_complet AS nom_complet,
		t.nom_complet_html AS nom_complet_html,
		t.nom_valide AS nom_valide,
		t.nom_vern AS nom_vern,
		t.nom_vern_eng AS nom_vern_eng,
		t.group1_inpn AS group1_inpn,
		t.group2_inpn AS group2_inpn,
		t.url_inpn AS url,
		NULL AS group3_inpn,
		t.meta_date_saisie::timestamp AS meta_create_date,
		t.meta_date_maj::timestamp AS meta_update_date,
		jsonb_build_object(
			'cd_ref_origine', t.cd_ref_origine,
			'user_maj', concat_ws(' ',u.prenom, u.nom, u.email),
			'version', '15.0'
			)::jsonb AS meta_update_comment,
		'U'::character(1) AS meta_last_action
	FROM referentiels.taxref t 
	LEFT JOIN applications.utilisateur u 
		ON u.id_user = t.meta_id_user_maj 
	WHERE (cd_ref > 14 AND cd_ref < 20000000) AND cd_ref_origine != cd_ref
)
TO stdout
WITH (format csv, header, delimiter E'\t')
;