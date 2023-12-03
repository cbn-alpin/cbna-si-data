-- Droits d'éxecution nécessaire : DB OWNER
-- Subdivize areas geom with st_subdivide() to faster st_intersect()
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create subdivided areas table'
CREATE TABLE IF NOT EXISTS ref_geo.:areaSubdividedTableName AS
    SELECT
        NULL::int AS gid,
        id_area AS area_id,
        id_type AS type_id,
        geom
    FROM ref_geo.l_areas
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on subdivided areas table'
\set subdividedTablePk 'pk_':areaSubdividedTableName
ALTER TABLE ref_geo.:areaSubdividedTableName
    ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
    ADD CONSTRAINT :subdividedTablePk PRIMARY KEY(gid);


\echo '----------------------------------------------------------------------------'
\echo 'Insert subdivided areas'
INSERT INTO ref_geo.:areaSubdividedTableName (
    area_id,
    type_id,
    geom
)
    SELECT
        a.id_area AS area_id,
        a.id_type AS type_id,
        st_subdivide(a.geom, 255) AS geom
    FROM ref_geo.l_areas AS a
        JOIN ref_geo.bib_areas_types AS t
            ON a.id_type = t.id_type
    WHERE t.type_code IN (:areaSubdividedTypesList)
ON CONFLICT DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Create geom index on subdivided SINP territory table'
\set geomIdx 'idx_':areaSubdividedTableName'_geom'
CREATE INDEX :geomIdx
    ON ref_geo.:areaSubdividedTableName USING gist(geom);


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
