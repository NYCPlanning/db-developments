-- create a tempory table from the housing table where development happened
-- with the desired fields in the desired order named appropriately
-- copy that table to the output folder and drop the table
-- update the cutoff dates
	-- Cutoff date for 1st quarter would be March 31st.
	-- Cutoff date for 2nd quarter would be June 30th.
	-- Cutoff date for 3rd quarter is Sept 30th.
	-- Cutoff date for 4th quarter is Dec 31st.
-- DROP TABLE IF EXISTS dev_export;
-- SELECT * INTO dev_export FROM developments_hny LIMIT 10;


/*
-- output devdb for QAQC purposes
DROP TABLE IF EXISTS dev_export;
SELECT * INTO dev_export
FROM developments_hny
WHERE ((co_earliest_effectivedate::date >= '2010-01-01' AND co_earliest_effectivedate::date <=  :'CAPTURE_DATE')
OR (co_earliest_effectivedate IS NULL AND status_q::date >= '2010-01-01' AND status_q::date <=  :'CAPTURE_DATE')
OR (co_earliest_effectivedate IS NULL AND status_q IS NULL AND status_a::date >= '2010-01-01' AND status_a::date <=  :'CAPTURE_DATE'))
AND x_outlier IS DISTINCT FROM 'true';
*/

-- Reorder and rename developments_hny table
DROP TABLE IF EXISTS developments_export;
CREATE TABLE developments_export (
	Job_Number text,
	Job_Type text,
	Job_Status text,
	Job_Inactive text,
	Occ_Category text,
	Complete_Year text,
	-- Complete_Qrtr text,
	Permit_Year text,
	-- Permit_Qrtr text,
	Units_Initial text,
	Units_Prop text,
	Units_Net text,
	Units_Complet text,
	Units_Incompl text,
	Units_HNYAff text,
	Boro text,
	BBL text,
	BIN text,
	Address_Numbr text,
	Address_St text,
	Address text,
	Date_Filed text,
	Date_StatusD text,
	Date_StatusP text,
	Date_Permittd text,
	Date_StatusR text,
	Date_StatusX text,
	Date_LastUpdt text,
	Date_Complete text,
	Occ_Initial text,
	Occ_Proposed text,
	ZoningDist1 text,
	ZoningDist2 text,
	ZoningDist3 text,
	SpecialDist1 text,
	SpecialDist2 text,
	Landmark text,
	CityOwned text,
	Owner_Type text,
	Owner_NonProf text,
	Owner_FirstNm text,
	Owner_LastNm text,
	Owner_BizNm text,
	Owner_Address text,
	Owner_ZipCode text,
	Owner_Phone text,
	Stories_Init text,
	Stories_Prop text,
	Height_Init text,
	Height_Prop text,
	ZoningSF_Init text,
	ZoningSF_Prop text,
	ConstructnSF text,
	Enlrg_Horiz text,
	Enlrg_Vert text,
	EnlargementSF text,
	CostEstimate text,
	MixedUseBldg text,
	LoftBoardCert text,
	eDesignation text,
	CurbCut text,
	TractHomes text,
	HNY_ID text,
	HNY_JobRelate text,
	Job_Desc text,
	PLUTO_UnitRes text,
	PLUTO_BldgSF text,
	PLUTO_ComSF text,
	PLUTO_OffcSF text,
	PLUTO_RetlSF text,
	PLUTO_ResSF text,
	PLUTO_YrBuilt text,
	PLUTO_YrAlt1 text,
	PLUTO_YrAlt2 text,
	PLUTO_BldgCls text,
	PLUTO_LandUse text,
	PLUTO_Owner text,
	PLUTO_OwnType text,
	PLUTO_Condo text,
	PLUTO_Bldgs text,
	PLUTO_Floors text,
	PLUTO_Version text,
	-- CenBlock2010 text,
	BCTCB2010 text,
	BCT2010 text,
	NTA2010 text,
	-- PUMA2010 text,
	ComunityDist text,
	CouncilDist text,
	SchoolSubDist text,
	-- SchoolCommnty text,
	-- SchoolElmntry text,
	-- SchoolMiddle text,
	-- FireCompany text,
	-- FireBattalion text,
	-- FireDivision text,
	PolicePrecnct text,
	-- DEPDrainArea text,
	-- DEPPumpStatn text,
	-- NYMTC_TAZ2012 text,
	PLUTO_FIRM07 text,
	PLUTO_PFIRM15 text,
	Latitude text,
	Longitude text,
	geom geometry(Geometry,4326),
	GeomSource text,
	DCPEdited text,
	-- DCPEditReason text,
	Version text,
	x_outlier text
);

