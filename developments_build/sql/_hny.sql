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
  
	-- For each hny record, find the highest-priority match(es)
	best_matches AS (SELECT t1.hny_id, t1.match_priority, 
							t2.job_number, t2.job_type, 
							t2.occ_category
					FROM (
					   SELECT hny_id, MIN(match_priority) AS match_priority
					   FROM all_matches
					   GROUP BY hny_id
					) AS t1 
					RIGHT JOIN all_matches AS t2 
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

	-- Add relationship flags
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
	FROM best_matches bm;

-- Logic to assign matches

-- Apply manual research