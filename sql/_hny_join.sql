/*
DESCRIPTION:
    Merging devdb with hny. This requires the following procedure.
    Following _hny.sql query with HNY_matches were completed

    5) Assign flags to indicate one_hny_to_many_dev and/or one_dev_to_many_hny.
        a) handle one devdb to many hny records cases by concatenating those hny_ids and combines units/fields 
        to create a single record
        b) Rest of the cases (one hny to many devdb, many hny to many devdb) are handled by including every 
        possible joins with devdb records for each hny recor.

    6) Combine the two tables to create HNY_devdb

INPUTS: 
    HNY_matches (
        hny_id,
        job_number,
        match_priority,
        job_type,
        resid_flag,
        all_counted_units,
		total_units
    )

    hpd_hny_units_by_building (
        ogc_fid,
        project_id,
        project_name,
        number,
        street,
        reporting_construction_type,
        all_counted_units,
        total_units,
        one_dev_to_many_hny integer,
        one_hny_to_many_dev integer,
        project_start_date text,
        project_completion_date text,
        extremely_low_income_units numeric,
        very_low_income_units numeric,
        low_income_units numeric,
        moderate_income_units numeric,
        middle_income_units numeric,
        other_income_units numeric,
        studio_units numeric,
        "1_br_units" numeric,
        "2_br_units" numeric,
        "3_br_units" numeric,
        "4_br_units" numeric,
        "5_br_units" numeric,
        "6_br+_units" numeric,
        unknown_br_units numeric,
        counted_rental_units numeric,
        counted_homeownership_units numeric
    )

    hny_geocode_results (
        * uid,
        geo_bin,
        geo_bbl,
        geo_latitude,
        geo_longitude

    )

    
OUTPUTS: 
    HNY_devdb(
        hny_id text,
        job_number text,
        classa_hnyaff text,
        all_hny_units text,
        one_dev_to_many_hny integer,
        one_hny_to_many_dev integer,
        project_start_date text,
        project_completion_date text,
        extremely_low_income_units numeric,
        very_low_income_units numeric,
        low_income_units numeric,
        moderate_income_units numeric,
        middle_income_units numeric,
        other_income_units numeric,
        studio_units numeric,
        "1_br_units" numeric,
        "2_br_units" numeric,
        "3_br_units" numeric,
        "4_br_units" numeric,
        "5_br_units" numeric,
        "6_br+_units" numeric,
        unknown_br_units numeric,
        counted_rental_units numeric,
        counted_homeownership_units numeric
    )
*/

-- 5) Identify relationships between devdb records and hny records
DROP TABLE IF EXISTS HNY_devdb;
WITH 
	-- Find cases of many-hny-to-one-devdb, after having filtered to highest priority
	many_developments AS (SELECT hny_id
				FROM HNY_matches
				GROUP BY hny_id
                HAVING COUNT(*)>1),
				
	-- Find cases of many-devdb-to-one-hny, after having filtered to highest priority
	many_hny AS (SELECT a.job_number
				FROM HNY_matches a
				GROUP BY a.job_number
                HAVING COUNT(*)>1),	

	-- Add relationship flags, where '1' in both flags means a many-to-many relationship
    RELATEFLAGS_hny_matches AS
    (SELECT m.*,
		(CASE 
			WHEN hny_id IN (SELECT DISTINCT hny_id FROM many_developments) THEN 1
			ELSE 0 
		END) AS one_hny_to_many_dev,
		(CASE 
			WHEN job_number IN (SELECT DISTINCT job_number FROM many_hny) THEN 1
			ELSE 0
		END) AS one_dev_to_many_hny
    FROM HNY_matches m), --- maybe this is where the hny_geo could be brought in again

