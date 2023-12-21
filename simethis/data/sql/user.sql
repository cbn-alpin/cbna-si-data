DROP TABLE IF EXISTS flore.cbna_agent ;

-- Create table, drop at the end of the script, in order to list CBNA agents
-- of the conservation and knowledge services of the CBNA
CREATE TABLE flore.cbna_agent (
    gid SERIAL PRIMARY KEY,
    uuid UUID,
    last_name VARCHAR(100),
    first_name VARCHAR(100),
    entry_date DATE,
    release_date DATE
) ;

-- Insert datas from CSV file to table
COPY flore.cbna_agent(last_name, first_name, entry_date, release_date)
FROM :'cbnaAgentCsvFilePath'
DELIMITER ',' CSV HEADER ;

-- Agent uuid recovery in the table
UPDATE flore.cbna_agent AS ca SET
    uuid = u.permid
FROM applications.utilisateur AS u
WHERE u.id_groupe = 1
    AND lower(unaccent(u.nom)) = lower(unaccent(ca.last_name))
    AND lower(unaccent(u.prenom)) = lower(unaccent(ca.first_name)) ;

DROP TABLE IF EXISTS flore.permid_organism_uuid_duplicates;

CREATE TABLE flore.permid_organism_uuid_duplicates (
    gid SERIAL PRIMARY KEY,
    permid UUID,
    id_org SMALLSERIAL,
    "name" VARCHAR
);

-- Insert datas from CSV file to table
COPY flore.permid_organism_uuid_duplicates(permid, id_org, "name")
FROM :'organismsDuplicatesCsvFilePath'
DELIMITER ',' CSV HEADER;

