/*
DESCRIPTION:
	1. Initial field mapping and prelimilary data cleaning
	2. Apply corrections on stories_prop, bin, bbl, and date fields
	3. QAQC check for invalid dates
INPUTS: 
	dob_jobapplications

OUTPUTS:
	INIT_devdb (
		uid text,
		job_number text,
		job_type text,
		job_desc text,
		_occ_initial text,
		_occ_proposed text,
		stories_init numeric,
		stories_prop text,
		zoningsft_init numeric,
		zoningsft_prop numeric,
		classa_init numeric,
		classa_prop numeric,
		_job_status text,
		date_lastupdt text,
		date_filed text,
		date_statusd text,
		date_statusp text,
		date_statusr text,
		date_statusx text,
		zoningdist1 text,
		zoningdist2 text,
		zoningdist3 text,
		specialdist1 text,
		specialdist2 text,
		landmark text,
		ownership text,
		owner_name text,
		owner_biznm text,
		owner_address text,
		owner_zipcode text,
		owner_phone text,
		height_init text,
		height_prop text,
		constructnsf text,
		enlargement text,
		enlargementsf text,
		costestimate text,
		loftboardcert text,
		edesignation text,
		curbcut text,
		tracthomes text,
		address_numbr text,
		address_street text,
		address text,
		bin text,
		bbl text,
		boro text,
		x_withdrawal text
	)
	
IN PREVIOUS VERSION: 
    create.sql
    jobnumber.sql
	adminjobs.sql
	clean.sql
	address.sql
	jobtype.sql
	x_mixeduse.sql
*/

DROP TABLE IF EXISTS _INIT_devdb;
WITH
-- identify admin jobs
JOBNUMBER_admin_jobs as (
	select ogc_fid
	from dob_jobapplications
	WHERE upper(jobdescription) LIKE '%NO WORK%'
	OR ((upper(jobdescription) LIKE '%ADMINISTRATIVE%'
		AND jobtype <> 'NB')
	OR (upper(jobdescription) LIKE '%ADMINISTRATIVE%'
		AND upper(jobdescription) NOT LIKE '%ERECT%'
		AND jobtype = 'NB'))
),
-- identify relevant_jobs
JOBNUMBER_relevant as (
	select ogc_fid
	from dob_jobapplications
	where 
		ogc_fid not in (select ogc_fid from JOBNUMBER_admin_jobs)
		AND jobdocnumber = '01'
		AND jobtype ~* 'A1|DM|NB'
) SELECT
	distinct
	ogc_fid as uid,
	jobnumber as job_number,

    -- Job Type recoding
	(CASE 
		WHEN jobtype = 'A1' THEN 'Alteration'
		WHEN jobtype = 'DM' THEN 'Demolition'
		WHEN jobtype = 'NB' THEN 'New Building'
		ELSE jobtype
	END ) as job_type,

	(CASE WHEN jobdescription !~ '[a-zA-Z]'
	THEN NULL ELSE jobdescription END) as job_desc,

    -- removing '.' for existingoccupancy 
    -- and proposedoccupancy (3 records affected)
	replace(existingoccupancy, '.', '') as _occ_initial, 
    replace(proposedoccupancy, '.', '') as _occ_proposed,
	
    -- set 0 -> null for jobtype = A1 or DM
	(CASE WHEN jobtype ~* 'A1|DM' 
        THEN nullif(existingnumstories, '0')::numeric
		ELSE NULL
    END) as stories_init,

	-- set 0 -> null for jobtype = A1 or NB
	(CASE WHEN jobtype ~* 'A1|NB' 
        THEN nullif(proposednumstories, '0')::numeric
		ELSE NULL
    END) as stories_prop,

    -- set 0 -> null for jobtype = A1 or DM\
	(CASE WHEN jobtype ~* 'A1|DM' 
        THEN nullif(existingzoningsqft, '0')::numeric
		ELSE existingzoningsqft::numeric
    END) as zoningsft_init,

    -- set 0 -> null for jobtype = A1 or DM
	(CASE WHEN jobtype ~* 'A1|DM' 
        THEN nullif(proposedzoningsqft, '0')::numeric
		ELSE proposedzoningsqft::numeric 
    END) as zoningsft_prop,

    -- if existingdwellingunits is not a number then null
        (CASE WHEN jobtype ~* 'NB' THEN 0 
        ELSE (CASE WHEN existingdwellingunits ~ '[^0-9]' THEN NULL
            ELSE existingdwellingunits::numeric END)
    END) as classa_init,

    -- if proposeddwellingunits is not a number then null
	(CASE WHEN jobtype ~* 'DM' THEN 0
		ELSE (CASE WHEN proposeddwellingunits ~ '[^0-9]' THEN NULL
			ELSE proposeddwellingunits::numeric END)
	END) as classa_prop,

	-- one to one mappings
	jobstatusdesc as _job_status,
	latestactiondate as date_lastupdt,
	prefilingdate as date_filed,
	fullypaid as date_statusd,
	approved as date_statusp,
	fullypermitted as date_statusr,
	signoffdate as date_statusx,
	zoningdist1 as ZoningDist1,
	zoningdist2 as ZoningDist2,
	zoningdist3 as ZoningDist3,
	specialdistrict1 as SpecialDist1,
	specialdistrict2 as SpecialDist2,

	(CASE WHEN landmarked = 'Y' THEN 'Yes'
		ELSE NULL END) as Landmark,

	ownership_translate(
		cityowned,
		ownertype,
		nonprofit
	) as ownership,
	
	ownerlastname||', '||ownerfirstname as owner_name,
	ownerbusinessname as Owner_BizNm,
	ownerhousestreetname as Owner_Address,
	zip as Owner_ZipCode,
	ownerphone as Owner_Phone,

	(CASE WHEN jobtype ~* 'A1|DM' 
		THEN NULLIF(existingheight, '0')
	END)::numeric as Height_Init,

	(CASE WHEN jobtype ~* 'A1|NB' 
		THEN NULLIF(proposedheight, '0')
	END)::numeric as Height_Prop,

	totalconstructionfloorarea as ConstructnSF,

	(CASE 
		WHEN (horizontalenlrgmt = 'Y' AND verticalenlrgmt <> 'Y') 
			THEN 'Horizontal'
		WHEN (horizontalenlrgmt <> 'Y' AND verticalenlrgmt = 'Y') 
			THEN 'Vertical'
		WHEN (horizontalenlrgmt = 'Y' AND verticalenlrgmt = 'Y') 
			THEN 'Horizontal and Vertical'
	END)  as enlargement,

	enlargementsqfootage as EnlargementSF,
	initialcost as CostEstimate,

	(CASE WHEN loftboard = 'Y' THEN 'Yes'
		ELSE NULL END) as LoftBoardCert,

	(CASE WHEN littlee = 'Y' THEN 'Yes'
		WHEN littlee = 'H' THEN 'Yes'
		ELSE NULL END) as eDesignation,

	(CASE WHEN curbcut = 'X' THEN 'Yes'
		ELSE NULL END) as CurbCut,
		
	cluster as TractHomes,
	regexp_replace(
		trim(housenumber), 
		'(^|)0*', '', '') as address_numbr,
	trim(streetname) as address_street,
	regexp_replace(
		trim(housenumber), 
		'(^|)0*', '', '')||' '||trim(streetname) as address,
	bin as bin,
	LEFT(bin, 1)||lpad(block, 5, '0')||lpad(RIGHT(lot,4), 4, '0') as bbl,
	CASE WHEN borough ~* 'Manhattan' THEN '1'
		WHEN borough ~* 'Bronx' THEN '2'
		WHEN borough ~* 'Brooklyn' THEN '3'
		WHEN borough ~* 'Queens' THEN '4'
		WHEN borough ~* 'Staten Island' THEN '5' 
		END as boro,
	specialactionstatus as x_withdrawal,
	ST_SetSRID(ST_Point(
		longitude::double precision,
		latitude::double precision),4326) as dob_geom
