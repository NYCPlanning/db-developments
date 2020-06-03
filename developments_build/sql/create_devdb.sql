/*
DESCRIPTION:
	Initial field mapping and prelimilary data cleaning

INPUTS: 
	dob_jobapplications

OUTPUTS:
	INIT_devdb (
		job_number text,
		job_type text,
		job_description text,
		_occ_init text,
		_occ_prop text,
		occ_category text,
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
		x_withdrawal text,
		latitude double precision,
		longitude double precision,
		geom geometry
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
DROP TABLE IF EXISTS INIT_devdb;
WITH
-- identify admin jobs
JOBNUMBER_admin_jobs as (
	select distinct jobnumber
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
	select distinct jobnumber
	from dob_jobapplications
	where 
		jobnumber not in (select jobnumber from JOBNUMBER_admin_jobs)
		AND jobdocnumber = '01' 
		AND jobtype ~* 'A1|DM|NB'
) SELECT 
	distinct jobnumber as job_number,

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
	NULL as occ_category,

    -- set 0 -> null for jobtype = A1 or DM
	(CASE WHEN jobtype ~* 'A1|DM' 
        THEN nullif(existingnumstories, '0')::numeric
		ELSE existingnumstories::numeric
    END) as stories_init,

	proposednumstories as stories_prop,

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
	latestactiondate as status_date,
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
	trim(housenumber) as address_house,
	trim(streetname) as address_street,
	trim(housenumber)||' '||trim(streetname) as address,
	bin as bin,
	LEFT(bin, 1)||lpad(block, 5, '0')||lpad(RIGHT(lot,4), 4, '0') as bbl,
	INITCAP(borough) as boro,
	specialactionstatus as x_withdrawal,
	latitude as latitude,
	longitude as longitude,
	ST_SetSRID(ST_Point(longitude, latitude),4326) as geom
INTO INIT_devdb
FROM dob_jobapplications
WHERE jobnumber in (select jobnumber from JOBNUMBER_relevant);