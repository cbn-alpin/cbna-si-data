-- Add countries
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Insert COUNTRY area type'
INSERT INTO ref_geo.bib_areas_types (
    type_name,
    type_code,
    type_desc,
    ref_name,
    ref_version
)
    SELECT
        'Pays',
        'COUNTRY',
        'Frontière des pays.',
        'OSM-Boundaries',
        regexp_replace(:'areaCountryDbName', '\D', '', 'g')::INTEGER
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM ref_geo.bib_areas_types AS bat
        WHERE bat.type_code = 'COUNTRY'
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'Create temporary country table'
DROP TABLE IF EXISTS ref_geo.tmp_country ;
CREATE UNLOGGED TABLE ref_geo.tmp_country ("data" JSONB) ;


\echo '----------------------------------------------------------------------------'
\echo 'Copy JSON file to temporary country table'
\COPY ref_geo.tmp_country ("data") FROM '${areaCountryEwktFilePath}';


\echo '----------------------------------------------------------------------------'
\echo 'Upsert country infos to geographic referentiel areas table'

DROP TYPE IF EXISTS ref_geo.country_type ;
CREATE TYPE ref_geo.country_type AS (
    osm_id INTEGER,
    boundary VARCHAR(255),
    admin_level INTEGER,
    parents INTEGER,
    "name" VARCHAR(255),
    local_name VARCHAR(255),
    name_en VARCHAR(255),
    all_tags JSONB,
    geom GEOMETRY
) ;

INSERT INTO ref_geo.l_areas (
    id_type,
    area_code,
    area_name,
    geom,
    centroid,
    source,
    comment,
    additional_data
)
    SELECT
        ref_geo.get_id_area_type('COUNTRY') AS id_type,
        d.all_tags->>'ISO3166-1:alpha2' AS area_code,
        d.all_tags->>'name:fr' AS area_name,
        st_transform(d.geom, 2154) AS geom,
        st_centroid(st_transform(d.geom, 2154)) AS centroid,
        CONCAT('OSM-Boundaries', ' - ', :'areaCountryDbName') AS "source",
        CONCAT('Imported with cbna-si-data/area script', ' - ', NOW()) AS "comment",
        d.all_tags AS additional_data
    FROM ref_geo.tmp_country AS c
        CROSS JOIN LATERAL jsonb_populate_recordset(NULL::ref_geo.country_type, c."data") AS d
ON CONFLICT (id_type, area_code) DO UPDATE
    SET area_name = EXCLUDED.area_name,
        geom = EXCLUDED.geom,
        centroid = EXCLUDED.centroid,
        source = EXCLUDED.source,
        comment = EXCLUDED.comment,
        additional_data = EXCLUDED.additional_data
;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
