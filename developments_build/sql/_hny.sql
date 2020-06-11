/*
DESCRIPTION:
    Merging devdb with hny. This requires the following procedure.

    1) Merge hny data from hpd_hny_units_by_building with hny_geocode_results,
        and filter to new construction that isn't confidential. Create a unique ID 
        using a hash.
    2) Find matches between geocoded devdb and hny using three different methods:
        a) JOIN KEY: geo_bin, geo_bbl
        b) JOIN KEY: geo_bbl
        c) SPATIAL JOIN: geom
        For all three, hny.units_total must be within 5 units dev_db.units_prop.
        The devdb record cannot be a demolition.
    3) Combine unique matched found by the three methods into the table all_matches, 
        assigning priority by match method and development type.
        In cases where a hny record matches with either multiple developments records
        or with a single developments record in multiple ways, matches get assigned 
        based on this hierarchy:
            1: Residential new building matched on both BIN & BBL
            2: Residential new building matched only on BBL
            3: Residential new building matched spatially
            4: Alteration or non-residential non-demolition matched on both BIN & BBL
            5: Alteration or non-residential non-demolition matched only on BBL
            6: Alteration or non-residential non-demolition matched spatially
    4) Create HNY_matches:
        For each hny_id, find the highest-priority match(es). This will either be the best 
        match, or multiple matches at the same priority-level. Depending on the number of 
        highest-priority matches, assign flags to indicate one_hny_to_many_dev
        and/or one_dev_to_many_hny.
    5) Resolve the one-to-many, many-to-one, and many-to-many cases in HNY_matches
        in order to create HNY_lookup
        a) One-to-one matches get assigned directly
        b) For one devdb to many hny, sum the total_units and all_counted_units for all hny rows
        c) For multiple devdb to one hny, assign units to the one with the lowest job_number.
            Remaining matches are retained, but get NULLs in the unit fields.
    6) Merge  devdb with HNY_lookup
        JOIN KEY: job_number
    7) Apply corrections

INPUTS: 
    hpd_hny_units_by_building (
        ogc_fid,
        project_id,
        project_name,
        number,
        street,
        reporting_construction_type,
        all_counted_units,
        total_units
    )

    hny_geocode_results (
        * uid,
        geo_bin,
        geo_bbl,
        geo_latitude,
        geo_longitude

    )

    MID_devdb (
        * job_number,
        status
        occ_init,
        occ_prop,
        occ_category,
        units_prop,
        geo_bin,
        geo_bbl,
        ...
    )

    
OUTPUTS: 
    HNY_matches (
        hny_id,
        job_number,
        match_priority,
        job_type,
        occ_category,
        all_counted_units,
		total_units
    ),

    HNY_devdb (
        * job_number,
        hny_id,
        affortable_units,
		all_hny_units,
        ...
    )

IN PREVIOUS VERSION: 
    hny_create.sql
    hny_id.sql
    hny_job_lookup.sql
    hny_res_nb_match.sql
    hny_a1_nonres_match.sql
    hny_manual_geomerge.sql
    hny_manual_match.sql
    hny_job_relate.sql
    hny_many_to_many.sql
    hny_dob_match.sql
    dob_hny_id.sql
    dob_affordable_units.sql
*/

DROP TABLE IF EXISTS HNY_matches;
-- 1) Merge with geocoding results and create a unique ID
WITH hny AS (
        SELECT project_id||'/'||COALESCE(building_id, '') as hny_id,
                a.*, 
                b.geo_bbl, 
                b.geo_bin, 
                b.geo_latitude, 
                b.geo_longitude,
                (CASE WHEN b.geo_longitude IS NOT NULL 
                        AND b.geo_latitude IS NOT NULL
                    THEN ST_SetSRID(ST_MakePoint(b.geo_longitude::NUMERIC, 
                                    b.geo_latitude::NUMERIC),4326)
                    ELSE NULL
                END) AS geom
        FROM hpd_hny_units_by_building a
        JOIN hny_geocode_results b
        ON a.ogc_fid::text = b.uid
        WHERE a.reporting_construction_type = 'New Construction'
        AND a.project_name <> 'CONFIDENTIAL'),

