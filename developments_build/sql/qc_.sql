-- 1.1 sum stats for job_type
DROP TABLE IF EXISTS dev_qc_jobtypestats;
CREATE TABLE dev_qc_jobtypestats AS (
	WITH newcount as (
	SELECT a.job_type, COUNT(a.*) as countnew, SUM(a.units_net::numeric) as unitsnetnew
	FROM dev_export a
	GROUP BY a.job_type 
	ORDER BY a.job_type),
	precount as (
	SELECT a.job_type, COUNT(a.*) as countprev, SUM(a.units_net::numeric) as unitsnetprev
	FROM old_devdb a
	GROUP BY a.job_type 
	ORDER BY a.job_type)
SELECT a.job_type, countnew, countprev, countnew - b.countprev as countdiff, unitsnetnew, unitsnetprev, unitsnetnew - unitsnetprev as unitsnetdiff
FROM newcount a, precount b
WHERE a.job_type=b.job_type);

-- 1.2 general counts of output
DROP TABLE IF EXISTS dev_qc_countsstats;
CREATE TABLE dev_qc_countsstats AS (
SELECT 'sum of units_net' AS stat, SUM(units_net::numeric) as count
FROM dev_export a
UNION
SELECT 'sum of units_prop' AS stat, SUM(units_prop::numeric) as count
FROM dev_export a
UNION
SELECT 'sum of units_complete' AS stat, SUM(units_complete::numeric) as count
FROM dev_export a
UNION
SELECT 'number of alterations with +/- 100 units' AS stat, COUNT(*) as count
FROM dev_export a
WHERE job_type = 'Alteration' AND (units_net::numeric >= 100 OR units_net::numeric <= 100)
UNION
SELECT 'number of inactive records' AS stat, COUNT(*) as count
FROM dev_export a
WHERE x_inactive = 'Inactive'
UNION
SELECT 'number of mixused records' AS stat, COUNT(*) as count
FROM dev_export a
WHERE x_mixeduse = 'Mixed Use'
);
-- UNION
-- SELECT 'number of hotel/residential records' AS stat, COUNT(*) as count
-- FROM housing_export a
-- WHERE job_type = 'Alteration' AND (units_net::numeric >= 100 OR units_net::numeric <= 100)

-- 1.3 group by co_year_earliest of units_complete
DROP TABLE IF EXISTS dev_qc_units_complete_stats;
CREATE TABLE dev_qc_units_complete_stats AS (
SELECT EXTRACT(YEAR FROM co_earliest_effectivedate::DATE) AS co_year_earliest,
SUM(units_complete::NUMERIC) AS sum_units_complete
FROM dev_export
GROUP by EXTRACT(YEAR FROM co_earliest_effectivedate::DATE)
ORDER BY co_year_earliest DESC
);
--1.4 geocoding stats
DROP TABLE IF EXISTS dev_qc_geocodedstats;
CREATE TABLE dev_qc_geocodedstats AS (
    SELECT x_geomsource, COUNT(*)
    FROM dev_export
    GROUP BY x_geomsource
    ORDER BY x_geomsource)
;
--2. Next, check all fields, for completeness and content, format etc. Using Python

--3. Check qc_outliers.csv for outliers. Leave correct records intact,
---add corrections to DCP attributes, and add false records to removals list.

-- 4.Check housing database for alterations where Units_prop is blank.
---See if proposed unit count is in job description.
---If so, add record to DCP attributes with data for unit_prop.
---attach housing_input_dcpattributes.csv url
DROP TABLE IF EXISTS dev_qc_a1_units_prop;
CREATE TABLE dev_qc_a1_units_prop AS (
SELECT job_number, job_type, units_init, units_prop, job_description
FROM dev_export
WHERE job_type = 'Alteration'
AND units_prop IS NULL
);

-- 5.Check housing database for alterations where units_init is blank.
---See if initial unit count is in job description.
---If u_prop is relatively large (10 units or more), research number of units_init.
---Add record to DCP attributes and add value for unit_init.
---The difference is calculated automatically.
DROP TABLE IF EXISTS dev_qc_a1_units_init;
CREATE TABLE dev_qc_a1_units_init AS (
SELECT job_number, job_type, units_init, units_prop, job_description
FROM dev_export
WHERE job_type = 'Alteration'
AND units_init IS NULL
);

-- 6.Query job description for words: hotel and resid% (NB or A1),
---exclude where DCP_edit=TRUE. Check unit values.
---If hotel rooms appear as residential units,
---add records to DCP attributes with correct input data:
---overwriting number of residential units proposed and net year over year counts.
DROP TABLE IF EXISTS dev_qc_hotel_resid_nb_a1;
CREATE TABLE dev_qc_hotel_resid_nb_a1 AS (
SELECT job_number, job_type, units_init, units_prop, units_complete, job_description
FROM dev_export
WHERE (job_type = 'Alteration' OR job_type = 'New Building')
AND job_description ~* 'hotel'
AND job_description ~* 'resid'
AND x_dcpedited IS NULL
);

