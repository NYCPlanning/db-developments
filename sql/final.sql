DROP TABLE IF EXISTS FINAL_devdb;
SELECT
	DISTINCT ON (MID_devdb.job_number) 
	MID_devdb.job_number,
	MID_devdb.job_type,
	MID_devdb.resid_flag,
	MID_devdb.nonres_flag,
	MID_devdb.job_inactive,
	MID_devdb.job_status,
	MID_devdb.complete_year,
	MID_devdb.complete_qrtr,
	MID_devdb.permit_year,
	MID_devdb.permit_qrtr,
	MID_devdb.classa_init,
	MID_devdb.classa_prop,
	MID_devdb.classa_net,
	HNY_devdb.classa_hnyaff,
	MID_devdb.hotel_init,
	MID_devdb.hotel_prop,
	MID_devdb.otherb_init,
	MID_devdb.otherb_prop,
	MID_devdb.co_latest_units as units_co,
	COALESCE(MID_devdb.geo_boro, MID_devdb.boro) as boro,
	COALESCE(MID_devdb.geo_bin, MID_devdb.bin) as bin,
	COALESCE(MID_devdb.geo_bbl, MID_devdb.bbl) as bbl,
	COALESCE(MID_devdb.geo_address_numbr, MID_devdb.address_numbr) as address_numbr,
	COALESCE(MID_devdb.geo_address_street, MID_devdb.address_street) as address_st,
	COALESCE(MID_devdb.geo_address_numbr, MID_devdb.address_numbr)
	||' '||COALESCE(MID_devdb.geo_address_street, MID_devdb.address_street) as address,
	MID_devdb.occ_initial,
	MID_devdb.occ_proposed,
	MID_devdb.bldg_class,
	MID_devdb.job_desc,
	MID_devdb.desc_other,
	MID_devdb.date_filed,
	MID_devdb.date_statusd,
	MID_devdb.date_statusp,
	MID_devdb.date_permittd,
	MID_devdb.date_statusr,
	MID_devdb.date_statusx,
	MID_devdb.date_lastupdt,
	MID_devdb.date_complete,
	MID_devdb.zoningdist1,
	MID_devdb.zoningdist2,
	MID_devdb.zoningdist3,
	MID_devdb.specialdist1,
	MID_devdb.specialdist2,
	MID_devdb.landmark,
	MID_devdb.zsf_init,
	MID_devdb.zsf_prop,
	MID_devdb.stories_init,
	MID_devdb.stories_prop,
	MID_devdb.height_init,
	MID_devdb.height_prop,
	MID_devdb.constructnsf,
	MID_devdb.enlargement,
	MID_devdb.enlargementsf,
	MID_devdb.costestimate,
	MID_devdb.loftboardcert,
	MID_devdb.edesignation,
	MID_devdb.curbcut,
	MID_devdb.tracthomes,
	MID_devdb.ownership,
	MID_devdb.owner_name,
	MID_devdb.owner_biznm,
	MID_devdb.owner_address,
	MID_devdb.owner_zipcode,
	MID_devdb.owner_phone,
	PLUTO_devdb.pluto_unitres,
	PLUTO_devdb.pluto_bldgsf,
	PLUTO_devdb.pluto_comsf,
	PLUTO_devdb.pluto_offcsf,
	PLUTO_devdb.pluto_retlsf,
	PLUTO_devdb.pluto_ressf,
	PLUTO_devdb.pluto_yrbuilt,
	PLUTO_devdb.pluto_yralt1,
	PLUTO_devdb.pluto_yralt2,
	PLUTO_devdb.pluto_histdst,
	PLUTO_devdb.pluto_landmk,
	PLUTO_devdb.pluto_bldgcls,
	PLUTO_devdb.pluto_landuse,
	PLUTO_devdb.pluto_owner,
	PLUTO_devdb.pluto_owntype,
	PLUTO_devdb.pluto_condo,
	PLUTO_devdb.pluto_bldgs,
	PLUTO_devdb.pluto_floors,
	PLUTO_devdb.pluto_version,
	MID_devdb.geo_censusblock2010 as cenblock2010,
	MID_devdb.bctcb2010,
	MID_devdb.bct2010,
	MID_devdb.geo_ntacode2010 as nta2010,
	MID_devdb.geo_ntaname2010 as ntaname2010,
	MID_devdb.geo_puma as puma2010,
	MID_devdb.geo_cd as comunitydist,
	MID_devdb.geo_council as councildist,
	MID_devdb.geo_schoolsubdist as schoolsubdist,
	MID_devdb.geo_csd as schoolcommnty,
	MID_devdb.geo_schoolelmntry as schoolelmntry,
	MID_devdb.geo_schoolmiddle as schoolmiddle,
	MID_devdb.geo_firecompany as firecompany,
	MID_devdb.geo_firebattalion as FireBattalion,
	MID_devdb.geo_firedivision as firedivision,
	MID_devdb.geo_policeprct as policeprecnct,
	--    depdrainarea,
	--    deppumpstatn,
	PLUTO_devdb.pluto_firm07,
	PLUTO_devdb.pluto_pfirm15,
	MID_devdb.latitude,
	MID_devdb.longitude,
	MID_devdb.datasource,
	MID_devdb.geomsource,
	CORR_lists.dcpeditfields,
	HNY_devdb.hny_id,
	HNY_devdb.hny_jobrelate,
	:'VERSION' as version
INTO FINAL_devdb
FROM MID_devdb 
    LEFT JOIN HNY_devdb ON MID_devdb.job_number = HNY_devdb.job_number
    LEFT JOIN PLUTO_devdb ON MID_devdb.job_number = PLUTO_devdb.job_number
    LEFT JOIN (
        SELECT job_number, STRING_AGG(field, '/') as dcpeditfields
        FROM corrections_applied GROUP BY job_number
    ) CORR_lists ON MID_devdb.job_number = CORR_lists.job_number
;


DROP TABLE IF EXISTS manual_corrections;
WITH 
applied AS (
	SELECT
		a.job_number,
		a.field,
		a.old_value,
		a.new_value,
		a.reason,
		a.edited_date,
		a.editor,
		b.pre_corr_value,
		1 as corr_applied,
		1 as job_in_devdb
	FROM _manual_corrections a
	LEFT JOIN corrections_applied b
	ON a.job_number = b.job_number
	AND a.field = b.field
	AND a.old_value = b.old_value
	AND a.new_value = b.new_value
),
not_applied AS (
	SELECT
		a.job_number,
		a.field,
		a.old_value,
		a.new_value,
		a.reason,
		a.edited_date,
		a.editor,
		b.pre_corr_value,
		0 as corr_applied,
		(a.job_number IN (SELECT job_number FROM FINAL_devdb))::integer as job_in_devdb
	FROM _manual_corrections a
	LEFT JOIN corrections_not_applied b
	ON a.job_number = b.job_number
	AND a.field = b.field
	AND a.old_value = b.old_value
	AND a.new_value = b.new_value
)
SELECT
	NOW() as build_dt,
	a.*
INTO manual_corrections
FROM 
	(SELECT * FROM applied
	UNION 
	SELECT * FROM not_applied) a;
