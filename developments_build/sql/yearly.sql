/*
DESCRIPTION:
    Creates an unaggregated table as input for the spatial aggregates.
    Includes completions split by year. 
    
INPUTS:
    FINAL_devdb (
        * job_number,
        job_type,
        date_permittd,
        date_complete,
        date_lastupdt,
        classa_complt,
        boro,
        bctcb2010,
        bct2010,
        nta2010,
        ntaname2010,
        puma2010
    )


OUTPUTS:
    YEARLY_devdb (
        * job_number,
        boro,
        bctcb2010,
        bct2010,
        nta2010,
        ntaname2010,
        puma2010,
        comp2010ap,
        comp2010,
        comp2011,
        comp2012,
        comp2013,
        comp2014,
        comp2015,
        comp2016,
        comp2017,
        comp2018,
        comp2019,
        comp2020,
        comp2020q2,
    )

*/


DROP TABLE IF EXISTS YEARLY_devdb;
WITH
DATES_complete_jobs AS (
    SELECT
        job_number,
        boro,
        bctcb2010,
        bct2010,
        nta2010,
        ntaname2010,
        puma2010,
        CASE WHEN job_type = 'Demolition' 
            AND date_permittd::date IS NOT NULL
            THEN date_permittd::date
            WHEN job_type <> 'Demolition'
            AND date_complete::date IS NOT NULL
            THEN date_complete::date
            ELSE date_lastupdt::date END as reference_date,
        classa_complt
        FROM FINAL_devdb
        WHERE job_status = '5. Complete'
)

SELECT job_number,
        boro,
        bctcb2010,
        bct2010,
        nta2010,
        ntaname2010,
        puma2010,
        CASE WHEN reference_date > '2010-03-31'::date
            AND reference_date < '2011-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2010ap,
        CASE WHEN reference_date > '2009-12-31'::date
            AND reference_date < '2010-04-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2010,
        CASE WHEN reference_date > '2010-12-31'::date
            AND reference_date < '2012-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2011,
        CASE WHEN reference_date > '2011-12-31'::date
            AND reference_date < '2013-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2012,
        CASE WHEN reference_date > '2012-12-31'::date
            AND reference_date < '2014-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2013,
        CASE WHEN reference_date > '2013-12-31'::date
            AND reference_date < '2015-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2014,
        CASE WHEN reference_date > '2014-12-31'::date
            AND reference_date < '2016-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2015,
        CASE WHEN reference_date > '2015-12-31'::date
            AND reference_date < '2017-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2016,
        CASE WHEN reference_date > '2016-12-31'::date
            AND reference_date < '2018-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2017,
        CASE WHEN reference_date > '2017-12-31'::date
            AND reference_date < '2019-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2018,
        CASE WHEN reference_date > '2018-12-31'::date
            AND reference_date < '2020-01-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2019,
        CASE WHEN reference_date > '2019-12-31'::date
            AND reference_date < '2020-07-01'::date
            THEN classa_complt
            ELSE NULL END AS comp2020q
INTO YEARLY_devdb
FROM DATES_complete_jobs;

    


    