-- 2) Find matches using the three different methods

    -- a) Find all matches on both BIN and BBL
    bin_bbl_match AS(
        SELECT 
            h.hny_id,
            d.job_number,
            d.job_type,
            d.occ_category,
            h.total_units,
            h.all_counted_units,
            'BINandBBL' AS match_method
        FROM hny h
        JOIN MID_devdb d
        ON h.geo_bbl = d.geo_bbl 
            AND h.geo_bin = d.geo_bin
            AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
        AND h.geo_bin IS NOT NULL
        AND h.geo_bbl IS NOT NULL
        AND d.status <> '9. Withdrawn'
        AND d.job_type <> 'Demolition'
    ),

    -- b) Find all matches on BBL, but where BIN does not match
    bbl_match AS (
        SELECT 
            h.hny_id,
            d.job_number,
            d.job_type,
            d.occ_category,
            h.total_units,
            h.all_counted_units,
            'BBLONLY' AS match_method
        FROM hny h
        JOIN MID_devdb d
        ON h.geo_bbl = d.geo_bbl 
            AND (h.geo_bin <> d.geo_bin OR h.geo_bin IS NULL OR d.geo_bin IS NULL)
            AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
        AND h.geo_bbl IS NOT NULL
        AND d.status <> '9. Withdrawn'
        AND d.job_type <> 'Demolition'
    ),

    -- c) Find spatial matches where BIN and BBL don't match
    spatial_match AS (
        SELECT 
            h.hny_id,
            d.job_number,
            d.job_type,
            d.occ_category,
            h.total_units,
            h.all_counted_units,
            'Spatial' AS match_method
        FROM hny h
        JOIN MID_devdb d
        ON ST_DWithin(h.geom::geography, d.geom::geography, 5)
            AND (h.geo_bbl <> d.geo_bbl OR h.geo_bbl IS NULL OR d.geo_bbl IS NULL)
            AND (h.geo_bin <> d.geo_bin OR h.geo_bin IS NULL OR d.geo_bin IS NULL)
            AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
        AND h.geom IS NOT NULL AND d.geom IS NOT NULL
        AND d.status <> '9. Withdrawn'
        AND d.job_type <> 'Demolition'
    ),

-- 3) Combine matches into a table of all_matches. Assign match priorities.
    all_matches AS (
        SELECT a.*,
        (CASE 
            WHEN (job_type = 'New Building'
                AND occ_category = 'Residential')
            THEN (CASE
                WHEN match_method = 'BINandBBL' THEN 1
                WHEN match_method = 'BBLONLY' THEN 2
                WHEN match_method = 'Spatial' THEN 3
                END)
            WHEN (job_type = 'Alteration'
                OR occ_category <> 'Residential')
            THEN (CASE
                WHEN match_method = 'BINandBBL' THEN 4
                WHEN match_method = 'BBLONLY' THEN 5
                WHEN match_method = 'Spatial' THEN 6
                END)
        END
        ) AS match_priority
        FROM (SELECT * FROM bin_bbl_match 
		        UNION 
		        SELECT * FROM bbl_match 
		        UNION 
		        SELECT * FROM spatial_match) a), 
  
-- 4) Find the highest-priority match(es) and determine relationships
	-- First find highest priority match(es) for each hny_id
	best_matches_by_hny AS (SELECT t1.hny_id, t1.match_priority, 
							t2.job_number, t2.job_type, 
							t2.occ_category, t2.total_units,
                            t2.all_counted_units
					FROM (
					   SELECT hny_id, MIN(match_priority) AS match_priority
					   FROM all_matches
					   GROUP BY hny_id
					) AS t1 
					JOIN all_matches AS t2 
					ON t2.hny_id = t1.hny_id 
					AND t2.match_priority = t1.match_priority),

	-- Then find highest priority match(es) for each job_number			
	best_matches AS (SELECT t2.hny_id, t1.match_priority, 
							t1.job_number, t2.job_type, 
							t2.occ_category, t2.total_units,
                            t2.all_counted_units
					FROM (
					   SELECT job_number, MIN(match_priority) AS match_priority
					   FROM best_matches_by_hny
					   GROUP BY job_number
					) AS t1 
					JOIN best_matches_by_hny AS t2 
					ON t2.job_number = t1.job_number 
					AND t2.match_priority = t1.match_priority),

	-- Find cases of many-hny-to-one-devdb, after having filtered to highest priority
	many_developments AS (SELECT hny_id, count(*)
				FROM best_matches
				GROUP BY hny_id),
				
	-- Find cases of many-devdb-to-one-hny, after having filtered to highest priority
	many_hny AS (SELECT a.job_number, count(*)
				FROM best_matches a
				GROUP BY a.job_number)	

	/** Add relationship flags and create HNY_matches. 
        A '1' in both flags means a many-to-many relationship. **/
	SELECT bm.*,
		(CASE 
			WHEN hny_id IN (SELECT DISTINCT hny_id FROM many_developments
									WHERE count > 1) THEN 1
			ELSE 0 
		END) AS one_hny_to_many_dev,
		(CASE 
			WHEN job_number IN (SELECT DISTINCT job_number FROM many_hny
									WHERE count > 1) THEN 1
			ELSE 0
		END) AS one_dev_to_many_hny
    INTO HNY_matches
	FROM best_matches bm;

