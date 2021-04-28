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
        job_status character varying,
        complete_year text,
        complete_qrtr text,
        x_inactive text,
        x_dcpedited text,
        dcpeditfields text
    )


OUTPUTS: 
    MID_STATUS_devdb (
        * job_number,
        classa_init int,
        classa_prop int,
        classa_net int,
        hotel_init int,
        hotel_prop int,
        otherb_init int,
        otherb_prop int,
        job_status character varying,
        complete_year text,
        complete_qrtr text,
        job_inactive text,
        dcpeditfields text
        ...
    )
*/
DROP TABLE IF EXISTS MID_devdb;
WITH
JOIN_STATUS_devdb as (
    SELECT
        a.*,
        (CASE
            WHEN a.resid_flag IS NULL THEN NULL
            ELSE a._classa_init
        END) as classa_init,
        (CASE
            WHEN a.resid_flag IS NULL THEN NULL
            ELSE a._classa_prop
        END) as classa_prop,
        (CASE
            WHEN a.resid_flag IS NULL THEN NULL
            ELSE a._classa_net
        END) as classa_net,
        (CASE
            WHEN a.resid_flag IS NULL THEN NULL
            ELSE a._hotel_init
        END) as hotel_init,
        (CASE
            WHEN a.resid_flag IS NULL THEN NULL
            ELSE a._hotel_prop
        END) as hotel_prop,
        (CASE
            WHEN a.resid_flag IS NULL THEN NULL
            ELSE a._otherb_init
        END) as otherb_init,
        (CASE
            WHEN a.resid_flag IS NULL THEN NULL
            ELSE a._otherb_prop
        END) as otherb_prop,
        b.job_status,
        b.job_inactive
    FROM _MID_devdb a
    LEFT JOIN STATUS_devdb b
    ON a.job_number = b.job_number
)
SELECT *
INTO MID_devdb
FROM JOIN_STATUS_devdb;
