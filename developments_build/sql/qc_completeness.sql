drop table if exists qc_completeness;

select * into qc_completeness from (
    select
        'total' as field,
        count(*) as counts
        FROM devdb_export a
    union
   select
        'job_number' as field,
        sum(case when a.job_number is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'job_type' as field,
        sum(case when a.job_type is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'job_status' as field,
        sum(case when a.job_status is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'job_inactive' as field,
        sum(case when a.job_inactive is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'occ_category' as field,
        sum(case when a.occ_category is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'complete_year' as field,
        sum(case when a.complete_year is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'permit_year' as field,
        sum(case when a.permit_year is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'units_initial' as field,
        sum(case when a.units_initial is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'units_prop' as field,
        sum(case when a.units_prop is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'units_net' as field,
        sum(case when a.units_net is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'units_complet' as field,
        sum(case when a.units_complet is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'units_incompl' as field,
        sum(case when a.units_incompl is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'units_hnyaff' as field,
        sum(case when a.units_hnyaff is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'boro' as field,
        sum(case when a.boro is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'bbl' as field,
        sum(case when a.bbl is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'bin' as field,
        sum(case when a.bin is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'address_numbr' as field,
        sum(case when a.address_numbr is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'address_st' as field,
        sum(case when a.address_st is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'address' as field,
        sum(case when a.address is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'date_filed' as field,
        sum(case when a.date_filed is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'date_statusd' as field,
        sum(case when a.date_statusd is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'date_statusp' as field,
        sum(case when a.date_statusp is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'date_permittd' as field,
        sum(case when a.date_permittd is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'date_statusr' as field,
        sum(case when a.date_statusr is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'date_statusx' as field,
        sum(case when a.date_statusx is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'date_lastupdt' as field,
        sum(case when a.date_lastupdt is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'date_complete' as field,
        sum(case when a.date_complete is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'occ_initial' as field,
        sum(case when a.occ_initial is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'occ_proposed' as field,
        sum(case when a.occ_proposed is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'zoningdist1' as field,
        sum(case when a.zoningdist1 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'zoningdist2' as field,
        sum(case when a.zoningdist2 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'zoningdist3' as field,
        sum(case when a.zoningdist3 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'specialdist1' as field,
        sum(case when a.specialdist1 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'specialdist2' as field,
        sum(case when a.specialdist2 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'landmark' as field,
        sum(case when a.landmark is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'cityowned' as field,
        sum(case when a.cityowned is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'owner_type' as field,
        sum(case when a.owner_type is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'owner_nonprof' as field,
        sum(case when a.owner_nonprof is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'owner_firstnm' as field,
        sum(case when a.owner_firstnm is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'owner_lastnm' as field,
        sum(case when a.owner_lastnm is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'owner_biznm' as field,
        sum(case when a.owner_biznm is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'owner_address' as field,
        sum(case when a.owner_address is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'owner_zipcode' as field,
        sum(case when a.owner_zipcode is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'owner_phone' as field,
        sum(case when a.owner_phone is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'stories_init' as field,
        sum(case when a.stories_init is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'stories_prop' as field,
        sum(case when a.stories_prop is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'height_init' as field,
        sum(case when a.height_init is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'height_prop' as field,
        sum(case when a.height_prop is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'zoningsf_init' as field,
        sum(case when a.zoningsf_init is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'zoningsf_prop' as field,
        sum(case when a.zoningsf_prop is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'constructnsf' as field,
        sum(case when a.constructnsf is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'enlrg_horiz' as field,
        sum(case when a.enlrg_horiz is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'enlrg_vert' as field,
        sum(case when a.enlrg_vert is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'enlargementsf' as field,
        sum(case when a.enlargementsf is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'costestimate' as field,
        sum(case when a.costestimate is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'mixedusebldg' as field,
        sum(case when a.mixedusebldg is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'loftboardcert' as field,
        sum(case when a.loftboardcert is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'edesignation' as field,
        sum(case when a.edesignation is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'curbcut' as field,
        sum(case when a.curbcut is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'tracthomes' as field,
        sum(case when a.tracthomes is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'hny_id' as field,
        sum(case when a.hny_id is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'hny_jobrelate' as field,
        sum(case when a.hny_jobrelate is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'job_desc' as field,
        sum(case when a.job_desc is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_unitres' as field,
        sum(case when a.pluto_unitres is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_bldgsf' as field,
        sum(case when a.pluto_bldgsf is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_comsf' as field,
        sum(case when a.pluto_comsf is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_offcsf' as field,
        sum(case when a.pluto_offcsf is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_retlsf' as field,
        sum(case when a.pluto_retlsf is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_ressf' as field,
        sum(case when a.pluto_ressf is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_yrbuilt' as field,
        sum(case when a.pluto_yrbuilt is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_yralt1' as field,
        sum(case when a.pluto_yralt1 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_yralt2' as field,
        sum(case when a.pluto_yralt2 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_bldgcls' as field,
        sum(case when a.pluto_bldgcls is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_landuse' as field,
        sum(case when a.pluto_landuse is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_owner' as field,
        sum(case when a.pluto_owner is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_owntype' as field,
        sum(case when a.pluto_owntype is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_condo' as field,
        sum(case when a.pluto_condo is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_bldgs' as field,
        sum(case when a.pluto_bldgs is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_floors' as field,
        sum(case when a.pluto_floors is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_version' as field,
        sum(case when a.pluto_version is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'bctcb2010' as field,
        sum(case when a.bctcb2010 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'bct2010' as field,
        sum(case when a.bct2010 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'nta2010' as field,
        sum(case when a.nta2010 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'comunitydist' as field,
        sum(case when a.comunitydist is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'councildist' as field,
        sum(case when a.councildist is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'schoolsubdist' as field,
        sum(case when a.schoolsubdist is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'policeprecnct' as field,
        sum(case when a.policeprecnct is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_firm07' as field,
        sum(case when a.pluto_firm07 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'pluto_pfirm15' as field,
        sum(case when a.pluto_pfirm15 is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'latitude' as field,
        sum(case when a.latitude is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'longitude' as field,
        sum(case when a.longitude is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'geom' as field,
        sum(case when a.geom is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'geomsource' as field,
        sum(case when a.geomsource is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'dcpedited' as field,
        sum(case when a.dcpedited is null then 1 else 0 end) as counts
        FROM devdb_export a
    union
    select
        'version' as field,
        sum(case when a.version is null then 1 else 0 end) as counts
        FROM devdb_export a
) a;