/* 
5) ASSIGN MATCHES   
*/
DROP TABLE IF EXISTS HNY_devdb;
WITH 
	-- a) Extract one-to-one matches
	one_to_one AS (SELECT job_number, 
							hny_id,
							job_type,
							occ_category,
							all_counted_units AS affordable_units,
							total_units AS all_hny_units,
                            one_dev_to_many_hny,
                            one_hny_to_many_dev
					FROM HNY_matches 
					WHERE one_dev_to_many_hny = 0
					AND one_hny_to_many_dev = 0),

	-- b) For one dev to many hny, group by job_number and sum unit fields
	one_to_many AS (SELECT job_number, 
							'Multiple' AS hny_id,
							job_type,
							occ_category,
							SUM(all_counted_units::int)::text AS affordable_units,
							SUM(total_units::int)::text AS all_hny_units,
                            one_dev_to_many_hny,
                            one_hny_to_many_dev
					FROM HNY_matches
					WHERE one_dev_to_many_hny = 1
					GROUP BY job_number, job_type, occ_category, one_dev_to_many_hny, one_hny_to_many_dev),

	-- c) For multiple dev to one hny, assign units to the one with the lowest job_number
	-- Find the minimum job_number per hny in HNY_matches
	min_job_number_per_hny AS 
        (SELECT MIN(job_number::INT)::text AS job_number, hny_id
            FROM HNY_matches
            WHERE one_hny_to_many_dev = 1
            GROUP BY hny_id),

	many_to_one AS 
        (SELECT a.job_number,
            /** hny_id has to be set to "Multiple" for many-to-many cases, 
                else it comes from HNY_matches **/
            (CASE WHEN one_hny_to_many_dev = 1 
                    AND one_dev_to_many_hny = 1 
                    THEN 'Multiple' 
                ELSE a.hny_id END) AS hny_id,
            a.job_type,
            a.occ_category,
            -- Only populate affordable_units for the minimum job_number per hny record
            (CASE WHEN a.job_number||a.hny_id IN (SELECT job_number||hny_id FROM min_job_number_per_hny) 
                    -- If this is a many-to-many match, get summed affordable_units from one_to_many
                    THEN CASE WHEN a.job_number IN (SELECT job_number FROM one_to_many)
                            THEN (SELECT affordable_units 
                                    FROM one_to_many b 
                                    WHERE a.job_number = b.job_number)
                            ELSE a.all_counted_units
                        END
                    ELSE NULL
            END) AS affordable_units,
            -- Only populate all_hny_units for the minimum job_number per hny record
            (CASE WHEN a.job_number||a.hny_id IN (SELECT job_number||hny_id FROM min_job_number_per_hny) 
                    -- If this is a many-to-many, get summed all_hny_units data from one_to_many
                    THEN CASE WHEN a.job_number IN (SELECT job_number FROM one_to_many)
                            THEN (SELECT all_hny_units 
                                    FROM one_to_many b 
                                    WHERE a.job_number = b.job_number)
                            ELSE a.total_units
                        END
                    ELSE NULL
            END) AS all_hny_units,
            one_dev_to_many_hny,
            one_hny_to_many_dev
        FROM HNY_matches a
        WHERE one_hny_to_many_dev = 1),

    -- Combine into a single look-up table					
	HNY_lookup AS(					
			SELECT * FROM one_to_one
			UNION
			SELECT * FROM one_to_many
                -- Many-to-many cases are further resolved in many_to_one table, so don't include
				WHERE job_number||hny_id NOT IN (SELECT job_number||hny_id FROM many_to_one)
			UNION
			SELECT * FROM many_to_one)

/* 
6) MERGE WITH devdb  
*/
SELECT a.*, 
        b.hny_id,
        b.affordable_units,
        b.all_hny_units,
        (CASE 
            WHEN one_dev_to_many_hny = 0 AND one_hny_to_many_dev = 0 THEN 'one-to-one'
            WHEN one_dev_to_many_hny = 0 AND one_hny_to_many_dev = 1 THEN 'one-to-many'
            WHEN one_dev_to_many_hny = 1 AND one_hny_to_many_dev = 0 THEN 'many-to-one'
            WHEN one_dev_to_many_hny = 1 AND one_hny_to_many_dev = 1 THEN 'many-to-many'
            ELSE NULL
        END) AS hny_jobrelate
INTO HNY_devdb
FROM MID_devdb a
JOIN HNY_lookup b
ON a.job_number = b.job_number;

/* 
7) CORRECTIONS
    hny_id
    affordable_units
    all_hny_units
    hny_jobrelate
*/

UPDATE HNY_devdb a
SET hny_id = b.new_value,
	x_dcpedited = 'Edited',
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'hny_id'
AND (a.hny_id=b.old_value 
    OR (a.hny_id IS NULL
        AND b.old_value IS NULL));

UPDATE HNY_devdb a
SET affordable_units = TRIM(b.new_value)::numeric,
	x_dcpedited = 'Edited',
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'affordable_units'
AND (a.affordable_units::numeric=b.old_value::numeric 
    OR (a.affordable_units IS NULL
        AND b.old_value IS NULL));

UPDATE HNY_devdb a
SET all_hny_units = TRIM(b.new_value)::numeric,
	x_dcpedited = 'Edited',
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'all_hny_units'
AND (a.all_hny_units::numeric=b.old_value::numeric 
    OR (a.all_hny_units IS NULL
        AND b.old_value IS NULL));

UPDATE HNY_devdb a
SET hny_jobrelate = b.new_value,
	x_dcpedited = 'Edited',
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'hny_jobrelate'
AND (a.hny_jobrelate=b.old_value 
    OR (a.hny_jobrelate IS NULL
        AND b.old_value IS NULL));
