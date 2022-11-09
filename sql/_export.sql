-- EXPORT DevDB
DROP TABLE IF EXISTS EXPORT_devdb;

SELECT
    * INTO EXPORT_devdb
FROM
    FINAL_devdb
WHERE (Date_Complete::date <= :'CAPTURE_DATE'
    OR (Date_Complete IS NULL
        AND Date_Permittd::date <= :'CAPTURE_DATE')
    OR (Date_Complete IS NULL
        AND Date_Permittd IS NULL
        AND Date_Filed::date <= :'CAPTURE_DATE'));

-- EXPORT HousingDB
DROP TABLE IF EXISTS EXPORT_housing;

SELECT
    * INTO EXPORT_housing
FROM
    EXPORT_devdb
WHERE
    resid_flag = 'Residential';

-- Switch to 10 char fieldnames
DROP TABLE IF EXISTS SHP_devdb;

SELECT
    Job_Number AS "Job_Number",
    Job_Type AS "Job_Type",
    Resid_Flag AS "ResidFlag",
    Nonres_Flag AS "NonresFlag",
    Job_Inactive AS "Job_Inactv",
    Job_Status AS "Job_Status",
    Complete_Year AS "CompltYear",
    Complete_Qrtr AS "CompltQrtr",
    Permit_Year AS "PermitYear",
    Permit_Qrtr AS "PermitQrtr",
    ClassA_Init AS "ClassAInit",
    ClassA_Prop AS "ClassAProp",
    ClassA_Net AS "ClassANet",
    ClassA_HNYAff::numeric AS "ClassA_HNY",
    Hotel_Init AS "HotelInit",
    Hotel_Prop AS "HotelProp",
    OtherB_Init AS "OtherBInit",
    OtherB_Prop AS "OtherBProp",
    units_co AS "Units_CO",
    Boro AS "Boro",
    BIN AS "BIN",
    BBL AS "BBL",
    Address_Numbr AS "AddressNum",
    Address_St AS "AddressSt",
    Address AS "Address",
    Occ_Initial AS "Occ_Init",
    Occ_Proposed AS "Occ_Prop",
    Bldg_Class AS "Bldg_Class",
    Job_Desc AS "Job_Desc",
    Desc_Other AS "Desc_Other",
    Date_Filed AS "DateFiled",
    Date_StatusD AS "DateStatsD",
    Date_StatusP AS "DateStatsP",
    Date_Permittd AS "DatePermit",
    Date_StatusR AS "DateStatsR",
    Date_StatusX AS "DateStatsX",
    Date_LastUpdt AS "DateLstUpd",
    Date_Complete AS "DateComplt",
    ZoningDist1 AS "ZoningDst1",
    ZoningDist2 AS "ZoningDst2",
    ZoningDist3 AS "ZoningDst3",
    SpecialDist1 AS "SpeclDst1",
    SpecialDist2 AS "SpeclDst2",
    Landmark AS "Landmark",
    ZSF_Init AS "ZSF_Init",
    ZSF_Prop AS "ZSF_Prop",
    ZoningUG_init AS "ZoningUG_init",
    ZoningUG_prop AS "ZoningUG_prop",
    Stories_Init AS "FloorsInit",
    Stories_Prop AS "FloorsProp",
    Height_Init AS "HeightInit",
    Height_Prop AS "HeightProp",
    ConstructnSF AS "CnstrctnSF",
    Enlargement AS "Enlargemnt",
    EnlargementSF AS "EnlrgSF",
    CostEstimate AS "CostEst",
    LoftBoardCert AS "LoftBoard",
    eDesignation AS "eDesigntn",
    CurbCut AS "CurbCut",
    TractHomes AS "TractHomes",
    Ownership AS "Ownership",
    owner_name AS "OwnrName",
    Owner_Address AS "OwnrAddr",
    Owner_ZipCode AS "OwnrZip",
    Owner_Phone AS "OwnrPhone",
    PLUTO_UnitRes AS "PL_UnitRes",
    PLUTO_BldgSF AS "PL_BldgSF",
    PLUTO_ComSF AS "PL_ComSF",
    PLUTO_OffcSF AS "PL_OffcSF",
    PLUTO_RetlSF AS "PL_RetlSF",
    PLUTO_ResSF AS "PL_ResSF",
    PLUTO_YrBuilt AS "PL_YrBuilt",
    PLUTO_YrAlt1 AS "PL_YrAlt1",
    PLUTO_YrAlt2 AS "PL_YrAlt2",
    PLUTO_Histdst AS "PL_Histdst",
    PLUTO_Landmk AS "PL_Landmk",
    PLUTO_BldgCls AS "PL_BldgCls",
    PLUTO_LandUse AS "PL_LandUse",
    PLUTO_Owner AS "PL_Owner",
    PLUTO_OwnType AS "PL_OwnType",
    PLUTO_Condo AS "PL_Condo",
    PLUTO_Bldgs AS "PL_Bldgs",
    PLUTO_Floors AS "PL_Floors",
    PLUTO_Version AS "PL_Version",
    CenBlock2010 AS "CenBlock10",
    CenTract2010 AS "CenTract10",
    BCTCB2010 AS "BCTCB2010",
    BCT2010 AS "BCT2010",
    NTA2010 AS "NTA2010",
    NTAName2010 AS "NTAName10",
    CenBlock2020 AS "CenBlock20",
    CenTract2020 AS "CenTract20",
    BCTCB2020 AS "BCTCB2020",
    BCT2020 AS "BCT2020",
    NTA2020 AS "NTA2020",
    NTAName2020 AS "NTAName20",
    CDTA2020 AS "CDTA2020",
    ComunityDist AS "CommntyDst",
    CouncilDist AS "CouncilDst",
    SchoolSubDist AS "SchSubDist",
    SchoolCommnty AS "SchCommnty",
    SchoolElmntry AS "SchElmntry",
    SchoolMiddle AS "SchMiddle",
    FireCompany AS "FireCmpany",
    FireBattalion AS "FireBattln",
    FireDivision AS "FireDivsn",
    PolicePrecnct AS "PolicePcnt",
    -- DEPDrainArea as "DEPDrainAr",
    -- DEPPumpStatn as "DEPPumpStn",
    PLUTO_FIRM07 AS "PL_FIRM07",
    PLUTO_PFIRM15 AS "PL_PFIRM15",
    Latitude AS "Latitude",
    Longitude AS "Longitude",
    DataSource AS "DataSource",
    GeomSource AS "GeomSource",
    DCPEditFields AS "DCPEdited",
    HNY_ID AS "HNY_ID",
    HNY_JobRelate AS "HNY_Relate",
    Version AS "Version",
    ST_SetSRID (ST_MakePoint (longitude, latitude), 4326) AS geom INTO SHP_devdb
FROM
    EXPORT_devdb;

DROP TABLE IF EXISTS SHP_housing;

SELECT
    * INTO SHP_housing
FROM
    SHP_devdb
WHERE
    "ResidFlag" = 'Residential';

