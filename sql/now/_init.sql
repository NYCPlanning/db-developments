/*
DESCRIPTION:
	Initial field mapping and prelimilary data cleaning for DOB NOW job applications data
	
INPUTS: 
	dob_now_applications

OUTPUTS:
	_INIT_NOW_devdb (
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
		x_withdrawal text,
		existingzoningsqft text,
		proposedzoningsqft text,
		buildingclass text,
		otherdesc text
	)
*/

DROP TABLE IF EXISTS _INIT_NOW_devdb;
SELECT
	distinct
	(ogc_fid::integer + (SELECT MAX(uid::integer) FROM _INIT_BIS_devdb))::text as uid,
	job_filing_number::text as job_number,
	jobtype as job_type,

	(CASE WHEN jobdescription !~ '[a-zA-Z]'
	THEN NULL ELSE jobdescription END) as job_desc,

	existingoccupancyclassification::text as _occ_initial, 
	proposedoccupancyclassification::text as _occ_proposed,
	
    -- set 0 -> null for jobtype = Alteration
	(CASE WHEN jobtype ~* 'Alteration' 
        THEN nullif(existing_stories, '0')::numeric
		ELSE NULL
	END)::numeric as stories_init,

	-- set 0 -> null for jobtype = Alteration
	(CASE WHEN jobtype ~* 'Alteration' 
        THEN nullif(proposed_no_of_stories, '0')::numeric
		ELSE NULL
	END)::numeric as stories_prop,

	NULL::numeric as zoningsft_init,
	NULL::numeric as zoningsft_prop,

    -- if existingdwellingunits is not a number then null
	(CASE WHEN jobtype ~* 'New Building' THEN 0 
		ELSE (CASE WHEN existing_dwelling_units ~ '[^0-9]' THEN NULL
		ELSE existing_dwelling_units::numeric END)
	END)::numeric as classa_init,

    -- if proposeddwellingunits is not a number then null
	(CASE WHEN jobtype ~* 'Demolition' THEN 0
		ELSE (CASE WHEN proposed_dwelling_units ~ '[^0-9]' THEN NULL
			ELSE proposed_dwelling_units::numeric END)
	END)::numeric as classa_prop,

	-- one to one mappings
	filing_status as _job_status,
	current_status_date as date_lastupdt,
	filing_date as date_filed,
	NULL as date_statusd,
	"approved_(date)" as date_statusp,
	permitissueddate as date_statusr,
	signoffdate as date_statusx,
	NULL as ZoningDist1,
	NULL as ZoningDist2,
	NULL as ZoningDist3,
	specialdistrict1 as SpecialDist1,
	specialdistrict2 as SpecialDist2,

	(CASE WHEN landmark ~* 'L' THEN 'Yes'
		ELSE NULL END) as Landmark,

	ownership_translate(
		NULLIF(LEFT(city_owned, 1), 'N'),
		UPPER(ownertype),
		COALESCE(LEFT(nonprofit, 1), 'N')
	) as ownership,
	
	NULL as owner_name,
	owner_s_business_name as Owner_BizNm,
	owner_s_street_name as Owner_Address,
	zip as Owner_ZipCode,
	ownerphone as Owner_Phone,

	(CASE WHEN jobtype ~* 'Alteration' 
		THEN NULLIF(existingbuildingheight, '0')
	END)::numeric as Height_Init,

	(CASE WHEN jobtype ~* 'Alteration' 
		THEN NULLIF(proposedbuildingheight, '0')
	END)::numeric as Height_Prop,

	NULL as ConstructnSF,

	(CASE 
		WHEN (horizontalenlargement ~* 'true' AND NOT verticalenlargement ~* 'false') 
			THEN 'Horizontal'
		WHEN (NOT horizontalenlargement ~* 'false' AND verticalenlargement ~* 'true') 
			THEN 'Vertical'
		WHEN (horizontalenlargement ~* 'true' AND verticalenlargement ~* 'true') 
			THEN 'Horizontal and Vertical'
	END)  as enlargement,

	NULL as EnlargementSF,
	CAST(initial_cost as MONEY)::text as CostEstimate,
	NULL as LoftBoardCert,
	little_e as eDesignation,

	(CASE WHEN worktypes = 'CC' THEN 'Yes'
		ELSE NULL END) as CurbCut,
		
	NULL as TractHomes,
	regexp_replace(
		trim(house_no), 
		'(^|)0*', '', '') as address_numbr,
	trim(street_name) as address_street,
	regexp_replace(
		trim(house_no), 
		'(^|)0*', '', '')||' '||trim(street_name) as address,
	bin as bin,
	LEFT(bin, 1)||lpad(block, 5, '0')||lpad(RIGHT(lot,4), 4, '0') as bbl,
	(CASE WHEN borough ~* 'Manhattan' THEN '1'
		WHEN borough ~* 'Bronx' THEN '2'
		WHEN borough ~* 'Brooklyn' THEN '3'
		WHEN borough ~* 'Queens' THEN '4'
		WHEN borough ~* 'Staten Island' THEN '5' 
	END) as boro,
	NULL::text as zsf_init,
	NULL::text as zsf_prop,
	building_type as bldg_class,
	NULL as desc_other,
	NULL as x_withdrawal,
	ST_SetSRID(ST_Point(
		longitude::double precision,
		latitude::double precision),4326) as dob_geom
INTO _INIT_NOW_devdb
FROM dob_now_applications;