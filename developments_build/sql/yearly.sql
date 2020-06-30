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
        puma2010,
        comunitydist,
        councildist
    )

    LOOKUP_geo(
        boro,
        fips_boro,
        hed_pumaname
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
        pumaname10,
        comunitydist,
        councildist,
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
        since_cen10,
        incmpfiled,
        incmpprgrs,
        incmprmtd,
        incmpwtdrn,
        inactive
    )

*/


DROP TABLE IF EXISTS YEARLY_devdb;
SELECT a.job_number,
        a.boro,
        a.bctcb2010,
        b.fips_boro||RIGHT(a.bctcb2010, 10) as cenblock10,
        a.bct2010,
        b.fips_boro||RIGHT(a.bct2010, 6) as centract10,
        a.nta2010,
        a.ntaname2010,
        a.puma2010,
        b.hed_pumaname as pumaname10,
        a.comunitydist,
        a.councildist,
        CASE WHEN a.complete_year = '2010' AND a.date_complete > '2010-03-31'::date
            THEN a.classa_net
            ELSE NULL END AS comp2010ap,
        CASE WHEN a.complete_year = '2010' 
            THEN a.classa_net
            ELSE NULL END AS comp2010,
        CASE WHEN a.complete_year = '2011'
            THEN a.classa_net
            ELSE NULL END AS comp2011,
        CASE WHEN a.complete_year = '2012'
            THEN a.classa_net
            ELSE NULL END AS comp2012,
        CASE WHEN a.complete_year = '2013'
            THEN a.classa_net
            ELSE NULL END AS comp2013,
        CASE WHEN a.complete_year = '2014'
            THEN a.classa_net
            ELSE NULL END AS comp2014,
        CASE WHEN a.complete_year = '2015'
            THEN a.classa_net
            ELSE NULL END AS comp2015,
        CASE WHEN a.complete_year = '2016'
            THEN a.classa_net
            ELSE NULL END AS comp2016,
        CASE WHEN a.complete_year = '2017'
            THEN a.classa_net
            ELSE NULL END AS comp2017,
        CASE WHEN a.complete_year = '2018'
            THEN a.classa_net
            ELSE NULL END AS comp2018,
        CASE WHEN a.complete_year = '2019'
            THEN a.classa_net
            ELSE NULL END AS comp2019,
        CASE WHEN a.complete_year = '2020' AND a.date_complete < '2020-07-01'::date
            THEN classa_net
            ELSE NULL END AS comp2020q2,
        CASE WHEN a.date_complete > '2010-03-31'::date AND a.date_complete < '2020-07-01'::date
            THEN a.classa_net
            ELSE NULL END AS since_cen10,
        CASE WHEN a.job_status = '1. Filed Application'
                AND a.job_inactive IS NULL
            THEN  a.classa_net 
            ELSE NULL END as incmpfiled, 
        CASE WHEN a.job_status = '2. Approved Application'
                AND a.job_inactive IS NULL
            THEN  a.classa_net 
            ELSE NULL END as incmpprgrs, 
        CASE WHEN a.job_status = '3. Permitted for Construction'
                AND a.job_inactive IS NULL
            THEN  a.classa_net 
            ELSE NULL END as incmprmtd, 
        CASE WHEN a.job_status = '9. Withdrawn'
                AND a.job_inactive IS NULL
            THEN  a.classa_net 
            ELSE NULL END as incmpwtdrn, 
        CASE WHEN a.job_status <> '9. Withdrawn'
                AND a.job_inactive = 'Inactive'
            THEN  a.classa_net 
            ELSE NULL END as inactive
INTO YEARLY_devdb
FROM FINAL_devdb a
LEFT JOIN LOOKUP_geo b
ON a.bct2010 = b.borocode||b.ct2010;
