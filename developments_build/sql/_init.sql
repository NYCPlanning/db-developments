/*
DESCRIPTION:
	1. Initial field mapping and prelimilary data cleaning
	2. Apply corrections on stories_prop, bin, bbl, x_mixeduse, and date fields
	3. QAQC check for invalid dates
INPUTS: 
	dob_jobapplications

OUTPUTS:
	INIT_devdb (
		uid text,
		job_number text,
		job_type text,
		job_description text,
		_occ_init text,
		_occ_prop text,
		stories_init numeric,
		stories_prop text,
		zoningsft_init numeric,
		zoningsft_prop numeric,
		_units_init numeric,
		_units_prop numeric,
		x_mixeduse text,
		status text,
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
		cityowned text,
		owner_type text,
		owner_nonprof text,
		owner_firstnm text,
		owner_lastnm text,
		owner_name text,
		owner_biznm text,
		owner_address text,
		owner_zipcode text,
		owner_phone text,
		height_init text,
		height_prop text,
		constructnsf text,
		enlrg_horiz text,
		enlrg_vert text,
		enlargementsf text,
		costestimate text,
		loftboardcert text,
		edesignation text,
		curbcut text,
		tracthomes text,
		address_house text,
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
	THEN NULL ELSE jobdescription END) as job_description,

    -- removing '.' for existingoccupancy 
    -- and proposedoccupancy (3 records affected)
	replace(existingoccupancy, '.', '') as _occ_init, 
    replace(proposedoccupancy, '.', '') as _occ_prop,
    -- set 0 -> null for jobtype = A1 or DM
	(CASE WHEN jobtype ~* 'A1|DM' 
        THEN nullif(existingnumstories, '0')::numeric
		ELSE existingnumstories::numeric
    END) as stories_init,

	proposednumstories::numeric as stories_prop,

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

	existingdwellingunits::numeric as _units_init,

    -- if proposeddwellingunits is not a number then null
	(CASE WHEN proposeddwellingunits ~ '[^0-9]' 
        THEN NULL
		ELSE proposeddwellingunits::numeric
    END) as _units_prop,

	-- mixuse flag
	(CASE WHEN jobdescription ~* 'MIX'
		OR (jobdescription ~* 'RESID' 
			AND jobdescription ~* 'COMM|HOTEL|RETAIL')
		THEN 'Mixed Use'
		ELSE NULL
	END) as x_mixeduse,

	-- one to one mappings
	jobstatusdesc as _status,
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
	
	ownerfirstname as Owner_FirstNm,
	ownerlastname as Owner_LastNm,
	ownerfirstname||', '||ownerlastname as owner_name,
	ownerbusinessname as Owner_BizNm,
	ownerhousestreetname as Owner_Address,
	zip as Owner_ZipCode,
	ownerphone as Owner_Phone,
	existingheight as Height_Init,
	proposedheight as Height_Prop,
	totalconstructionfloorarea as ConstructnSF,

	(CASE 
		WHEN (horizontalenlrgmt = 'Y' AND verticalenlrgmt <> 'Y') 
			THEN 'Enlrg_Horiz'
		WHEN (horizontalenlrgmt <> 'Y' AND verticalenlrgmt = 'Y') 
			THEN 'Enlrg_Vert'
		WHEN (horizontalenlrgmt = 'Y' AND verticalenlrgmt = 'Y') 
			THEN 'Enlrg_Horiz and Enlrg_Vert'
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
		'(^|)0*', '', '') as address_house,
	trim(streetname) as address_street,
	regexp_replace(
		trim(housenumber), 
		'(^|)0*', '', '')||' '||trim(streetname) as address,
	bin as bin,
	LEFT(bin, 1)||lpad(block, 5, '0')||lpad(RIGHT(lot,4), 4, '0') as bbl,
	INITCAP(borough) as boro,
	specialactionstatus as x_withdrawal
INTO _INIT_devdb
FROM dob_jobapplications
WHERE ogc_fid in (select ogc_fid from JOBNUMBER_relevant);

DROP TABLE IF EXISTS CORR_devdb;
SELECT
	job_number,
	array[]::text[] as x_dcpedited,
	array[]::json[] as x_reason
INTO CORR_devdb
FROM _INIT_devdb;

/*
CORRECTIONS: 
	stories_prop
	x_mixeduse
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
SET x_dcpedited = array_append(x_dcpedited, 'stories_prop'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'stories_prop', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET stories_prop = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'stories_prop'=any(x_dcpedited));

-- x_mixeduse
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'x_mixeduse'
	AND (upper(a.x_mixeduse)=upper(b.old_value) 
		OR (a.x_mixeduse IS NULL 
		AND (b.old_value IS NULL OR b.old_value = 'false')))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited, 'x_mixeduse'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'x_mixeduse', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET x_mixeduse = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'x_mixeduse'=any(x_dcpedited));

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
SET x_dcpedited = array_append(x_dcpedited, 'bbl'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'bbl', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET bbl = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'bbl'=any(x_dcpedited));

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
SET x_dcpedited = array_append(x_dcpedited, 'bin'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'bin', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET bin = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'bin'=any(x_dcpedited));

-- date_lastupdt
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_lastupdt'
	AND (a.date_lastupdt::text = b.old_value::text
		OR (a.date_lastupdt IS NULL
			AND b.old_value IS NULL))
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/date_lastupdt/',
	x_reason = x_reason||'/date_lastupdt:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_lastupdt = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/date_lastupdt/');

-- date_filed
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_filed'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/date_filed/',
	x_reason = x_reason||'/date_filed:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_filed = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/date_filed/');

-- date_statusd
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_statusd'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/date_statusd/',
	x_reason = x_reason||'/date_statusd:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_statusd = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/date_statusd/');

-- date_statusp
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_statusp'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/date_statusp/',
	x_reason = x_reason||'/date_statusp:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_statusp = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/date_statusp/');

-- date_statusr
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_statusr'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/date_statusr/',
	x_reason = x_reason||'/date_statusr:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_statusr = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/date_statusr/');

-- date_statusx
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_statusx'
	AND is_date(b.new_value)
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/date_statusx/',
	x_reason = x_reason||'/date_statusx:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET date_statusx = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/date_statusx/');

/** QAQC
	invalid_date_lastupdt
	invalid_date_filed
	invalid_date_statusd
	invalid_date_statusp
	invalid_date_statusr
	invalid_date_statusx
**/


