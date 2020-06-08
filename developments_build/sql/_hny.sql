/** Combine hny records with geocoding results from geocode_hny.py.
    Geocoding-derived BIN, BBL, and geometry are what we use
    to match a hny records with a developments record. In this step,
    we also create a hash unique ID and a geometry object from
    the coordinates.
    
    We will only look at hny records where the name indicates that 
    it is not confidential, and where the building is new construction **/

WITH hny AS (
        SELECT md5(CAST((a.project_id,
                       a.number,
                       a.street,
                       b.geo_bin,
                       b.geo_bbl) AS text)) as hny_id,
                a.*, b.geo_bbl, b.geo_bin, b.geo_latitude, b.geo_longitude,
                (CASE WHEN b.geo_longitude IS NOT NULL AND b.geo_latitude IS NOT NULL
                    THEN ST_SetSRID(ST_MakePoint(b.geo_longitude::NUMERIC, 
                                    b.geo_latitude::NUMERIC),4326)
                    ELSE NULL
                END) AS geom
        FROM hpd_hny_units_by_building a
        JOIN hny_geocode_results b
        ON a.ogc_fid::text = b.uid
        WHERE a.reporting_construction_type = 'New Construction'
        AND a.project_name <> 'CONFIDENTIAL'),
    -- Manual equivalent
    manual_hny AS (
        SELECT md5(CAST((a.project_id,
                       a.number,
                       a.street,
                       b.geo_bin,
                       b.geo_bbl) AS text)) as hny_id,
                a.*, b.geo_bbl, b.geo_bin, b.geo_latitude, b.geo_longitude
        FROM housing_input_hny_job_manual a
        JOIN hny_manual_geocode_results b
        ON a.ogc_fid::text = b.uid
    ),

/** Find matches between developments records and hny records 
    using three different methods. All matches have the constraint that
    the units_total of a hny record must be within 5 units of units_prop
    of the developments record. **/

    -- Find all matches on both BIN and BBL
    bin_bbl_match AS(
        SELECT 
            h.hny_id,
            d.job_number,
            d.job_type,
            d.occ_category,
            'BINandBBL' AS match_method
        FROM hny h
        JOIN developments_hny d
        ON h.geo_bbl = d.geo_bbl 
            AND h.geo_bin = d.geo_bin
            AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
        AND h.geo_bin IS NOT NULL
        AND h.geo_bbl IS NOT NULL
        AND d.status <> 'Withdrawn'
        AND d.job_type <> 'Demolition'
    ),

    -- Find all matches on BBL, but where BIN does not match
    bbl_match AS (
        SELECT 
            h.hny_id,
            d.job_number,
            d.job_type,
            d.occ_category,
            'BBLONLY' AS match_method
        FROM hny h
        JOIN developments_hny d
        ON h.geo_bbl = d.geo_bbl 
            AND (h.geo_bin <> d.geo_bin OR h.geo_bin IS NULL OR d.geo_bin IS NULL)
            AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
        AND h.geo_bbl IS NOT NULL
        AND d.status <> 'Withdrawn'
        AND d.job_type <> 'Demolition'
    ),

    -- Find spatial matches where BIN and BBL don't match
    spatial_match AS (
        SELECT 
            h.hny_id,
            d.job_number,
            d.job_type,
            d.occ_category,
            'Spatial' AS match_method
        FROM hny h
        JOIN developments_hny d
        ON ST_DWithin(h.geom::geography, d.geom::geography, 5)
            AND (h.geo_bbl <> d.geo_bbl OR h.geo_bbl IS NULL OR d.geo_bbl IS NULL)
            AND (h.geo_bin <> d.geo_bin OR h.geo_bin IS NULL OR d.geo_bin IS NULL)
            AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
        AND h.geom IS NOT NULL AND d.geom IS NOT NULL
        AND d.status <> 'Withdrawn'
        AND d.job_type <> 'Demolition'
    ),
    /** Combine the three methods of matching into a hny-developments lookup, 
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
         **/

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
  
	/** For each hny record, find the highest-priority match(es). 
    This will either be the best match, or multiple matches 
    at the same priority-level. **/
	best_matches AS (SELECT t1.hny_id, t1.match_priority, 
							t2.job_number, t2.job_type, 
							t2.occ_category
					FROM (
					   SELECT hny_id, MIN(match_priority) AS match_priority
					   FROM all_matches
					   GROUP BY hny_id
					) AS t1 
					JOIN all_matches AS t2 
					ON t2.hny_id = t1.hny_id 
					AND t2.match_priority = t1.match_priority),

	-- Find many-hny-to-one-developments
	many_developments AS (SELECT hny_id, count(*)
				FROM best_matches
				GROUP BY hny_id),
				
	-- Find many-developments-to-one-hny
	many_hny AS (SELECT job_number, count(*)
				FROM best_matches
				GROUP BY job_number)	

	-- Add relationship flags. Note that a 1 in both means many-to-many.
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
    INTO hny_developments_matches
	FROM best_matches bm;