INSERT INTO developments_export (
	Job_Number,
	Job_Type,
	job_status,
	Job_Inactive,
	Occ_Category,
	Complete_Year,
	-- Complete_Qrtr,
	Permit_Year,
	-- Permit_Qrtr,
	Units_Initial,
	Units_Prop,
	Units_Net,
	Units_Complet,
	Units_Incompl,
	Units_HNYAff,
	Boro,
	BBL,
	BIN,
	Address_Numbr,
	Address_St,
	Address,
	Date_Filed,
	Date_StatusD,
	Date_StatusP,
	Date_Permittd,
	Date_StatusR,
	Date_StatusX,
	Date_LastUpdt,
	Date_Complete,
	Occ_Initial,
	Occ_Proposed,
	ZoningDist1,
	ZoningDist2,
	ZoningDist3,
	SpecialDist1,
	SpecialDist2,
	Landmark,
	CityOwned,
	Owner_Type,
	Owner_NonProf,
	Owner_FirstNm,
	Owner_LastNm,
	Owner_BizNm,
	Owner_Address,
	Owner_ZipCode,
	Owner_Phone,
	Stories_Init,
	Stories_Prop,
	Height_Init,
	Height_Prop,
	ZoningSF_Init,
	ZoningSF_Prop,
	ConstructnSF,
	Enlrg_Horiz,
	Enlrg_Vert,
	EnlargementSF,
	CostEstimate,
	MixedUseBldg,
	LoftBoardCert,
	eDesignation,
	CurbCut,
	TractHomes,
	HNY_ID,
	HNY_JobRelate,
	Job_Desc,
	PLUTO_UnitRes,
	PLUTO_BldgSF,
	PLUTO_ComSF,
	PLUTO_OffcSF,
	PLUTO_RetlSF,
	PLUTO_ResSF,
	PLUTO_YrBuilt,
	PLUTO_YrAlt1,
	PLUTO_YrAlt2,
	PLUTO_BldgCls,
	PLUTO_LandUse,
	PLUTO_Owner,
	PLUTO_OwnType,
	PLUTO_Condo,
	PLUTO_Bldgs,
	PLUTO_Floors,
	PLUTO_Version,
	-- CenBlock2010,
	BCTCB2010,
	BCT2010,
	NTA2010,
	-- PUMA2010,
	ComunityDist,
	CouncilDist,
	SchoolSubDist,
	-- SchoolCommnty,
	-- SchoolElmntry,
	-- SchoolMiddle,
	-- FireCompany,
	-- FireBattalion,
	-- FireDivision,
	PolicePrecnct,
	-- DEPDrainArea,
	-- DEPPumpStatn,
	-- NYMTC_TAZ2012,
	PLUTO_FIRM07,
	PLUTO_PFIRM15,
	Latitude,
	Longitude,
	geom,
	GeomSource,
	DCPEdited,
	-- DCPEditReason,
	Version,
	x_outlier
	)
SELECT
	job_number,
	job_type,
	status,
	x_inactive,
	occ_category,
	year_complete, -- Complete_Year,
	-- NULL, -- Complete_Qrtr,
	year_permit, -- Permit_Year,
	-- NULL, -- Permit_Qrtr,
	units_init,
	units_prop,
	units_net,
	units_complete,
	units_incomplete,
	affordable_units,
	boro,
	geo_bbl,
	geo_bin,
	address_house,
	address_street,
	address,
	status_a,
	status_d,
	status_p,
	status_q,
	status_r,
	status_x,
	status_date,
	co_earliest_effectivedate,
	occ_init,
	occ_prop,
	ZoningDist1,
	ZoningDist2,
	ZoningDist3,
	SpecialDist1,
	SpecialDist2,
	Landmark,
	CityOwned,
	Owner_Type,
	Owner_NonProf,
	Owner_FirstNm,
	Owner_LastNm,
	Owner_BizNm,
	Owner_Address,
	Owner_ZipCode,
	Owner_Phone,
	stories_init,
	stories_prop,
	Height_Init,
	Height_Prop,
	zoningsft_init,
	zoningsft_prop,
	ConstructnSF,
	Enlrg_Horiz,
	Enlrg_Vert,
	EnlargementSF,
	CostEstimate,
	x_mixeduse,
	LoftBoardCert,
	eDesignation,
	CurbCut,
	TractHomes,
	hny_id,
	hny_to_job_relat,
	job_description,
	unitsres,
	bldgarea,
	comarea,
	officearea,
	retailarea,
	resarea,
	yearbuilt,
	yearalter1,
	yearalter2,
	bldgclass,
	landuse,
	ownername,
	ownertype,
	condono,
	numbldgs,
	numfloors,
	pluto_version,
	-- NULL, -- CenBlock2010, FIPS Census Block 2010
	geo_boro||geo_censustract2010||geo_censusblock2010,
	geo_boro||geo_censustract2010,
	geo_ntacode2010,
	-- NULL, -- PUMA2010,
	geo_cd,
	geo_council,
	geo_csd,
	-- NULL, -- SchoolCommnty,
	-- NULL, -- SchoolElmntry,
	-- NULL, -- SchoolMiddle,
	-- NULL, -- FireCompany,
	-- NULL, -- FireBattalion,
	-- NULL, -- FireDivision,
	geo_policeprct,-- PolicePrecnct,
	-- NULL, -- DEPDrainArea,
	-- NULL, -- DEPPumpStatn,
	-- NULL, -- NYMTC_TAZ2012,
	firm07_flag,
	pfirm15_flag,
	latitude,
	longitude,
	geom,
	x_geomsource,
	x_dcpedited,
	-- x_reason,
	:'VERSION',
	x_outlier