INTO _INIT_devdb
FROM dob_jobapplications
WHERE ogc_fid in (select ogc_fid from JOBNUMBER_relevant);

DROP TABLE IF EXISTS CORR_devdb;
SELECT 
	a.job_number,
	array[]::text[] as dcpeditfields
INTO CORR_devdb
FROM (
	SELECT
		distinct
		job_number
	FROM _INIT_devdb
) a;

/*
CORRECTIONS: 
	stories_prop
	bin
	bbl
	date_lastupdt
	date_filed
	date_statusd
	date_statusp
	date_statusr
	date_statusx
*/
-- stories_prop
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'stories_prop'
	AND (a.stories_prop=b.old_value::numeric 
		OR (a.stories_prop IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'stories_prop')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET stories_prop = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'stories_prop'=any(dcpeditfields));


-- bbl
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'bbl'
	AND a.bbl IS NULL AND b.old_value IS NOT NULL
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'bbl')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET bbl = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'bbl'=any(dcpeditfields));

-- bin
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'bin'
	AND a.bbl IS NULL AND b.old_value IS NOT NULL
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'bin')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET bin = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'bin'=any(dcpeditfields));

-- date_lastupdt
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_lastupdt'
	AND (a.date_lastupdt::text = b.old_value::text
		OR (a.date_lastupdt IS NULL
			AND b.old_value IS NULL))
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'date_lastupdt')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_lastupdt = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'date_lastupdt'=any(dcpeditfields));

-- date_filed
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_filed'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'date_filed')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_filed = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'date_filed'=any(dcpeditfields));

-- date_statusd
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_statusd'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'date_statusd')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_statusd = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'date_statusd'=any(dcpeditfields));

-- date_statusp
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_statusp'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'date_statusp')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_statusp = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'date_statusp'=any(dcpeditfields));

-- date_statusr
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_statusr'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'date_statusr')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_statusr = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'date_statusr'=any(dcpeditfields));

-- date_statusx
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_statusx'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'date_statusx')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_statusx = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'date_statusx'=any(dcpeditfields));

