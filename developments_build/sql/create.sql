DROP TABLE IF EXISTS INIT_devdb;
WITH
-- identify admin jobs
JOBNUMBER_admin_jobs as (
	select jobnumber
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
	select jobnumber
	from dob_jobapplications
	where 
		jobnumber not in (select jobnumber from JOBNUMBER_admin_jobs)
		AND jobdocnumber = '01' 
		AND jobtype ~* 'A1|DM|NB'
) SELECT 
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

	-- one to one mappings
	jobstatusdesc as status,
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