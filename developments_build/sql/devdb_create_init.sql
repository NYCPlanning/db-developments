/*
DESCRIPTION:
	1. Initial field mapping and prelimilary data cleaning
	2. Apply corrections on stories_prop, bin, bbl, x_mixeduse
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
		status_date text,
		status_a text,
		status_d text,
		status_p text,
		status_r text,
		status_x text,
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

	jobdescription as job_description,

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
	latestactiondate::date as status_date,
	prefilingdate as status_a,
	fullypaid as status_d,
	approved as status_p,
	fullypermitted as status_r,
	signoffdate as status_x,
	zoningdist1 as ZoningDist1,
	zoningdist2 as ZoningDist2,
	zoningdist3 as ZoningDist3,
	specialdistrict1 as SpecialDist1,
	specialdistrict2 as SpecialDist2,
	landmarked as Landmark,
	cityowned as CityOwned,
	ownertype as Owner_Type,
	nonprofit as Owner_NonProf,
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
	horizontalenlrgmt as Enlrg_Horiz,
	verticalenlrgmt as Enlrg_Vert,
	enlargementsqfootage as EnlargementSF,
	initialcost as CostEstimate,
	loftboard as LoftBoardCert,
	littlee as eDesignation,
	curbcut as CurbCut,
	cluster as TractHomes,
	regexp_replace(
		regexp_replace(
			trim(housenumber), 
			'GAR|REAR|GARAGE', '', 'g'), 
		'(^|)0*', '', '') as address_house,
	trim(streetname) as address_street,
	regexp_replace(
		regexp_replace(
			trim(housenumber), 
			'GAR|REAR|GARAGE', '', 'g'), 
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
	'' as x_dcpedited,
	'' as x_reason
INTO CORR_devdb
FROM _INIT_devdb;

/*
CORRECTIONS: 
	stories_prop
	x_mixeduse
	bin
	bbl
*/
-- stories_prop
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'stories_prop'
	AND (a.stories_prop=b.old_value::numeric 
		OR (a.stories_prop IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/stories_prop/',
	x_reason = x_reason||'/stories_prop:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET stories_prop = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/stories_prop/');

-- x_mixeduse
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'x_mixeduse'
	AND (upper(a.x_mixeduse)=upper(b.old_value) 
		OR (a.x_mixeduse IS NULL 
		AND (b.old_value IS NULL OR b.old_value = 'false')))
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/x_mixeduse/',
	x_reason = x_reason||'/x_mixeduse:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET x_mixeduse = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/x_mixeduse/');

-- bbl
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'bbl'
	AND a.bbl IS NULL AND b.old_value IS NOT NULL
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/bbl/',
	x_reason = x_reason||'/bbl:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET bbl = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/bbl/');

-- bin
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'bin'
	AND a.bbl IS NULL AND b.old_value IS NOT NULL
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/bin/',
	x_reason = x_reason||'/bin:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _INIT_devdb a
SET bin = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/bin/');