/*
DESCRIPTION:
    Merging MID_devdb with (HNY_devdb & PLUTO_devdb) to create FINAL_devdb
    JOIN KEY: job_number

INPUTS: 

    MID_devdb (
        * job_number,
        ...
    )

    HNY_devdb (
        * job_number,
        hny_id text,
        classa_hnyaff text,
		all_hny_units text,
        hny_jobrelate text
    )

    PLUTO_dedb (
        * job_number
        pluto_unitres,
	    pluto_bldgsf,
	    pluto_comsf,
        pluto_offcsf,
	    pluto_retlsf,
	    pluto_ressf,
	    pluto_yrbuilt,
	    pluto_yralt1,
	    pluto_yralt2,
	    pluto_bldgcls,
	    pluto_landuse,
	    pluto_owntype,
        pluto_owner,
	    pluto_condo,
	    pluto_bldgs,
	    pluto_floors,
	    pluto_firm07,
	    pluto_pfirm15
    )
OUTPUTS: 
    FINAL_devdb (
        * job_number,
        ...
    )
*/
DROP TABLE IF EXISTS FINAL_devdb;
WITH
JOIN_HNY_devdb as (
    SELECT
        a.*,
        b.hny_id,
        b.classa_hnyaff,
        b.all_hny_units,
        b.hny_jobrelate
    FROM MID_devdb a
    LEFT JOIN HNY_devdb b
    ON a.job_number = b.job_number
),
JOIN_HNY_PLUTO_devdb as (
    SELECT
        a.*,
	    b.pluto_unitres,
	    b.pluto_bldgsf,
	    b.pluto_comsf,
        b.pluto_offcsf,
	    b.pluto_retlsf,
	    b.pluto_ressf,
	    b.pluto_yrbuilt,
	    b.pluto_yralt1,
	    b.pluto_yralt2,
	    b.pluto_bldgcls,
	    b.pluto_landuse,
	    b.pluto_owntype,
        b.pluto_owner,
	    b.pluto_condo,
	    b.pluto_bldgs,
	    b.pluto_floors,
	    b.pluto_firm07,
	    b.pluto_pfirm15
    FROM JOIN_HNY_devdb a
    LEFT JOIN PLUTO_devdb b
    ON a.job_number = b.job_number
)
-- Put columns in desired order
SELECT (
    job_number,
    job_type,
    resid_flag,
    nonres_flag,
    job_inactive,
    job_status,
    complete_year,
    complete_qrtr,
    permit_year,
    permit_qrtr,
    classa_init,
    classa_prop,
    classa_net,
    classa_complt,
    classa_incmpl,
    classa_hnyaff,
    hotel_init,
    hotel_prop,
    otherb_init,
    otherb_prop,
    boro,
    bin,
    bbl,
    address_numbr,
    address_st,
    address,
    occ_initial,
    occ_proposed,
    job_desc,
    date_filed,
    date_statusd,
    date_statusp,
    date_permittd,
    date_statusx,
    date_lastupdt,
    date_complete,
    zoningdist1,
    zoningdist2,
    zoningdist3,
    specialdist1,
    specialdist2,
    landmark,
    stories_init,
    stories_prop,
    height_init,
    height_prop,
    zoningsf_init,
    zoningsf_prop,
    constructnsf,
    enlargement,
    enlargementsf,
    costestimate,
    loftboardcert,
    edesignation,
    curbcut,
    tracthomes,
    ownership,
    owner_name,
    owner_biznm,
    owner_address,
    owner_zipcode,
    owner_phone,
    pluto_unitres,
    pluto_bldgsf,
    pluto_comsf,
    pluto_offcsf,
    pluto_retlsf,
    pluto_ressf,
    pluto_yrbuilt,
    pluto_yralt1,
    pluto_yralt2,
    pluto_bldgcls,
    pluto_landuse,
    pluto_owner,
    pluto_owntype,
    pluto_condo,
    pluto_bldgs,
    pluto_floors,
    pluto_version,
    cenblock2010,
    bctcb2010,
    bct2010,
    nta2010,
    ntaname2010,
    puma2010,
    comunitydist,
    councildist,
    schoolsubdist,
    schoolcommnty,
    schoolelmntry,
    schoolmiddle,
    firecompany,
    firebatttalion,
    firedivision,
    policeprecnct,
    depdrainarea,
    deppumpstatn,
    pluto_firm07,
    pluto_pfirm15,
    latitude,
    longitude,
    geomsource,
    hny_id,
    hny_jobrelate,
    '19Q4' as version
)
INTO MID_devdb
FROM JOIN_HNY_PLUTO_devdb;