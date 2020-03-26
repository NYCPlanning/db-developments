ALTER TABLE dof_dtm
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE dcp_mappluto
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE doitt_buildingfootprints
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE dcp_ntaboundaries
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE dcp_cdboundaries
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE dcp_censusblocks
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE dcp_censustracts
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE dcp_school_districts
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE dcp_boroboundaries_wi
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE dcp_councildistricts
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE doitt_zipcodeboundaries
RENAME COLUMN wkb_geometry TO geom;

ALTER TABLE dob_cofos
DROP COLUMN IF EXISTS ogc_fid,
DROP COLUMN IF EXISTS v;

ALTER TABLE dob_cofos_append
DROP COLUMN IF EXISTS ogc_fid;

INSERT INTO dob_cofos
SELECT * FROM dob_cofos_append;

DROP TABLE IF EXISTS old_devdb;
ALTER TABLE developments
RENAME TO old_devdb;