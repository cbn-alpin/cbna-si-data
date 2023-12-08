BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Preparing permission insertion query'

SELECT
	CONCAT(
	    e'(\n',
		e'\tutilisateurs.get_id_role_by_uuid(''', r.uuid_role,	'''), -- ', r.nom_role, e'\n',
		e'\tgn_permissions.get_id_action_by_code(''', a.code_action, '''), -- ', a.description_action, e'\n',
		e'\tgn_commons.get_id_module_bycode(''', m.module_code, '''),', e'\n',
		e'\tgn_permissions.get_id_object(''', o.code_object, '''),', e'\n',
		e'\t', COALESCE(p.scope_value::VARCHAR, 'NULL'), e'\n',
		e'),\n'
	)
FROM gn_permissions.t_permissions AS p
	JOIN gn_permissions.bib_actions AS a
		ON p.id_action = a.id_action
	JOIN gn_permissions.t_objects AS o
		ON p.id_object = o.id_object
	JOIN gn_commons.t_modules AS m
		ON p.id_module = m.id_module
	JOIN utilisateurs.t_roles AS r
		ON p.id_role = r.id_role
ORDER BY p.id_role, p.id_module, p.id_action ;

\echo '-------------------------------------------------------------------------------'
\echo 'Add utility functions for permissions'

CREATE OR REPLACE FUNCTION gn_permissions.get_id_action_by_code(actionCode VARCHAR)
 RETURNS INTEGER
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    -- Function which return the id_action of an action by its code
    DECLARE idAction INTEGER;

    BEGIN
        SELECT INTO idAction ba.id_action
        FROM gn_permissions.bib_actions AS ba
        WHERE ba.code_action = actionCode ;

        RETURN idAction ;
    END;
$function$
;

\echo '-------------------------------------------------------------------------------'
\echo 'Configure CBNA roles'

-- Ajout d'un index unique sur le champ t_roles.email
ALTER TABLE utilisateurs.t_roles DROP CONSTRAINT IF EXISTS unique_email;
ALTER TABLE utilisateurs.t_roles ADD CONSTRAINT unique_email UNIQUE (email)

-- Ajout d'un index unique sur le champ t_roles.identifiant
ALTER TABLE utilisateurs.t_roles DROP CONSTRAINT IF EXISTS unique_identifiant;
ALTER TABLE utilisateurs.t_roles ADD CONSTRAINT unique_identifiant UNIQUE (identifiant)

-- Changement de noms des groupes par défaut
UPDATE utilisateurs.t_roles SET
	nom_role = 'Agents'
WHERE id_role = 1 AND groupe = TRUE;
UPDATE utilisateurs.t_roles SET
	nom_role = 'Administrateurs'
WHERE id_role = 2 AND groupe = TRUE;

-- Suppression des utilisateurs exemples inutiles
DELETE FROM utilisateurs.t_roles
WHERE (id_role = 4 AND identifiant = 'agent')
	OR (id_role = 6 AND identifiant = 'pierre.paul')
	OR (id_role = 7 AND identifiant = 'validateur');

-- Changement sur les utilisateurs
UPDATE utilisateurs.t_roles SET
	prenom_role = 'Administrateur',
	nom_role = 'GÉNÉRAL',
	remarques='Mise à jour installation.',
	pass = NULL,
	pass_plus = '$2b$12$NcwUfJ/kd.60giUoGf8sie2k2.aal5NUhpbb6yhj2ux2sLYQiJYTO'
WHERE id_role = 3 AND identifiant = 'admin';
UPDATE utilisateurs.t_roles SET
	id_role = 4,
	identifiant = 'partner-test',
	prenom_role = 'Partenaire',
	nom_role = 'TEST',
	email = 'jp.milcent+test@cbn-alpin.fr',
	desc_role = 'Compte partenaire.',
	remarques = 'Compte partenaire de test.',
	pass = NULL,
	pass_plus = '$2b$12$5rbkVjDL4aJbV18nqXeROePE7lfYR02Zw8mNwHINFHowS3RyctBmi'
WHERE id_role = 5 AND identifiant = 'partenaire' ;

-- Mise à jour de la séquence de la clé primaire de t_roles
SELECT SETVAL(
	pg_get_serial_sequence('utilisateurs.t_roles', 'id_role'),
	COALESCE(MAX(id_role) + 1, 1),
	FALSE
)
FROM utilisateurs.t_roles;

-- Ajout des groupes complémentaires
INSERT INTO utilisateurs.t_roles (
	nom_role,
	groupe,
	uuid_role,
	desc_role,
	remarques
) VALUES (
	'Observateurs',
	TRUE,
	'e944e966-b85f-44c8-acb7-941f6a74ba37',
	'Rassemble tous les observateurs sans accès.',
	'Groupe des observateurs sans accès à GeoNature.'
),
(
	'Partenaires',
	TRUE,
	'cceb3beb-1891-42e9-b01e-ef7a59ad461a',
	'Tous les utilisateurs externes au CBNA. Accès en lecture et écriture uniquement à leurs données dans tous les modules.',
	'Groupe des utilisateurs avec des droits limités en consultation et édition.'
),
(
	'Validateurs',
	TRUE,
	'dd04b9c2-eb93-47b4-80f5-df280b019c9c',
	'Tous les agents du service Connaissance.',
	'Groupe des utilisateurs avec des droits de validation taxonomique.'
),
(
	'Datamanagers',
	TRUE,
	'b259e9a6-136e-4bf9-a0d7-ada2dde7642c',
	'Tous les gestionnaire de données.',
	'Groupe des utilisateurs avec des droits sur les exports et imports.'
)
ON CONFLICT DO NOTHING ;

-- Configuration du groupe Admin vis à vis de GeoNature
INSERT INTO utilisateurs.cor_profil_for_app (
	id_profil,
	id_application
) VALUES (
	(SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Administrateur'),
	(SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN')
)
ON CONFLICT DO NOTHING ;

-- Association des groupes aux profils pour les applications (GeoNature, TaxHub et UsersHub)
INSERT INTO utilisateurs.cor_role_app_profil (
	id_role,
	id_application,
	id_profil
) VALUES (
	utilisateurs.get_id_groupe_by_name('Administrateur'),
	(SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
	(SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Administrateur')
), (
	utilisateurs.get_id_groupe_by_name('Validateurs'),
	(SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
	(SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Lecteur')
), (
	utilisateurs.get_id_groupe_by_name('Partenaires'),
	(SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
	(SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Lecteur')
), (
	utilisateurs.get_id_groupe_by_name('Datamanagers'),
	(SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
	(SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Lecteur')
)
ON CONFLICT DO NOTHING ;

-- Association des groupes aux profils pour les applications (GeoNature, TaxHub et UsersHub)
INSERT INTO gn_permissions.t_permissions (
	id_role,
	id_action,
	id_module,
	id_object,
	scope_value
) VALUES (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('SYNTHESE'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('SYNTHESE'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	2
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	2
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	2
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	2
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b544d3fe-090a-43e2-8517-85b1c00338ba'), -- Agents
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('MOBILE_APPS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('PERMISSIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('PERMISSIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('MOBILE_APPS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('MODULES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('PERMISSIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('MODULES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('MOBILE_APPS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('MODULES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('PERMISSIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('MOBILE_APPS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('PERMISSIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('MOBILE_APPS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('SYNTHESE'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('SYNTHESE'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('5f2c4853-71b0-4b4f-9b23-61f428b06df4'), -- Administrateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('VALIDATION'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('SYNTHESE'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('SYNTHESE'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('OCCTAX'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('OCCHAB'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('cceb3beb-1891-42e9-b01e-ef7a59ad461a'), -- Partenaires
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('VALIDATION'),
	gn_permissions.get_id_object('ALL'),
	1
), (
	utilisateurs.get_id_role_by_uuid('dd04b9c2-eb93-47b4-80f5-df280b019c9c'), -- Validateurs
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('VALIDATION'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOTIFICATIONS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('NOMENCLATURES'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('ADMIN'),
	gn_permissions.get_id_object('ADDITIONAL_FIELDS'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
), (
	utilisateurs.get_id_role_by_uuid('b259e9a6-136e-4bf9-a0d7-ada2dde7642c'), -- Datamanagers
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_bycode('METADATA'),
	gn_permissions.get_id_object('ALL'),
	NULL
)
ON CONFLICT DO NOTHING ;

\echo '-------------------------------------------------------------------------------'
\echo 'Finalize integration of users in GN Siflora database'

-- Mise à jour organisme des utilisateurs pré-existant
UPDATE utilisateurs.t_roles SET
	id_organisme = utilisateurs.get_id_organism_by_uuid('72520b54-879f-4f7c-b202-7e546319f4ee') -- Réseau des botanistes correspondants du CBNA
WHERE identifiant = 'partner-test';

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
