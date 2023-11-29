BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Finalize integration of users in GN Siflora database'

-- Mise à jour organisme des utilisateurs pré-existant
UPDATE utilisateurs.t_roles SET
	id_organisme = utilisateurs.get_id_organism_by_uuid('72520b54-879f-4f7c-b202-7e546319f4ee') -- Réseau des botanistes correspondants du CBNA
WHERE identifiant = 'jpm-perso';

-- Ajout des utilisateurs au groupe Administrateurs
INSERT INTO utilisateurs.cor_roles (
	id_role_groupe,
	id_role_utilisateur
)
	SELECT
		utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
		id_role
	FROM utilisateurs.t_roles
	WHERE email IN (
			'c.hoarau@cbn-alpin.fr',
			'c.bionda@cbn-alpin.fr'
		)
		AND identifiant IS NOT NULL
ON CONFLICT DO NOTHING ;

-- Ajout des utilisateurs au groupe Agents
INSERT INTO utilisateurs.cor_roles (
	id_role_groupe,
	id_role_utilisateur
)
	SELECT
		utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
		id_role
	FROM utilisateurs.t_roles
	WHERE identifiant IS NOT NULL
		AND email IS NOT NULL
		AND email ILIKE '%@cbn-alpin.fr'
ON CONFLICT DO NOTHING ;

-- Ajout des utilisateurs au groupe Validateurs
INSERT INTO utilisateurs.cor_roles (
	id_role_groupe,
	id_role_utilisateur
)
	SELECT
		utilisateurs.get_id_role_by_uuid('dd04b9c2-eb93-47b4-80f5-df280b019c9c'), -- Validateurs
		id_role
	FROM utilisateurs.t_roles
	WHERE email IN (
			's.abdulhak@cbn-alpin.fr',
			'l.garraud@cbn-alpin.fr',
			'j.van-es@cbn-alpin.fr',
			'g.pache@cbn-alpin.fr',
			't.legland@cbn-alpin.fr',
			'b.merhan@cbn-alpin.fr',
			'p.debay@cbn-alpin.fr',
			'm.michoulier@cbn-alpin.fr',
			'l.bizard@cbn-alpin.fr',
			'l.wirtz@cbn-alpin.fr'
		)
		AND identifiant IS NOT NULL
ON CONFLICT DO NOTHING ;

-- Ajout des utilisateurs au groupe Datamanagers
INSERT INTO utilisateurs.cor_roles (
	id_role_groupe,
	id_role_utilisateur
)
	SELECT
		utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
		id_role
	FROM utilisateurs.t_roles
	WHERE email IN (
			'jm.genis@cbn-alpin.fr',
			'm.molinatti@cbn-alpin.fr',
			'm.isenmann@cbn-alpin.fr',
			'c.hoarau@cbn-alpin.fr'
		)
		AND identifiant IS NOT NULL
ON CONFLICT DO NOTHING ;

-- Ajout des utilisateurs au groupe Partenaires
INSERT INTO utilisateurs.cor_roles (
	id_role_groupe,
	id_role_utilisateur
)
	SELECT
		utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
		id_role
	FROM utilisateurs.t_roles
	WHERE email IS NOT NULL
		AND identifiant IS NOT NULL
		AND email NOT ILIKE '%@cbn-alpin.fr'
ON CONFLICT DO NOTHING ;

-- Ajout des observateurs au groupe Observateurs
INSERT INTO utilisateurs.cor_roles (
	id_role_groupe,
	id_role_utilisateur
)
	SELECT
		utilisateurs.get_id_role_by_uuid('e944e966-b85f-44c8-acb7-941f6a74ba37'), -- Observateurs
		id_role
	FROM utilisateurs.t_roles
	WHERE email IS NULL
		AND identifiant IS NULL
ON CONFLICT DO NOTHING ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
