/*
DESCRIPTION:
    Merging INIT_devdb with (STATUS_Q_devdb, CO_devdb, UNITS_devdb, OCC_devdb)
    JOIN KEY: job_number

INPUTS: 

    INIT_devdb (
        * job_number,
        ...
    )

    STATUS_Q_devdb (
        * job_number,
        status_q,
        year_complete
    )

    CO_devdb (
        * job_number,
        year_complete,
        co_earliest_effectivedate,
        co_latest_certtype, 
        co_latest_units
    )

    UNITS_devdb (
        * job_number,
        units_init,
        units_prop,
        hotel_init,
	    hotel_prop,
	    otherb_init,
	    otherb_prop,
        units_net
    )

    OCC_devdb (
        * job_number,
        occ_init,
        occ_prop,
        occ_category
    )

OUTPUTS: 
    MID_devdb (
        * job_number,
        status_q,
        year_complete,
        co_earliest_effectivedate,
        co_latest_certtype, 
        co_latest_units,
        units_init,
        units_prop,
        hotel_init,
	    hotel_prop,
	    otherb_init,
	    otherb_prop,
        units_net,
        units_complete_diff,
        occ_init,
        occ_prop,
        occ_category
        ...
    )
*/
DROP TABLE IF EXISTS MID_devdb;
WITH
JOIN_status_q as (
    SELECT
        a.*,
        b.status_q,
        b.year_permit,
        b.quarter_permit,
        b.year_complete as year_complete_A1_NB,
        b.quarter_complete as quarter_complete_A1_NB
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
            THEN b.year_complete 
        ELSE a.year_complete_A1_NB END) as year_complete,
        (CASE WHEN a.job_type = 'Demolition'
            THEN b.quarter_complete 
        ELSE a.quarter_complete_A1_NB END) as quarter_complete,
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
        b.units_net,
        b.units_init,
        b.units_prop,
        b.hotel_init,
	    b.hotel_prop,
	    b.otherb_init,
	    b.otherb_prop,
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
