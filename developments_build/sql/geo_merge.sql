UPDATE developments a 
SET geo_bbl = b.bbl, 
    geo_bin = b.bin, 
    geo_address_house = b.hnum, 
    geo_address_street = b.sname, 
    geo_zipcode = b.zipcode,
    geo_boro = b.bcode, 
    geo_cd = b.cd,
    geo_council = b.council,
    geo_ntacode2010 = b.nta, 
    geo_censusblock2010 = b.cblock, 
    geo_censustract2010 = b.ctract,
    geo_csd = b.csd,
    geo_policeprct = b.policeprct,
    latitude = b.lat, 
    longitude = b.lon
FROM development_tmp b
WHERE a.job_number||a.status_date = b.uid;

-- DROP TABLE development_tmp;