COPY (
    -- CBNA accreditation territory observers + Users + Digitisers
    WITH cbna_agents AS (
        SELECT DISTINCT ON (u.permid)
            1 AS priority,
            u.permid AS unique_id,
            u.login AS identifier,
            public.delete_space(u.prenom) AS firstname,
            u.nom AS "name",
            public.delete_space(u.email) AS email,
            lower(coalesce(o.uuid_national, o.permid::varchar)) AS code_organism,
            public.delete_space(u.comm) AS "comment",
            TRUE AS "enable",
            jsonb_build_object(
                'code', u.code,
                'idGroupe', u.id_groupe,
                'password', u.pass,
                'lastLogin', u.last_login,
                'key', u."key"
            )::jsonb AS additional_data,
            u.meta_date_saisie::timestamp AS meta_create_date,
            u.meta_date_maj::timestamp AS meta_update_date,
            'I'::char(1) AS meta_last_action
        FROM applications.utilisateur AS u
            LEFT JOIN referentiels.organisme AS o
                ON o.id_org = u.id_org
        WHERE u.id_org = 2785
    ),
    cbna_digitizers AS (
        SELECT DISTINCT ON (u.permid)
            2 AS priority,
            CASE
                WHEN r.meta_id_user_saisie IS NOT NULL
                    THEN u.permid
                ELSE NULL
            END AS unique_id,
            u.login AS identifier,
            public.delete_space(u.prenom) AS firstname,
            u.nom AS "name",
            public.delete_space(u.email) AS email,
            lower(coalesce(o.uuid_national, o.permid::varchar)) AS code_organism,
            public.delete_space(u.comm) AS "comment",
            TRUE AS "enable",
            NULL::jsonb AS additional_data,
            u.meta_date_saisie::timestamp AS meta_create_date,
            u.meta_date_maj::timestamp AS meta_update_date,
            'I'::char(1) AS meta_last_action
        FROM applications.utilisateur AS u
            JOIN flore.releve AS r
                ON r.meta_id_user_saisie = u.id_user
            LEFT JOIN referentiels.organisme AS o
                ON o.id_org = u.id_org
        WHERE r.meta_id_groupe = 1
    ),
    providers_digitizers AS (
        SELECT DISTINCT ON (u.permid)
            3 AS priority,
            CASE
                WHEN r.meta_id_user_saisie IS NOT NULL
                    THEN u.permid
                ELSE NULL
            END AS unique_id,
            u.login AS identifier,
            public.delete_space(u.prenom) AS firstname,
            u.nom AS "name",
            public.delete_space(u.email) AS email,
            lower(coalesce(o.uuid_national, o.permid::varchar)) AS code_organism,
            public.delete_space(u.comm) AS "comment",
            TRUE AS "enable",
            NULL::jsonb AS additional_data,
            u.meta_date_saisie::timestamp AS meta_create_date,
            u.meta_date_maj::timestamp AS meta_update_date,
            'I'::char(1) AS meta_last_action
        FROM applications.utilisateur AS u
            JOIN flore.releve AS r
                ON r.meta_id_user_saisie = u.id_user
            LEFT JOIN referentiels.organisme AS o
                ON o.id_org = u.id_org
        WHERE r.meta_id_groupe <> 1
            AND r.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')
    ),
    cbna_users AS (
        SELECT DISTINCT ON (all_cbna_users.unique_id)
            all_cbna_users.*
        FROM (
            SELECT * FROM cbna_agents
            UNION
            SELECT * FROM cbna_digitizers
            UNION
            SELECT * FROM providers_digitizers
        ) AS all_cbna_users
    ),
    releves_sialp AS (
        -- CTE Observation records produced on the CBNA territory, CBNA Territory Observers
        SELECT
            rel.id_releve,
            rel.date_releve_deb,
            rel.date_releve_fin,
            rel.id_obs1,
            rel.id_obs2,
            rel.id_obs3,
            rel.id_obs4,
            rel.id_obs5,
            rel.id_org_obs1,
            rel.id_org_obs2,
            rel.id_org_obs3,
            rel.id_org_obs4,
            rel.id_org_obs5
        FROM flore.releve AS rel
        WHERE (
            rel.meta_id_groupe = 1
            OR  (
                rel.meta_id_groupe <> 1
                AND rel.insee_dept IN ('04', '05', '01', '26', '38', '73', '74')
            )
        )
    ),
    observers_1 AS (
        SELECT
            flore.check_cbna_agent(r.id_obs1, r.date_releve_deb) AS unique_id,
            NULL AS identifier,
            public.delete_space(o.prenom) AS firstname,
            o.nom AS "name",
            public.delete_space(o.email) AS email,
            coalesce(
                (CASE
                    WHEN lower(org.uuid_national) ~* '^\s*$'
                        THEN NULL
                    WHEN lower(org.uuid_national) IS NOT NULL
                        AND org.permid NOT IN (
                            SELECT permid FROM flore.permid_organism_uuid_duplicates
                        )
                        THEN lower(org.uuid_national)
                    ELSE NULL
                END),
                org.permid::varchar
            ) AS code_organism,
            public.delete_space(o.comm) AS "comment",
            true AS "enable",
            jsonb_build_object(
                'code', o.code,
                'idGroupe', o.meta_id_groupe,
                'anneeNai', o.annee_nai ,
                'anneeDec', o.annee_dec,
                'idObs', r.id_obs1
            )::jsonb AS additional_data,
            o.meta_date_saisie::timestamp AS meta_create_date,
            o.meta_date_maj::timestamp AS meta_update_date,
            'I'::char(1) AS meta_last_action
        FROM releves_sialp AS r
            JOIN referentiels.observateur AS o
                ON o.id_obs = r.id_obs1
            JOIN referentiels.organisme AS org
                ON org.id_org = r.id_org_obs1
    ),
    observers_2 AS (
        SELECT
            flore.check_cbna_agent(r.id_obs2, r.date_releve_deb ) AS unique_id,
            NULL AS identifier,
            public.delete_space(o.prenom) AS firstname,
            o.nom AS "name",
            public.delete_space(o.email) AS email,
            coalesce(
                (CASE
                    WHEN lower(org.uuid_national) ~* '^\s*$'
                        THEN NULL
                    WHEN lower(org.uuid_national) IS NOT NULL
                        AND org.permid NOT IN (
                            SELECT permid FROM flore.permid_organism_uuid_duplicates
                        )
                        THEN lower(org.uuid_national)
                    ELSE NULL
                END),
                org.permid::varchar
            ) AS code_organism,
            public.delete_space(o.comm) AS "comment",
            true AS "enable",
            jsonb_build_object(
                'code', o.code,
                'idGroupe', o.meta_id_groupe,
                'anneeNai', o.annee_nai ,
                'anneeDec', o.annee_dec,
                'idObs', r.id_obs2
            )::jsonb AS additional_data,
            o.meta_date_saisie::timestamp AS meta_create_date,
            o.meta_date_maj::timestamp AS meta_update_date,
            'I'::char(1) AS meta_last_action
        FROM releves_sialp AS r
            JOIN referentiels.observateur AS o
                ON o.id_obs = r.id_obs2
            JOIN referentiels.organisme AS org
                ON org.id_org = r.id_org_obs2
    ),
    observers_3 AS (
        SELECT
            flore.check_cbna_agent(r.id_obs3, r.date_releve_deb) AS unique_id,
            NULL AS identifier,
            public.delete_space(o.prenom) AS firstname,
            o.nom AS "name",
            public.delete_space(o.email) AS email,
            coalesce(
                (CASE
                    WHEN lower(org.uuid_national) ~* '^\s*$'
                        THEN NULL
                    WHEN lower(org.uuid_national) IS NOT NULL
                        AND org.permid NOT IN (
                            SELECT permid FROM flore.permid_organism_uuid_duplicates
                        )
                        THEN lower(org.uuid_national)
                    ELSE NULL
                END),
                org.permid::varchar
            ) AS code_organism,
            public.delete_space(o.comm) AS "comment",
            true AS "enable",
            jsonb_build_object(
                'code', o.code,
                'idGroupe', o.meta_id_groupe,
                'anneeNai', o.annee_nai ,
                'anneeDec', o.annee_dec,
                'idObs', r.id_obs3
            )::jsonb AS additional_data,
            o.meta_date_saisie::timestamp AS meta_create_date,
            o.meta_date_maj::timestamp AS meta_update_date,
            'I'::char(1) AS meta_last_action
        FROM releves_sialp AS r
            JOIN referentiels.observateur AS o
                ON o.id_obs = r.id_obs3
            JOIN referentiels.organisme AS org
                ON org.id_org = r.id_org_obs3
    ),
    observers_4 AS (
        SELECT
            flore.check_cbna_agent(r.id_obs4, r.date_releve_deb) AS unique_id,
            NULL AS identifier,
            public.delete_space(o.prenom) AS firstname,
            o.nom AS "name",
            public.delete_space(o.email) AS email,
            coalesce(
                (CASE
                    WHEN lower(org.uuid_national) ~* '^\s*$'
                        THEN NULL
                    WHEN lower(org.uuid_national) IS NOT NULL
                        AND org.permid NOT IN (
                            SELECT permid FROM flore.permid_organism_uuid_duplicates
                        )
                        THEN lower(org.uuid_national)
                    ELSE NULL
                END),
                org.permid::varchar
            ) AS code_organism,
            public.delete_space(o.comm) AS "comment",
            true AS "enable",
            jsonb_build_object(
                'code', o.code,
                'idGroupe', o.meta_id_groupe,
                'anneeNai', o.annee_nai ,
                'anneeDec', o.annee_dec,
                'idObs', r.id_obs4
            )::jsonb AS additional_data,
            o.meta_date_saisie::timestamp AS meta_create_date,
            o.meta_date_maj::timestamp AS meta_update_date,
            'I'::char(1) AS meta_last_action
        FROM releves_sialp AS r
            JOIN referentiels.observateur AS o
                ON o.id_obs = r.id_obs4
            JOIN referentiels.organisme AS org
                ON org.id_org = r.id_org_obs4
    ),
    observers_5 AS (
        SELECT
            flore.check_cbna_agent(r.id_obs5, r.date_releve_deb) AS unique_id,
            NULL AS identifier,
            public.delete_space(o.prenom) AS firstname,
            o.nom AS "name",
            public.delete_space(o.email) AS email,
            coalesce(
                (CASE
                    WHEN lower(org.uuid_national) ~* '^\s*$'
                        THEN NULL
                    WHEN lower(org.uuid_national) IS NOT NULL
                        AND org.permid NOT IN (
                            SELECT permid FROM flore.permid_organism_uuid_duplicates
                        )
                        THEN lower(org.uuid_national)
                    ELSE NULL
                END),
                org.permid::varchar
            ) AS code_organism,
            public.delete_space(o.comm) AS "comment",
            true AS "enable",
            jsonb_build_object(
                'code', o.code,
                'idGroupe', o.meta_id_groupe,
                'anneeNai', o.annee_nai ,
                'anneeDec', o.annee_dec,
                'idObs', r.id_obs5
            )::jsonb AS additional_data,
            o.meta_date_saisie::timestamp AS meta_create_date,
            o.meta_date_maj::timestamp AS meta_update_date,
            'I'::char(1) AS meta_last_action
        FROM releves_sialp AS r
            JOIN referentiels.observateur AS o
                ON o.id_obs = r.id_obs5
            JOIN referentiels.organisme AS org
                ON org.id_org = r.id_org_obs5
    ),
    observers AS (
        SELECT DISTINCT ON (all_observers.unique_id)
            3 AS priority,
            all_observers.*
        FROM (
            SELECT * FROM observers_1
            UNION
            SELECT * FROM observers_2
            UNION
            SELECT * FROM observers_3
            UNION
            SELECT * FROM observers_4
            UNION
            SELECT * FROM observers_5
        ) AS all_observers
    ),
    users AS (
        SELECT DISTINCT ON (all_users.unique_id)
            unique_id,
            identifier,
            firstname,
            "name",
            email,
            code_organism,
            "comment",
            "enable",
            additional_data,
            meta_create_date,
            meta_update_date,
            meta_last_action
        FROM (
            SELECT * FROM cbna_users
            UNION ALL
            SELECT * FROM observers
            ORDER BY unique_id, priority
        ) AS all_users
    ),
    duplicate_emails AS (
        SELECT email
        FROM users
        GROUP BY email
        HAVING count(*) > 1
    )
    SELECT
        unique_id,
        identifier,
        firstname,
        "name",
        coalesce(
            (
                SELECT replace(u.email, '@', concat('+', u.unique_id, '@'))
                FROM users AS u
                WHERE u.unique_id = users.unique_id
                    AND users.email IN (SELECT email FROM duplicate_emails)
            ),
            users.email
        ) AS email,
        code_organism,
        "comment",
        "enable",
        additional_data,
        meta_create_date,
        meta_update_date,
        meta_last_action
    FROM users
    ORDER BY "name", firstname
) TO '/tmp/user.csv'
WITH(format csv, header, delimiter E'\t', null '\N');
