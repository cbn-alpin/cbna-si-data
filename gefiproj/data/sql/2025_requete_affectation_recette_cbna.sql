-- cat ./2025_requete_affectation_recette_cbna.sql | ssh admin@webapps 'cd ~/docker/gefiproj/; docker compose run --rm gefiproj-postgres /bin/bash -c "psql --no-psqlrc -p 5432 -U dbprod -d proddb"' > ./$(date +'%F')_affectation_recette_cbna.csv
COPY (
	SELECT 
		p.code_p AS code_projet, 
		p.nom_p AS nom_projet, 
		r.annee_r AS annee_recette, 
		REPLACE(r.montant_r::text, '.', ',') AS montant_recette,
		REPLACE(CAST(affectation_2018.montant AS varchar), '.', ',') AS affectation_2018,
		REPLACE(CAST(affectation_2019.montant AS varchar), '.', ',') AS affectation_2019,
		REPLACE(CAST(affectation_2020.montant AS varchar), '.', ',') AS affectation_2020,
		REPLACE(CAST(affectation_2021.montant AS varchar), '.', ',') AS affectation_2021,
		REPLACE(CAST(affectation_2022.montant AS varchar), '.', ',') AS affectation_2022,
		REPLACE(CAST(affectation_2023.montant AS varchar), '.', ',') AS affectation_2023,
		REPLACE(CAST(affectation_2024.montant AS varchar), '.', ',') AS affectation_2024,
		REPLACE(CAST(affectation_2025.montant AS varchar), '.', ',') AS affectation_2025,
		REPLACE(CAST(affectation_2026.montant AS varchar), '.', ',') AS affectation_2026,
		REPLACE(CAST(affectation_2027.montant AS varchar), '.', ',') AS affectation_2027,
		REPLACE(CAST(affectation_2028.montant AS varchar), '.', ',') AS affectation_2028,
		REPLACE(CAST(affectation_2029.montant AS varchar), '.', ',') AS affectation_2029,
		REPLACE(CAST(affectation_2030.montant AS varchar), '.', ',') AS affectation_2030,
		REPLACE(CAST(affectation_2031.montant AS varchar), '.', ',') AS affectation_2031
	FROM recette AS r
		JOIN financement AS f
			ON r.id_f = f.id_f 
		JOIN projet AS p 
			ON f.id_p = p.id_p,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2018
		 ) AS affectation_2018,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2019
		 ) AS affectation_2019,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2020
		 ) AS affectation_2020,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2021
		 ) AS affectation_2021,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2022
		 ) AS affectation_2022,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2023
		 ) AS affectation_2023,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2024
		 ) AS affectation_2024,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2025
		 ) AS affectation_2025,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2026
		 ) AS affectation_2026,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2027
		 ) AS affectation_2027,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2028
		 ) AS affectation_2028,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2029
		 ) AS affectation_2029,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2030
		 ) AS affectation_2030,
		LATERAL (
			SELECT SUM(ma.montant_ma) AS montant FROM montant_affecte AS ma WHERE ma.id_r = r.id_r AND ma.annee_ma = 2031
		 ) AS affectation_2031
	WHERE p.statut_p = false 
	ORDER BY p.code_p ASC, r.annee_r ASC
) TO stdout
WITH (format csv, header, delimiter E'\t');
