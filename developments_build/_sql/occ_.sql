-- populate the occupancy code fields using the housing_input_lookup_occupancy lookup table
-- initial 
-- post 2008
UPDATE developments a
SET occ_init = b.dcpclassificationnew
FROM housing_input_lookup_occupancy b
WHERE a.occ_init = b.doboccupancycode2008
	AND (right(status_a,4))::numeric >= 2008;

-- pre 2008
UPDATE developments a
SET occ_init = b.dcpclassificationnew
FROM housing_input_lookup_occupancy b
WHERE a.occ_init = b.doboccupancycode1968
	AND (right(status_a,4))::numeric < 2008;

-- no date filter 2008
UPDATE developments a
SET occ_init = b.dcpclassificationnew
FROM housing_input_lookup_occupancy b
WHERE a.occ_init = b.doboccupancycode2008;

-- no date filter 1968
UPDATE developments a
SET occ_init = b.dcpclassificationnew
FROM housing_input_lookup_occupancy b
WHERE a.occ_init = b.doboccupancycode1968;

-- proposed 
-- post 2008
UPDATE developments a
SET occ_prop = b.dcpclassificationnew
FROM housing_input_lookup_occupancy b
WHERE a.occ_prop = b.doboccupancycode2008
	AND (right(status_a,4))::numeric >= 2008;

-- pre 2008
UPDATE developments a
SET occ_prop = b.dcpclassificationnew
FROM housing_input_lookup_occupancy b
WHERE a.occ_prop = b.doboccupancycode1968
	AND (right(status_a,4))::numeric < 2008;

-- no date filter 2008
UPDATE developments a
SET occ_prop = b.dcpclassificationnew
FROM housing_input_lookup_occupancy b
WHERE a.occ_prop = b.doboccupancycode2008;

-- no date filter 1968
UPDATE developments a
SET occ_prop = b.dcpclassificationnew
FROM housing_input_lookup_occupancy b
WHERE a.occ_prop = b.doboccupancycode1968;

-- mark records as Empty Lots
UPDATE developments
SET occ_init = 'Empty Lot'
WHERE job_type = 'New Building';

UPDATE developments
SET occ_prop = 'Empty Lot'
WHERE job_type = 'Demolition';

-- Set occ_init = 'Garage/Miscellaneous' AND occ_prop = 'Garage/Miscellaneous'
-- Where job_type is Demolition or Alteration
-- AND address contains REAR or where job_description contains GARAGE 
UPDATE developments
SET occ_init = 'Garage/Miscellaneous',
	occ_prop = 'Garage/Miscellaneous'
WHERE (job_type = 'Alteration'
	AND (upper(job_description) LIKE '%GARAGE%' OR upper(address) LIKE '%REAR%') 
	AND (units_net::numeric = 0 OR units_net::numeric IS NULL));

UPDATE developments
SET occ_init = 'Garage/Miscellaneous'
WHERE (job_type = 'Demolition' 
	AND (upper(job_description) LIKE '%GARAGE%' OR upper(address) LIKE '%REAR%')); 
-- Set occ_prop = 'Garage/Miscellaneous'
-- Where job_type = New Building
-- job_description contains '%GARAGE%' and does NOT contain any of the following: %Res%, %Dwell%, %house%,%home%, %apart%, %family%
UPDATE developments
SET occ_prop = 'Garage/Miscellaneous'
WHERE (job_type = 'New Building' 
	AND (upper(job_description) LIKE '%GARAGE%' 
		AND upper(job_description) NOT LIKE '%RES%'
		AND upper(job_description) NOT LIKE '%DWELL%'
		AND upper(job_description) NOT LIKE '%HOUSE%'
		AND upper(job_description) NOT LIKE '%HOME%'
		AND upper(job_description) NOT LIKE '%APART%'
		AND upper(job_description) NOT LIKE '%FAMILY%'));

-- When there are multiple new building jobs that share the same address and net units
-- if 1 does not mention garage, change occ_prop to garage for records where job decription contains garage
WITH nongaragejobs AS (
	SELECT address, job_type, units_prop, job_description
	FROM developments
	WHERE upper(job_description) NOT LIKE '%GARAGE%'
	AND job_type = 'New Building'
	AND occ_prop IS DISTINCT FROM 'Garage/Miscellaneous')
UPDATE developments a 
SET occ_prop = 'Garage/Miscellaneous'
FROM nongaragejobs b
WHERE a.address = b.address
	AND a.job_type = b.job_type
	AND a.units_prop = b.units_prop
	AND upper(a.job_description) LIKE '%GARAGE%'
	AND occ_prop IS DISTINCT FROM 'Garage/Miscellaneous';

-- category
-- set to Residential where exiting or proposed occupany is Residential
UPDATE developments a
SET occ_category = 'Residential'
WHERE upper(occ_init) LIKE '%RESIDENTIAL%' OR upper(occ_prop) LIKE '%RESIDENTIAL%'
OR upper(occ_init) LIKE '%ASSISTED%LIVING%' OR upper(occ_prop) LIKE '%ASSISTED%LIVING%'
AND a.occ_category IS NULL;

-- otherwise set to other
UPDATE developments
SET occ_category = 'Other'
WHERE occ_category IS NULL;