-- Logic to assign matches

WITH 
	-- Find matches that are one-to-one
	one_to_one AS (SELECT job_number, 
							hny_id,
							job_type,
							occ_category,
							all_counted_units,
							total_units
					FROM hny_developments_matches 
					WHERE one_dev_to_many_hny = 0
					AND one_hny_to_many_dev = 0),
	-- For one dev to many hny, sum the units for all hny matches
	one_to_many AS (SELECT job_number, 
							'Multiple' AS hny_id,
							job_type,
							occ_category,
							SUM(all_counted_units::int)::text AS all_counted_units,
							SUM(total_units::int)::text AS total_units 
					FROM hny_developments_matches
					WHERE one_dev_to_many_hny = 1
					GROUP BY job_number, job_type, occ_category),
	-- For multiple dev to one hny, assign units to the one with the lowest job_number
	-- Begin by creating a table only containing data for the minimum job_number per hny
	min_job_number_per_hny AS (SELECT MIN(job_number::INT)::text AS job_number, hny_id
							 FROM hny_developments_matches
							 WHERE one_dev_to_many_hny = 0
							 AND one_hny_to_many_dev = 1
							 GROUP BY hny_id),
	many_to_one AS (SELECT a.job_number,
							-- hny_id has to be set to "Multiple" for many-to-many cases, else it comes from hny_developments_matches
							(CASE WHEN one_hny_to_many_dev = 1 
									AND one_dev_to_many_hny = 1 
									THEN 'Multiple' 
								ELSE a.hny_id END) AS hny_id,
							a.job_type,
							a.occ_category,
							-- Only populate all_counted_units for the minimum job_number per hny record
							(CASE WHEN a.job_number||a.hny_id IN (SELECT job_number||hny_id FROM min_job_number_per_hny) 
									-- If this is a many-to-many, need to get summed all_counted_units data from one_to_many
									THEN CASE WHEN a.job_number IN (SELECT job_number FROM one_to_many)
											THEN (SELECT all_counted_units 
													FROM one_to_many b 
													WHERE a.job_number = b.job_number)
											ELSE a.all_counted_units
										END
									ELSE NULL
							END) AS all_counted_units,
							-- Only populate total_units for the minimum job_number per hny record
							(CASE WHEN a.job_number||a.hny_id IN (SELECT job_number||hny_id FROM min_job_number_per_hny) 
									-- If this is a many-to-many, need to get summed total_units data from one_to_many
									THEN CASE WHEN a.job_number IN (SELECT job_number FROM one_to_many)
											THEN (SELECT all_counted_units 
													FROM one_to_many b 
													WHERE a.job_number = b.job_number)
											ELSE a.total_units
										END
									ELSE NULL
							END) AS total_units
					FROM hny_developments_matches a
					WHERE one_hny_to_many_dev = 1),
    -- Combine into a single look-up table to append hny columns to developments database					
	dev_hny_lookup AS(					
			SELECT * FROM one_to_one
			UNION
			SELECT * FROM one_to_many
                -- Many-to-many cases are also in many_to_one table
				WHERE job_number||hny_id NOT IN (SELECT job_number||hny_id FROM many_to_one)
			UNION
			SELECT * FROM many_to_one)

SELECT * FROM dev_hny_lookup;