-- 7.Check all Alterations from residential to hotel (only A1) and from hotel to residential.
---Check individually and add necessary changes to DCP attributes.
DROP TABLE IF EXISTS dev_qc_hotel_resid_a1;
CREATE TABLE dev_qc_hotel_resid_a1 AS (
SELECT job_number, units_init, units_prop,
occ_init, occ_prop, job_description
FROM dev_export
WHERE job_type = 'Alteration'
AND (occ_prop ~* 'resid'
AND occ_init ~* 'hotel')
OR (occ_prop ~* 'hotel'
AND occ_init ~* 'resid')
);

-- 8.Research large non-residenttial buildings with large unit counts to confirm that they are non-residential
DROP TABLE IF EXISTS dev_qc_nonresid_large;
CREATE TABLE dev_qc_nonresid_large AS (
SELECT * FROM dev_export
WHERE occ_category != 'Residential'
AND units_net::NUMERIC >= 3
);

--9. Check all DCP Attributes records with values entered for unit_change_20XX. -->python
---Confirm that the information entered in the first half of the year
---is still correct for the second half of the year.
---I believe we actually decided not to update the YOY tables for half year values anymore,
---which would make this issue a moot point.
--->this can be realized by conducting qaqc in recipe database


--10. Check qc_potentialdups.csv. Focus on potential duplicates of four or more units (plus or minus 4 or more).
--Look at units_net, job status, and job descriptions, are they identical or very similiar? If not, not duplicates.
--If yes, investigate further. When identifying a duplicate pair, to identify the actual duplicate (the job NOT being pursued),
--check status_dates and select the job "to remove". Removal happens by adding job to dcp_attributes and editing x_inactive as 'Inactive'.
-- reporting possible duplicate records where the records have the same job_type and address and units_net > 0
-- order by address then job type then units descending
DROP TABLE IF EXISTS dev_qc_potentialdups;
CREATE TABLE dev_qc_potentialdups AS (
	WITH housing_export_rownum AS (
	SELECT a.*, ROW_NUMBER()
    	OVER (PARTITION BY address, job_type
      	ORDER BY address, job_type, units_net::numeric DESC) AS row_number
  		FROM dev_export a
  		WHERE units_net::numeric > 0
		AND x_inactive <> 'Inactive'
  		AND status <> 'Withdrawn'
  		AND occ_prop <> 'Garage/Miscellaneous')
	SELECT * 
	FROM housing_export_rownum 
	WHERE address||job_type IN (SELECT address||job_type 
	FROM housing_export_rownum WHERE row_number = 2));
--11. Check: qc_occupancyresearch.csv.
---Occupancy classification "Assembly - Other" where occ_category: Other and units_net NOT 0.
---Research individually and re-classify into existing category based on the field:
---DCP_Classification_New in housing_input_lookup_occupancy.csv by adding record to DCP attributes.
-- outputting records for research based on occupancy categories
DROP TABLE IF EXISTS dev_qc_occupancyresearch;
CREATE TABLE dev_qc_occupancyresearch AS (
    SELECT * FROM dev_export
    WHERE (occ_init = 'Assembly: Other'
    OR occ_prop = 'Assembly: Other'
    OR (occ_prop = 'Assembly: Other'
        AND occ_category = 'Other')
    OR job_number IN (
        SELECT DISTINCT jobnumber
        FROM dob_jobapplications
        WHERE occ_init = 'H-2'
        OR occ_prop = 'H-2'))
    AND (units_net::NUMERIC != 0 AND units_net IS NOT NULL));

--12. Check quality of HNY match. qc_HNY. The important thing is that units_prop and address match HNY.
---Sometimes the relationship between DOB records and HNY records is not 1 to 1.
-->hny mismatch table should be attached
DROP TABLE IF EXISTS dev_qc_hny_mismatch;
CREATE TABLE dev_qc_hny_mismatch AS (
SELECT a.address AS dob_address, b.number||' '||b.street AS hny_address,
a.units_prop, b.total_units
FROM developments_hny a
JOIN hny b
ON a.hny_id = b.hny_id
WHERE a.address != b.number||' '||b.street
OR a.units_prop != b.total_units
);

--13. Check geocoding: are there records that are not within tax lots? Records in water?
--->geometry on a map
-- sum stats for x_geomsource
DROP TABLE IF EXISTS dev_qc_clipped;
DROP TABLE IF EXISTS dev_qc_water;
DROP TABLE IF EXISTS dev_qc_taxlot;
DROP TABLE IF EXISTS dev_qc_unclipped;
CREATE TABLE dev_qc_clipped AS (
SELECT a.job_number||a.status_date AS id
FROM dev_export a, dcp_ntaboundaries b
WHERE ST_Within(a.geom,b.geom)
);
CREATE TABLE dev_qc_water AS (
SELECT 'in water' as type, a.* 
FROM dev_export a
LEFT JOIN dev_qc_clipped b
ON job_number||status_date = b.id
WHERE b.id IS NULL
AND geom IS NOT NULL);
DROP TABLE IF EXISTS dev_qc_clipped;
CREATE TABLE dev_qc_clipped AS (
SELECT a.job_number||a.status_date AS id
FROM dev_export a, dcp_mappluto b
WHERE ST_Within(a.geom,b.geom)
);
CREATE TABLE dev_qc_taxlot AS (
SELECT 'outside taxlot' as type, a.*
FROM dev_export a
LEFT JOIN dev_qc_clipped b
ON job_number||status_date = b.id
WHERE b.id IS NULL
AND geom IS NOT NULL 
AND job_number||status_date NOT IN (
SELECT job_number||status_date FROM dev_qc_water)
);
CREATE TABLE dev_qc_unclipped AS (
	SELECT * FROM dev_qc_water
	UNION
	SELECT * FROM dev_qc_taxlot);
