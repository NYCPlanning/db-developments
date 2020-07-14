/*
DESCRIPTION:

    1. Merge SPATIAL_devdb with _INIT_devdb and create INIT_devdb.

        SPATIAL_devdb + _INIT_devdb -> INIT_devdb

    2. remove records using job_number and bbl 
        in housing_input_research 

INPUTS:
    _INIT_devdb (
        * job_number,
        ... 
    )

    SPATIAL_devdb (
        * job_number,
        ...
    )

    _INIT_qaqc (
        invalid_date_lastupdt,
	    invalid_date_filed,
	    invalid_date_statusd,
	    invalid_date_statusp,
	    invalid_date_statusr,
	    invalid_date_statusx
    )

OUTPUTS:
    
    INIT_devdb (
        _INIT_devdb.*,
        geo_bbl text,
        geo_bin text,
        geo_address_numbr text,
        geo_address_street text,
        geo_address text,
        geo_zipcode text,
        geo_boro text,
        geo_cd text,
        geo_council text,
        geo_ntacode2010 text,
        geo_censusblock2010 text,
        geo_censustract2010 text,
        geo_csd text,
        geo_policeprct text,
        geo_latitude double precision,
        geo_longitude double precision,
        latitude double precision,
        longitude double precision,
        geom geometry,
        geomsource text
    )
*/
/*
Merging spatial attribute table to the Main attribute table
*/
DROP TABLE IF EXISTS INIT_devdb;
SELECT
    distinct
    b.*,
    a.geo_bbl,
    a.geo_bin,
    a.geo_address_numbr,
    a.geo_address_street,
    a.geo_address,
    a.geo_zipcode,
    a.geo_boro,
    a.geo_cd,
    a.geo_council,
    a.geo_ntacode2010,
    a.geo_ntaname2010,
    a.geo_censusblock2010,
    a.geo_censustract2010,
    a.geo_csd,
    a.geo_policeprct,
    a.geo_firedivision,
    a.geo_firebattalion,
    a.geo_firecompany,
    a.geo_puma,
    a.geo_schoolelmntry,
    a.geo_schoolmiddle,
    a.geo_schoolsubdist,
    a.geo_latitude,
    a.geo_longitude,
    a.latitude,
    a.longitude,
    a.geom,
    a.geomsource
INTO INIT_devdb
FROM SPATIAL_devdb a
LEFT JOIN _INIT_devdb b
ON a.uid = b.uid;

-- Format dates in INIT_devdb where valid
UPDATE INIT_devdb
SET date_lastupdt = (CASE WHEN is_date(date_lastupdt) THEN date_lastupdt::date
					ELSE NULL END),
	date_filed = (CASE WHEN is_date(date_filed) THEN date_filed::date
					ELSE NULL END),
	date_statusd = (CASE WHEN is_date(date_statusd) THEN date_statusd::date
					ELSE NULL END),
	date_statusp = (CASE WHEN is_date(date_statusp) THEN date_statusp::date
					ELSE NULL END),
	date_statusr = (CASE WHEN is_date(date_statusr) THEN date_statusr::date
					ELSE NULL END),
	date_statusx = (CASE WHEN is_date(date_statusx) THEN date_statusx::date
					ELSE NULL END);

/*
DEDUPLICATION

For any records that share an identical job_number and BBL, 
keep only the record with the most recent date_lastupdt 
value and remove the older record(s). After this step, job_number
in INIT_devdb will be the uid

*/
WITH latest_records AS (
	SELECT
        job_number, 
        geo_bbl, 
        MAX(date_lastupdt) AS date_lastupdt
	FROM INIT_devdb
	GROUP BY job_number, geo_bbl
	HAVING COUNT(*)>1
)
DELETE FROM INIT_devdb a
USING latest_records b
WHERE a.job_number = b.job_number
AND a.geo_bbl = b.geo_bbl
AND a.date_lastupdt != b.date_lastupdt;

/* 
CORRECTIONS

    job_number (removal)
    bbl (removal)

*/
INSERT INTO housing_input_research 
    (job_number, field)
SELECT 
    job_number, 'remove' as field
FROM INIT_devdb
WHERE UPPER(job_desc) LIKE '%BIS%TEST%' 
    OR UPPER(job_desc) LIKE '% TEST %'
AND job_number NOT IN(
    SELECT DISTINCT job_number
    FROM housing_input_research
    WHERE field = 'remove');

DELETE FROM INIT_devdb a
USING housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'remove';

DELETE FROM INIT_devdb a
USING housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'bbl'
AND a.geo_bbl = b.old_value
AND b.new_value IS NULL;
