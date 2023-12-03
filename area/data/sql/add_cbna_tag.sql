-- Add CBNA TAG
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Insert TAG area type'
INSERT INTO ref_geo.bib_areas_types (
    type_name,
    type_code,
    type_desc,
    ref_name,
    ref_version
)
    SELECT
        'TAG du CBNA',
        'TAG',
        'Territoire d''agrément du CBNA constitué par l''agrégation des départements 01, 04, 05, 26, 38, 73, 74.',
        t.ref_name,
        t.ref_version
    FROM ref_geo.bib_areas_types AS t
    WHERE t.type_code = 'DEP'
        AND NOT EXISTS (
        SELECT 'X'
        FROM ref_geo.bib_areas_types AS bat
        WHERE bat.type_code = 'TAG'
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert TAG area'
INSERT INTO ref_geo.l_areas (
    id_type,
    area_name,
    area_code,
    geom,
    "enable"
)
    SELECT
        ref_geo.get_id_area_type('TAG'),
        'TAG CBNA',
        'tag-cbna',
        ST_UNION(g.geom),
        TRUE
    FROM (
        SELECT a.geom
        FROM ref_geo.l_areas AS a
        WHERE a.id_type = ref_geo.get_id_area_type('DEP')
            AND a.area_code IN (:areaTagDeptCodesList)
     ) AS g
     WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = 'tag-cbna'
                AND la.id_type = ref_geo.get_id_area_type('TAG')
        ) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