DROP TABLE IF EXISTS dev_qc_clipped;
DROP TABLE IF EXISTS dev_qc_water;
DROP TABLE IF EXISTS dev_qc_taxlot;

--14. Eliminate DOB test jobs (BIS TEST) - query job description field. If any left, add to housing_input_removals.csv
-->housing_input_reasearch.sql

--15. Check jobs where the number of units in the CO exceeds the number of units that were permitted.
--This is especially important for the year over year table.
DROP TABLE IF EXISTS dev_qc_cofos_units;
CREATE TABLE dev_qc_cofos_units AS (
WITH yearly_units AS(
    SELECT job_number, EXTRACT(YEAR FROM effectivedate::DATE) AS year, max(units) AS co_units
    FROM developments_co
    GROUP BY job_number, year
    ORDER BY job_number, year
)
SELECT a.*, b.units_prop
FROM yearly_units a
INNER JOIN dev_export b
ON a.job_number = b.job_number
WHERE a.co_units::NUMERIC > b.units_prop::NUMERIC
AND a.job_number||year NOT IN (
SELECT job_number||RIGHT(field, 4) FROM housing_input_research
WHERE field ~* 'unit_change'
    )
);

-- A.1 Report jobs that are complete where the PLUTO BBL matches the BBL
--- but the PLUTO number of units <> the proposed number of units
DROP TABLE IF EXISTS dev_qc_mismatch_complete_units;
CREATE TABLE dev_qc_mismatch_complete_units AS (
	SELECT a.bbl, a.status, a.units_prop::NUMERIC, b.unitstotal AS pluto_units,
	a.units_prop::NUMERIC - b.unitstotal AS diff FROM dev_export a
	INNER JOIN dcp_mappluto b
	ON a.bbl = b.bbl::TEXT
	WHERE (a.status = 'Complete' 
		OR a.status = 'Partial complete'
		OR a.status = 'Complete (demolition)')
	AND a.units_prop::NUMERIC != b.unitstotal
	ORDER BY diff DESC
	);

-- A.2 Report jobs that are not complete where the PLUTO BBL matches the BBL
-- but the PLUTO number of units <> the initial number of units
DROP TABLE IF EXISTS dev_qc_mismatch_incomplete_units;
CREATE TABLE dev_qc_mismatch_incomplete_units AS (
	SELECT a.bbl, a.status, a.units_init::NUMERIC, b.unitstotal AS pluto_units,
	a.units_init::NUMERIC - b.unitstotal AS diff FROM dev_export a
	INNER JOIN dcp_mappluto b
	ON a.bbl = b.bbl::TEXT
	WHERE (a.status != 'Complete'
		AND a.status != 'Partial complete' 
		AND a.status != 'Complete (demolition)'
		AND a.status != 'Withdrawn')
	AND a.units_init::NUMERIC != b.unitstotal
	ORDER BY diff DESC
	);

-- B. output table of potential SROs
-- Query for keywords in description: Class B, SRO, Furnished room
-- Or where there is a big change in the number of units for an Alteration
DROP TABLE IF EXISTS dev_qc_sro;
CREATE TABLE dev_qc_sro AS (
	SELECT job_number, job_description, units_prop::NUMERIC, units_init::NUMERIC,
	units_prop::NUMERIC - units_init::NUMERIC AS diff, 'key word' AS reason FROM dev_export
	WHERE job_description ~* 'CLASS B'
	OR job_description ~* 'SRO'
	OR job_description ~* 'FURNISHED ROOM'
	UNION
	SELECT job_number, job_description, units_prop::NUMERIC, units_init::NUMERIC,
	units_prop::NUMERIC - units_init::NUMERIC AS diff, 'big change in units' AS reason
	FROM dev_export
	WHERE job_type = 'Alteration'
	AND ABS(units_prop::NUMERIC - units_init::NUMERIC) > 5
	ORDER BY diff DESC
	);

-- C. Compare results from Geosupport and Spatial Join
-- D. summary table at census tract level
-- E. output of records where DOB Job number is not unique in the final developments database
DROP TABLE IF EXISTS dev_qc_jobnum;
CREATE TABLE dev_qc_jobnum AS (
	SELECT * FROM developments_hny
	WHERE job_number IN (
		SELECT job_number
		FROM developments_hny
		GROUP BY job_number
		HAVING COUNT(*)>1
	)
);