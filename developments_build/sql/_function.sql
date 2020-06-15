-- occ_translation function
CREATE OR REPLACE FUNCTION occ_translate(
	_occ varchar,
	job_type varchar
) 
  RETURNS varchar AS $$
  	SELECT (CASE 
        WHEN job_type = 'New Building' THEN 'Empty Site'
        ELSE (select occ from occ_lookup where dob_occ = _occ)
    END);
$$ LANGUAGE sql;

-- occ_translation function
CREATE OR REPLACE FUNCTION status_translate(
	_status varchar
) 
  RETURNS varchar AS $$
  	select status 
    from status_lookup 
    where dob_status = _status
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION nta_translate(
	_nta varchar
) 
  RETURNS varchar AS $$
  	select ntaname 
    from dcp_ntaboundaries 
    where ntacode = _nta
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION ownership_translate(
	_cityowned varchar,
  _ownertype varchar,
  _nonprofit varchar
) 
  RETURNS varchar AS $$
  	select ownership 
    from ownership_lookup 
    where COALESCE(_cityowned, 'NULL') = COALESCE(cityowned, 'NULL')
    AND COALESCE(_ownertype, 'NULL') = COALESCE(ownertype, 'NULL')
    AND COALESCE(_nonprofit, 'NULL') = COALESCE(nonprofit, 'NULL')
$$ LANGUAGE sql;

-- check if date string is valid function
CREATE OR REPLACE FUNCTION is_date(
    s varchar
) 
  RETURNS boolean AS $$
    BEGIN
      perform s::date;
      RETURN true;
    exception WHEN others THEN
      RETURN false;
    END;
$$ LANGUAGE plpgsql;

-- year quater function
CREATE OR REPLACE FUNCTION year_quater(
	_date date
) 
  RETURNS varchar AS $$
  	select extract(year from _date)::text||'Q'
        ||EXTRACT(QUARTER FROM _date)::text
$$ LANGUAGE sql;


-- spatial join functions
CREATE OR REPLACE FUNCTION get_zipcode(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.zipcode::varchar
      FROM doitt_zipcodeboundaries b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_bbl(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.bbl::bigint::text
      FROM dcp_mappluto b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION get_council(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT lpad(b.coundist::text,2,'0')
      FROM dcp_councildistricts b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION get_boro(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.borocode::varchar
      FROM dcp_boroboundaries_wi b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_csd(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT  lpad(b.schooldist::text,2,'0')
      FROM dcp_school_districts b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_ct(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.ct2010::varchar
      FROM dcp_censustracts b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_cb(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.cb2010::varchar
      FROM dcp_censusblocks b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_nta(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.ntacode::varchar
      FROM dcp_ntaboundaries b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_cd(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.borocd::varchar
      FROM dcp_cdboundaries b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_cd(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.borocd::varchar
      FROM dcp_cdboundaries b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_policeprct(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.precinct::varchar
      FROM dcp_policeprecincts b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_schooldist(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.schooldist::varchar
      FROM dcp_school_districts b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_firecompany(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.firecotype||lpad(b.fireconum::varchar, 3, '0')
      FROM dcp_firecompanies b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_firebattalion(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.firebn::varchar
      FROM dcp_firecompanies b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_firedivision(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.firediv::varchar
      FROM dcp_firecompanies b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_puma(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.puma::varchar
      FROM dcp_puma b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;
  
CREATE OR REPLACE FUNCTION get_bin(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.bin::varchar
      FROM doitt_buildingfootprints b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_base_bbl(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.base_bbl::varchar
      FROM doitt_buildingfootprints b
      WHERE ST_Within(_geom, b.geom)
  $$ LANGUAGE sql;