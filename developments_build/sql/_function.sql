-- occ_translation function
CREATE OR REPLACE FUNCTION occ_translate(
	_occ varchar,
	job_type varchar
) 
  RETURNS varchar AS $$
  	SELECT (CASE 
        WHEN job_type = 'New Building' THEN 'Empty Site'
        ELSE (select occ from lookup_occ where dob_occ = _occ)
    END);
$$ LANGUAGE sql;

-- occ_translation function
CREATE OR REPLACE FUNCTION status_translate(
	_status varchar
) 
  RETURNS varchar AS $$
  	select status 
    from lookup_status 
    where dob_status = _status
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION nta_translate(
	_nta varchar
) 
  RETURNS varchar AS $$
  	select distinct ntaname 
    from lookup_nta 
    where nta = _nta
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION ownership_translate(
	_cityowned varchar,
  _ownertype varchar,
  _nonprofit varchar
) 
  RETURNS varchar AS $$
  	select ownership 
    from lookup_ownership
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
CREATE OR REPLACE FUNCTION year_quarter(
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
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_bbl(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.bbl::bigint::text
      FROM dcp_mappluto b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION get_council(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT lpad(b.coundist::text,2,'0')
      FROM dcp_councildistricts b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION get_boro(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.borocode::varchar
      FROM dcp_boroboundaries_wi b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_csd(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT  lpad(b.schooldist::text,2,'0')
      FROM dcp_school_districts b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_ct(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.ct2010::varchar
      FROM dcp_censustracts b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_cb(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.cb2010::varchar
      FROM dcp_censusblocks b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_nta(
    boroct varchar
  ) 
    RETURNS varchar AS $$
      SELECT nta
      FROM lookup_nta
      WHERE boro||ct2010 = boroct
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_ntaname(
    boroct varchar
  ) 
    RETURNS varchar AS $$
      SELECT ntaname
      FROM lookup_nta
      WHERE boro||ct2010 = boroct
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_puma(
    boroct varchar
  ) 
    RETURNS varchar AS $$
      SELECT puma
      FROM lookup_nta
      WHERE boro||ct2010 = boroct
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_cd(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.borocd::varchar
      FROM dcp_cdboundaries b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_cd(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.borocd::varchar
      FROM dcp_cdboundaries b
      WHERE ST_Within(_geom, b.wkb_geometry)
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
      WHERE ST_Within(_geom, b.wkb_geometry)
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
  
CREATE OR REPLACE FUNCTION get_bin(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.bin::varchar
      FROM doitt_buildingfootprints b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_base_bbl(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.base_bbl::varchar
      FROM doitt_buildingfootprints b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_schoolelmntry(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.esid_no::varchar
      FROM doe_eszones b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION get_schoolmiddle(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.msid_no::varchar
      FROM doe_mszones b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_schoolsubdist(
    _geom geometry
  ) 
    RETURNS varchar AS $$
      SELECT b.district||'-'||b.subdistrict
      FROM doe_school_subdistricts b
      WHERE ST_Within(_geom, b.wkb_geometry)
  $$ LANGUAGE sql;

DROP TABLE IF EXISTS dof_shoreline_subdivide;
select ST_SubDivide(wkb_geometry, 100) as wkb_geometry 
into dof_shoreline_subdivide
FROM dof_shoreline;

CREATE OR REPLACE FUNCTION in_water(
    _geom geometry
  ) 
    RETURNS boolean AS $$
      SELECT ST_Within(_geom, b.wkb_geometry) 
      FROM dof_shoreline_subdivide b 
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION flag_nonres(
    _job_description varchar,
    _occ_init varchar,
    _occ_prop varchar
  ) 
    RETURNS varchar AS $$     
    SELECT
    (CASE 
        WHEN _job_description ~* concat(
            'commer|retail|office|mixed|use|mixed-use|mixeduse|store|shop','|',
            'cultur|fitness|gym|service|eating|drink|grocery|market|restau','|',
            'food|cafeteria|cabaret|leisure|entertainment|industrial|manufact','|',
            'warehouse|wholesale|fabric|utility|auto|storage|factor|barn|sound','|',
            'stage|communit|facility|theater|theatre|club|stadium|repair|assembl','|',
            'pavilion|arcade|educat|elementary|school|academy|training|library','|',
            'museum|institut|daycare|day|care|worship|church|synago|religio|hotel','|',
            'motel|transient|health|hospital|classro|clinic|medical|doctor|ambula','|',
            'treatment|diagnos|station|dental|public|tech|science|studies|bank','|',
            'exercise|dancing|dance|gallery|bowling|mercant|veterina|beauty|salon'
          ) OR concat(
                coalesce(_occ_init, ''), ' ', 
                coalesce(_occ_prop, '')
              ) ~* concat(
            'Assembly: Eating & Drinking (A-2)','|', 
            'Assembly: Eating & Drinking (F-4)','|', 
            'Assembly: Indoor Sports (A-4)','|', 
            'Assembly: Museums (F-3)','|', 
            'Assembly: Other (A-3)','|', 
            'Assembly: Other (PUB)','|', 
            'Assembly: Outdoors (A-5)','|', 
            'Assembly: Theaters, Churches(A-1)','|', 
            'Assembly: Theaters, Churches (F-1A)','|', 
            'Assembly: Theaters, Churches (F-1B)','|', 
            'Commercial: Not Specified (COM)','|', 
            'Commercial: Offices (B)','|', 
            'Commercial: Retail (C)','|', 
            'Commercial: Retail (M)','|', 
            'Educational (G)','|', 
            'Industrial: High Hazard (A)','|', 
            'Industrial: High Hazard (H-3)','|', 
            'Industrial: High Hazard (H-4)','|', 
            'Industrial: High Hazard (H-5)','|', 
            'Industrial: Low Hazard (D-2)','|', 
            'Industrial: Moderate Hazard (D-1)','|', 
            'Industrial: Moderate Hazard (F-1)','|', 
            'Institutional: Day Care (I-4)','|', 
            'Miscellaneous (K)','|', 
            'Miscellaneous (U)','|', 
            'Storage: Low Hazard (B-2)','|', 
            'Storage: Low Hazard (S-2)','|', 
            'Storage: Moderate Hazard (B-1)','|', 
            'Storage: Moderate Hazard (S-1)','|', 
            'Unknown (E)','|', 
            'Unknown (F-2)','|', 
            'Unknown (H-1)','|', 
            'Unknown (H-2)'
          ) THEN 'Non-Residential'
        ELSE NULL
    END)
  $$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_DDL(p_table_name varchar)
  RETURNS text AS
$BODY$
DECLARE
    v_table_ddl   text;
    column_record record;
BEGIN
    FOR column_record IN 
        SELECT 
            b.nspname as schema_name,
            b.relname as table_name,
            a.attname as column_name,
            pg_catalog.format_type(a.atttypid, a.atttypmod) as column_type,
            CASE WHEN 
                (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                 FROM pg_catalog.pg_attrdef d
                 WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) IS NOT NULL THEN
                'DEFAULT '|| (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                              FROM pg_catalog.pg_attrdef d
                              WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef)
            ELSE
                ''
            END as column_default_value,
            CASE WHEN a.attnotnull = true THEN 
                'NOT NULL'
            ELSE
                'NULL'
            END as column_not_null,
            a.attnum as attnum,
            e.max_attnum as max_attnum
        FROM 
            pg_catalog.pg_attribute a
            INNER JOIN 
             (SELECT c.oid,
                n.nspname,
                c.relname
              FROM pg_catalog.pg_class c
                   LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
              WHERE c.relname ~ ('^('||lower(p_table_name)||')$')
                AND pg_catalog.pg_table_is_visible(c.oid)
              ORDER BY 2, 3) b
            ON a.attrelid = b.oid
            INNER JOIN 
             (SELECT 
                  a.attrelid,
                  max(a.attnum) as max_attnum
              FROM pg_catalog.pg_attribute a
              WHERE a.attnum > 0 
                AND NOT a.attisdropped
              GROUP BY a.attrelid) e
            ON a.attrelid=e.attrelid
        WHERE a.attnum > 0 
          AND NOT a.attisdropped
        ORDER BY a.attnum
    LOOP
        IF column_record.attnum = 1 THEN
            v_table_ddl:='CREATE TABLE '||column_record.schema_name||'.'||column_record.table_name||' (';
        ELSE
            v_table_ddl:=v_table_ddl||',';
        END IF;

        IF column_record.attnum <= column_record.max_attnum THEN
            v_table_ddl:=v_table_ddl||chr(10)||
                     '    '||column_record.column_name||' '||column_record.column_type||' '||column_record.column_default_value||' '||column_record.column_not_null;
        END IF;
    END LOOP;

    v_table_ddl:=v_table_ddl||');';
    RETURN v_table_ddl;
END;
$BODY$
  LANGUAGE 'plpgsql' COST 100.0 SECURITY INVOKER;