DROP TABLE IF EXISTS _QAQC_devdb;
WITH
-- identify invalid dates in input data
JOBNUMBER_invalid_dates AS (
	SELECT job_number,
		 (CASE WHEN is_date(date_lastupdt) 
		 		OR date_lastupdt IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_lastupdt,
		 (CASE WHEN is_date(date_filed) 
		 		OR date_filed IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_filed,
		 (CASE WHEN is_date(date_statusd) 
		 		OR date_statusd IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_statusd,
		 (CASE WHEN is_date(date_statusp) 
		 		OR date_statusp IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_statusp,
		 (CASE WHEN is_date(date_statusr)
		 		OR date_statusr IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_statusr,
		 (CASE WHEN is_date(date_statusx)
		 		OR date_statusx IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_statusx
		FROM _INIT_devdb )
SELECT *
INTO _QAQC_devdb
FROM JOBNUMBER_invalid_dates;

-- Format dates in _INIT_devdb where valid
UPDATE _INIT_devdb
SET date_lastupdt = CASE WHEN job_number in (SELECT job_number 
							FROM _QAQC_devdb 
							WHERE invalid_date_lastupdt = 1) THEN NULL
					ELSE date_lastupdt::date END),
	date_filed = CASE WHEN job_number in (SELECT job_number 
							FROM _QAQC_devdb 
							WHERE invalid_date_filed = 1) THEN NULL
					ELSE date_filed::date END),
	date_statusd = CASE WHEN job_number in (SELECT job_number 
							FROM _QAQC_devdb 
							WHERE invalid_date_statusd = 1) THEN NULL
					ELSE date_statusd::date END),
	date_statusp = CASE WHEN job_number in (SELECT job_number 
							FROM _QAQC_devdb 
							WHERE invalid_date_statusp = 1) THEN NULL
					ELSE date_statusp::date END),
	date_statusr = CASE WHEN job_number in (SELECT job_number 
							FROM _QAQC_devdb 
							WHERE invalid_date_statusr = 1) THEN NULL
					ELSE date_statusr::date END),
	date_statusx = CASE WHEN job_number in (SELECT job_number 
							FROM _QAQC_devdb 
							WHERE invalid_date_statusx = 1) THEN NULL
					ELSE date_statusx::date END);