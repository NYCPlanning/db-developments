DROP TABLE IF EXISTS MID_devdb;
WITH
JOIN_status_q as (
    SELECT
        a.*,
        b.status_q,
        b.year_complete as year_complete_A1_NB
    FROM INIT_devdb a
    LEFT JOIN STATUS_Q_devdb b
    ON a.job_number = b.job_number
), 
JOIN_co as (
    SELECT 
        a.*,
        -- For new buildings and alterations, this is defined as the year of the 
        -- first certificate of occupancy issuance. For demolitions, this is the 
        -- year that the demolition was permitted
        (CASE WHEN a.job_type = 'Demolition'
        THEN b.year_complete ELSE a.year_complete_A1_NB
        END) as year_complete,
        b.co_earliest_effectivedate,
        b.co_latest_certtype, 
        b.co_latest_units::numeric
    FROM JOIN_status_q a
    LEFT JOIN CO_devdb b
    ON a.job_number = b.job_number
),
JOIN_units as (
    SELECT
        a.*,
        b.units_init,
        b.units_prop,
        b.units_net,
        (CASE
            WHEN b.units_net != 0 
                THEN a.co_latest_units/b.units_net
            ELSE NULL
        END) as units_complete_pct,
        b.units_net - a.co_latest_units as units_complete_diff
    FROM JOIN_co a
    LEFT JOIN UNITS_devdb b
    ON a.job_number = b.job_number
),
JOIN_occ as (
    SELECT
        a.*,
        b.occ_init,
        b.occ_prop,
        b.occ_category
    FROM JOIN_units a
    LEFT JOIN OCC_devdb b
    ON a.job_number = b.job_number
) 
SELECT *
INTO MID_devdb
FROM JOIN_occ;
