BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Finalize integration of GN Siflora database'

\echo '-------------------------------------------------------------------------------'
\echo 'Ajout d''un index unique sur le champ t_roles.email'
ALTER TABLE utilisateurs.t_roles DROP CONSTRAINT IF EXISTS unique_email;
ALTER TABLE utilisateurs.t_roles ADD CONSTRAINT unique_email UNIQUE (email);

\echo '-------------------------------------------------------------------------------'
\echo 'Ajout d''un index unique sur le champ t_roles.identifiant'
ALTER TABLE utilisateurs.t_roles DROP CONSTRAINT IF EXISTS unique_identifiant;
ALTER TABLE utilisateurs.t_roles ADD CONSTRAINT unique_identifiant UNIQUE (identifiant);

\echo '-------------------------------------------------------------------------------'
\echo 'Changement de noms des groupes par défaut'
UPDATE utilisateurs.t_roles SET
    nom_role = 'Agents'
WHERE id_role = 1 AND groupe = TRUE;
UPDATE utilisateurs.t_roles SET
    nom_role = 'Administrateurs'
WHERE id_role = 2 AND groupe = TRUE;

\echo '-------------------------------------------------------------------------------'
\echo 'Suppression des utilisateurs exemples inutiles'
DELETE FROM utilisateurs.cor_role_liste crl
USING utilisateurs.t_roles tr
WHERE (crl.id_role = 4 AND tr.identifiant = 'agent')
    OR (crl.id_role = 6 AND tr.identifiant = 'pierre.paul')
    OR (crl.id_role = 7 AND tr.identifiant = 'validateur');

DELETE FROM utilisateurs.t_roles
WHERE (id_role = 4 AND identifiant = 'agent')
    OR (id_role = 6 AND identifiant = 'pierre.paul')
    OR (id_role = 7 AND identifiant = 'validateur');

\echo '-------------------------------------------------------------------------------'
\echo 'Changement sur les utilisateurs'
UPDATE utilisateurs.t_roles SET
    prenom_role = 'Administrateur',
    nom_role = 'GÉNÉRAL',
    remarques='Mise à jour installation.',
    pass = NULL,
    pass_plus = :'passAdmin'
WHERE id_role = 3 AND identifiant = 'admin';
UPDATE utilisateurs.t_roles SET
    id_role = 4,
    identifiant = 'partner-test',
    prenom_role = 'Partenaire',
    nom_role = 'TEST',
    email = 'jp.milcent+partner@cbn-alpin.fr',
    desc_role = 'Compte partenaire.',
    remarques = 'Compte partenaire de test.',
    pass = NULL,
    pass_plus = :'passPartner'
WHERE id_role = 5 AND identifiant = 'partenaire' ;

\echo '-------------------------------------------------------------------------------'
\echo 'Mise à jour de la séquence de la clé primaire de t_roles'
SELECT SETVAL(
    pg_get_serial_sequence('utilisateurs.t_roles', 'id_role'),
    COALESCE(MAX(id_role) + 1, 1),
    FALSE
)
FROM utilisateurs.t_roles;

\echo '-------------------------------------------------------------------------------'
\echo 'Ajout des groupes complémentaires'
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

\echo '-------------------------------------------------------------------------------'
\echo 'Configuration du groupe Admin vis à vis de GeoNature'
INSERT INTO utilisateurs.cor_profil_for_app (
    id_profil,
    id_application
) VALUES (
    (SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Administrateur'),
    (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN')
)
ON CONFLICT DO NOTHING ;

\echo '-------------------------------------------------------------------------------'
\echo 'Association des groupes aux profils pour les applications (GeoNature, TaxHub et UsersHub)'
INSERT INTO utilisateurs.cor_role_app_profil (
    id_role,
    id_application,
    id_profil
) VALUES (
    utilisateurs.get_id_group_by_name('Administrateurs'),
    (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
    (SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Administrateur')
), (
    utilisateurs.get_id_group_by_name('Validateurs'),
    (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
    (SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Lecteur')
), (
    utilisateurs.get_id_group_by_name('Partenaires'),
    (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
    (SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Lecteur')
), (
    utilisateurs.get_id_group_by_name('Datamanagers'),
    (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
    (SELECT id_profil FROM utilisateurs.t_profils WHERE nom_profil = 'Lecteur')
)
ON CONFLICT DO NOTHING ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
