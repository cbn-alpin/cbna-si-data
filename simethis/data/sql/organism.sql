-- In order to list the duplicates of the uuid_national of the organism table, we created a query linked below
-- https://wiki-intranet.cbn-alpin.fr/projets/feder-si/migration-simethis-geonature#requete_permettant_de_lister_les_doublons_des_uuid_national_des_organismes

CREATE TABLE flore.permid_organism_uuid_duplicates(
	gid serial PRIMARY KEY,
	permid uuid,
	id_org smallserial,
	"name" varchar
);	
INSERT INTO flore.permid_organism_uuid_duplicates(
	permid,
	id_org,
	"name"
)
VALUES ('ab8a47df-1cf0-4206-8307-5ef8a65cb8db', '3089', 'Société Botanique de Lyon'), 
	   ('77304c59-6a03-48ba-b8e2-2926aaf1f39c', '10219', 'CBN du Massif Central (CHLORIS)'),
	   ('82568af7-b02a-437f-9ff6-dbb0f4ad0330', '10099', 'Syndicat intercommunal du Vuache'),
	   ('8a2a3558-5150-41a0-b850-0802e5c3e392', '3179', 'Université Joseph Fourier'),
	   ('e254dcb1-42b1-455f-a7d9-9cb9d50bf66f', '10286', 'Direction Départementale de lAgriculture et de la Forêt 05');
COPY (
SELECT DISTINCT ON (unique_id)
	COALESCE(
		(CASE
			WHEN lower(ov.uuid_national) ~* '^\s*$'
				THEN NULL 
			WHEN lower(ov.uuid_national) IS NOT NULL 
				AND ov.permid NOT IN (SELECT poud.permid FROM flore.permid_organism_uuid_duplicates poud)
				THEN lower(ov.uuid_national)
			ELSE NULL
		 END),
		 ov.permid::varchar
	) AS unique_id,
	ov.nom AS name,
	ov.adresse AS adress,
	public.delete_space(ov.cp) AS postal_code,
	public.delete_space(ov.ville) AS city,
	LEFT(public.delete_space(ov.tel),14) AS phone,
	NULL::bpchar AS fax,
	public.delete_space(ov.email) AS email,
	public.delete_space(ov.web) AS url,
	NULL::bpchar AS logo_url,
	jsonb_strip_nulls(
		CASE
        	WHEN ov.id_org IS NOT NULL
        		THEN jsonb_build_object('infoSup',
        			jsonb_build_object(
        				'idOrg', ov.id_org,
        				'code', ov.code,
        				'pays', ov.pays,
        				'sinpDspublique', ov.sinp_dspublique,
        				'metaIdGroupe', ov.meta_id_groupe,
        				'comm', ov.comm,
        				'permid', ov.permid,
        				'fichier1', ov.fichier1)				
        				)
        	ELSE jsonb_build_object('infoSup', null)
        	END ||
        CASE
			WHEN ov.uuid_national ~* '^\s*$' OR  ov.uuid_national IS NULL 
			THEN jsonb_build_object('is_uuid_national', false)
			ELSE jsonb_build_object('is_uuid_national', TRUE)
        END::jsonb) AS additional_data,	
	ov.meta_date_saisie::timestamp AS meta_create_date,
		CASE 
	    	WHEN ov.meta_date_maj IS NOT NULL OR ov.meta_date_maj::varchar !~* '^\s*$'
	    		THEN ov.meta_date_maj::timestamp
	    	ELSE NULL
	    END AS meta_update_date,
	'I' AS meta_last_action
	FROM referentiels.organisme ov
JOIN flore.releve r ON r.id_org_f = ov.id_org
	OR r.id_org_obs1 = ov.id_org OR r.id_org_obs2 = ov.id_org OR r.id_org_obs3 = ov.id_org OR r.id_org_obs4 = ov.id_org OR r.id_org_obs5 = ov.id_org
WHERE (r.meta_id_groupe = 1
	OR  (r.meta_id_groupe <> 1
	AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')))
) TO stdout
WITH (format csv, header, delimiter E'\t')
;

DROP TABLE IF EXISTS flore.permid_organism_uuid_duplicates;