FROM developments_hny;

-- Force occ-category to be residential for all housing DB cases prior to export
UPDATE developments_export
SET Occ_Category = (
	CASE 
		WHEN (/* Include corrections that result in non-null units */
				(Job_Number IN (
    				SELECT DISTINCT b.job_number
    				FROM housing_input_research b
    				WHERE b.new_value IS NOT NULL 
						AND b.field IN ('units_initial',
									'units_init',
									'units_Init', 
									'units_prop', 
									'Hotel_init', 
									'Hotel_prop', 
									'OtherB_init', 
									'OtherB_prop')
						))
				/*Identify residential by keyword*/
				OR ((Occ_Category = 'Residential' 
					OR Occ_Proposed LIKE '%Residential%' 
					OR Occ_Initial LIKE '%Residential%' 
					OR Occ_Proposed LIKE '%Assisted%Living%' 
					OR Occ_Initial LIKE '%Assisted%Living%')
				/* Exclude garage & miscellaneous from residential */
				AND (Occ_Initial IS DISTINCT FROM 'Garage/Miscellaneous' 
					OR Occ_Proposed IS DISTINCT FROM 'Garage/Miscellaneous')
				/* Exclude new HNY hotels or dorms not in mixed-use */
				AND Job_Number NOT IN (
					SELECT DISTINCT Job_Number
					FROM developments_hny
					WHERE Job_Type = 'New Building' 
						AND Occ_Proposed = 'Hotel or Dormitory' 
						AND MixedUseBldg IS NULL))
				) THEN 'Residential'
		/* Make sure everything else is other */
		ELSE 'Other'
	END);


-- overwrite non-residential units to zero
UPDATE developments_export
SET Units_Initial = '0',
	Units_Prop = '0',
	Units_Net = '0'
WHERE developments_export.Occ_Category = 'Other';


-- output the devDB
DROP TABLE IF EXISTS devdb_export;
SELECT * INTO devdb_export
FROM developments_export
WHERE ((Date_Complete::date >= '2010-01-01' 
		AND Date_Complete::date <=  :'CAPTURE_DATE')
	OR (Date_Complete IS NULL 
		AND Date_Permittd::date >= '2010-01-01' 
		AND Date_Permittd::date <=  :'CAPTURE_DATE')
	OR (Date_Complete IS NULL 
		AND Date_Permittd IS NULL 
		AND Date_Filed::date >= '2010-01-01' 
		AND Date_Filed::date <=  :'CAPTURE_DATE'))
AND x_outlier IS DISTINCT FROM 'true';

-- output the housingDB
DROP TABLE IF EXISTS housing_export;
SELECT * INTO housing_export
FROM developments_export
WHERE ((Date_Complete::date >= '2010-01-01' 
		AND Date_Complete::date <=  :'CAPTURE_DATE')
	OR (Date_Complete IS NULL 
		AND Date_Permittd::date >= '2010-01-01' 
		AND Date_Permittd::date <=  :'CAPTURE_DATE')
	OR (Date_Complete IS NULL 
		AND Date_Permittd IS NULL 
		AND Date_Filed::date >= '2010-01-01' 
		AND Date_Filed::date <=  :'CAPTURE_DATE'))
AND Occ_Category = 'Residential'
AND x_outlier IS DISTINCT FROM 'true';

-- drop outlier column from final output
ALTER TABLE devdb_export
DROP COLUMN x_outlier;
ALTER TABLE housing_export
DROP COLUMN x_outlier;