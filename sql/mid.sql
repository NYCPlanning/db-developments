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
        job_inactive character varying
    )


OUTPUTS: 
    MID_devdb (
        * job_number,
        job_status character varying,
        complete_year text,
        complete_qrtr text,
        job_inactive character varying,
        ...
    )
*/
DROP TABLE IF EXISTS MID_devdb CASCADE;
WITH
JOIN_STATUS_devdb as (
    SELECT
        a.*,
        b.job_status,
        b.job_inactive
    FROM _MID_devdb a
    LEFT JOIN STATUS_devdb b
    ON a.job_number = b.job_number
)
SELECT *
INTO MID_devdb
FROM JOIN_STATUS_devdb;
CREATE INDEX MID_devdb_raw_job_number_idx ON MID_devdb_raw(job_number);
