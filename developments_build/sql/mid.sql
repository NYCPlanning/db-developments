/*
DESCRIPTION:
    Merging _MID_devdb with (STATUS_devdb) to create MID_devdb
    JOIN KEY: job_number

INPUTS: 

    _MID_devdb (
        * job_number,
        ...
    )

    STATUS_devdb (
        * job_number,
        status character varying,
        complete_year text,
        complete_qrtr text,
        units_complete numeric,
        units_incomplete numeric,
        x_inactive text,
        x_dcpedited text,
        x_reason text
    )


OUTPUTS: 
    MID_STATUS_devdb (
        * job_number,
        status character varying,
        complete_year text,
        complete_qrtr text,
        units_complete numeric,
        units_incomplete numeric,
        x_inactive text,
        x_dcpedited text,
        x_reason text
        ...
    )
*/
DROP TABLE IF EXISTS MID_devdb;
WITH
JOIN_STATUS_devdb as (
    SELECT
        a.*,
        b.status,
        b.complete_year,
        b.complete_qrtr,
        b.units_complete,
        b.units_incomplete,
        b.x_inactive
    FROM _MID_devdb a
    LEFT JOIN STATUS_devdb b
    ON a.job_number = b.job_number
)
SELECT *
INTO MID_devdb
FROM JOIN_STATUS_devdb;
