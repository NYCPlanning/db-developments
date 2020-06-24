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
        classa_net,
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
        incmpfiled,
        incmpprgrs,
        incmprmtd,
        incmpwtdrn,
        inactive
    )

*/


DROP TABLE IF EXISTS YEARLY_devdb;
SELECT job_number,
        boro,
        bctcb2010,
        bct2010,
        nta2010,
        ntaname2010,
        puma2010,
        CASE WHEN complete_year = '2010' AND date_complete > '2010-03-31'::date
            THEN classa_net
            ELSE NULL END AS comp2010ap,
        CASE WHEN complete_year = '2010' 
            THEN classa_net
            ELSE NULL END AS comp2010,
        CASE WHEN complete_year = '2011'
            THEN classa_net
            ELSE NULL END AS comp2011,
        CASE WHEN complete_year = '2012'
            THEN classa_net
            ELSE NULL END AS comp2012,
        CASE WHEN complete_year = '2013'
            THEN classa_net
            ELSE NULL END AS comp2013,
        CASE WHEN complete_year = '2014'
            THEN classa_net
            ELSE NULL END AS comp2014,
        CASE WHEN complete_year = '2015'
            THEN classa_net
            ELSE NULL END AS comp2015,
        CASE WHEN complete_year = '2016'
            THEN classa_net
            ELSE NULL END AS comp2016,
        CASE WHEN complete_year = '2017'
            THEN classa_net
            ELSE NULL END AS comp2017,
        CASE WHEN complete_year = '2018'
            THEN classa_net
            ELSE NULL END AS comp2018,
        CASE WHEN complete_year = '2019'
            THEN classa_net
            ELSE NULL END AS comp2019,
        CASE WHEN complete_year = '2020' AND date_complete < '2020-07-01'::date
            THEN classa_net
            ELSE NULL END AS comp2020q2,
        CASE WHEN job_status = '1. Filed Application'
                AND job_inactive IS NULL
            THEN  classa_net 
            ELSE NULL END as incmpfiled, 
        CASE WHEN job_status = '2. Approved Application'
                AND job_inactive IS NULL
            THEN  classa_net 
            ELSE NULL END as incmpprgrs, 
        CASE WHEN job_status = '3. Permitted for Construction'
                AND job_inactive IS NULL
            THEN  classa_net 
            ELSE NULL END as incmprmtd, 
        CASE WHEN job_status = '9. Withdrawn'
                AND job_inactive IS NULL
            THEN  classa_net 
            ELSE NULL END as incmpwtdrn, 
        CASE WHEN job_status <> '9. Withdrawn'
                AND job_inactive = 'Inactive'
            THEN  classa_net 
            ELSE NULL END as inactive
INTO YEARLY_devdb
FROM FINAL_devdb;