-- 5) ASSIGN MATCHES   
	-- a) For one dev to many hny, group by job_number and sum unit fields
	one_to_many AS (SELECT 
        string_agg(r.hny_id, ', ') AS hny_id,
        r.job_number, 
        SUM(COALESCE(r.all_counted_units::int, '0'))::text AS classa_hnyaff,
        SUM(COALESCE(r.total_units::int, '0'))::text AS all_hny_units,
        r.one_dev_to_many_hny,
        r.one_hny_to_many_dev,
        MIN(h.project_start_date) as project_start_date,
        MIN(h.project_completion_date) as project_completion_date,
        SUM(h.extremely_low_income_units::NUMERIC) as extremely_low_income_units,
        SUM(h.very_low_income_units::NUMERIC) as very_low_income_units,
        SUM(h.low_income_units::NUMERIC) as low_income_units,
        SUM(h.moderate_income_units::NUMERIC) as moderate_income_units,
        SUM(h.middle_income_units::NUMERIC) as middle_income_units,
        SUM(h.other_income_units::NUMERIC) as other_income_units,
        SUM(h.studio_units::NUMERIC) as studio_units,
        SUM(h."1_br_units"::NUMERIC) as "1_br_units",
        SUM(h."2_br_units"::NUMERIC) as "2_br_units",
        SUM(h."3_br_units"::NUMERIC) as "3_br_units",
        SUM(h."4_br_units"::NUMERIC) as "4_br_units",
        SUM(h."5_br_units"::NUMERIC) as "5_br_units",
        SUM(h."6_br+_units"::NUMERIC) as "6_br+_units",
        SUM(h.unknown_br_units::NUMERIC) as unknown_br_units,
        SUM(h.counted_rental_units::NUMERIC) as counted_rental_units,
        SUM(h.counted_homeownership_units::NUMERIC) as counted_homeownership_units
                        
        FROM RELATEFLAGS_hny_matches r
        LEFT JOIN HNY_geo h
        ON r.hny_id = h.hny_id
        WHERE r.one_dev_to_many_hny = 1 AND r.one_hny_to_many_dev = 0
        GROUP BY r.job_number, r.one_dev_to_many_hny, r.one_hny_to_many_dev), 
    -- b) this would include all other hny devdb relationship 
    other_relations AS (
            SELECT
                r.hny_id,
                r.job_number::TEXT as job_number,
                r.all_counted_units::text as classa_hnyaff,
                r.total_units::text as all_hny_units,
                r.one_dev_to_many_hny,
                r.one_hny_to_many_dev,
                h.project_start_date as project_start_date,
                h.project_completion_date as project_completion_date,
                h.extremely_low_income_units::NUMERIC as extremely_low_income_units,
                h.very_low_income_units::NUMERIC as very_low_income_units,
                h.low_income_units::NUMERIC as low_income_units,
                h.moderate_income_units::NUMERIC as moderate_income_units,
                h.middle_income_units::NUMERIC as middle_income_units,
                h.other_income_units::NUMERIC as other_income_units,
                h.studio_units::NUMERIC as studio_units,
                h."1_br_units"::NUMERIC as "1_br_units",
                h."2_br_units"::NUMERIC as "2_br_units",
                h."3_br_units"::NUMERIC as "3_br_units",
                h."4_br_units"::NUMERIC as "4_br_units",
                h."5_br_units"::NUMERIC as "5_br_units",
                h."6_br+_units"::NUMERIC as "6_br+_units",
                h.unknown_br_units::NUMERIC as unknown_br_units,
                h.counted_rental_units::NUMERIC as counted_rental_units,
                h.counted_homeownership_units::NUMERIC as counted_homeownership_units
            FROM RELATEFLAGS_hny_matches r
            LEFT JOIN HNY_geo h
            ON r.hny_id = h.hny_id
            WHERE NOT (r.one_dev_to_many_hny = 1 AND r.one_hny_to_many_dev = 0))
        
-- 6) Insert into HNY_devdb  
SELECT 
*
INTO 
HNY_devdb
FROM (SELECT * FROM one_to_many
    UNION
    SELECT * FROM other_relations) all_hny;

