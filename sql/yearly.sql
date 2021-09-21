/*
DESCRIPTION:
    Creates an unaggregated table as input for the spatial aggregates.
    Includes completions split by year. 
    
INPUTS:
    FINAL_devdb
    LOOKUP_geo
OUTPUTS:
    YEARLY_devdb
*/

DROP TABLE IF EXISTS YEARLY_devdb;
SELECT a.job_number,
        b.boro,
        b.borocode,
        b.bctcb2010,
        b.fips_boro||b.ctcb2010 as cenblock10,
        b.bct2010,
        b.fips_boro||b.ct2010 as centract10,
        b.nta as nta2010,
        b.ntaname as ntaname2010,
        b.puma as puma2010,
        b.pumaname as pumaname10,
        b.commntydst,
        b.councildst,
        CASE WHEN a.complete_year = '2010' AND a.date_complete > '2010-03-31'::date
                AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2010ap,
        CASE WHEN a.complete_year = '2010' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2010,
        CASE WHEN a.complete_year = '2011' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2011,
        CASE WHEN a.complete_year = '2012' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2012,
        CASE WHEN a.complete_year = '2013' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2013,
        CASE WHEN a.complete_year = '2014' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2014,
        CASE WHEN a.complete_year = '2015' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2015,
        CASE WHEN a.complete_year = '2016' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2016,
        CASE WHEN a.complete_year = '2017' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2017,
        CASE WHEN a.complete_year = '2018' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2018,
        CASE WHEN a.complete_year = '2019' AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS comp2019,
        CASE WHEN a.complete_year = '2020' AND a.job_inactive IS NULL
            THEN classa_net
            ELSE NULL END AS comp2020,
        CASE WHEN a.complete_year = '2021' AND a.job_inactive IS NULL
            THEN classa_net
            ELSE NULL END AS comp2021,
        CASE WHEN a.date_complete > '2010-03-31'::date AND a.date_complete < :'CAPTURE_DATE'::date
                AND a.job_inactive IS NULL
            THEN a.classa_net
            ELSE NULL END AS since_cen10,
        CASE WHEN a.job_status = '1. Filed Application'
                AND a.job_inactive IS NULL
            THEN  a.classa_net 
            ELSE NULL END as filed, 
        CASE WHEN a.job_status = '2. Approved Application'
                AND a.job_inactive IS NULL
            THEN  a.classa_net 
            ELSE NULL END as approved, 
        CASE WHEN a.job_status = '3. Permitted for Construction'
                AND a.job_inactive IS NULL
            THEN  a.classa_net 
            ELSE NULL END as permitted, 
        CASE WHEN a.job_status = '9. Withdrawn'
                AND a.date_lastupdt::date > '2009-12-31'::date
            THEN  a.classa_net 
            ELSE NULL END as withdrawn, 
        CASE WHEN a.job_status <> '9. Withdrawn'
                AND a.job_inactive ~* 'Inactive'
                AND a.date_lastupdt::date > '2009-12-31'::date
            THEN  a.classa_net 
            ELSE NULL END as inactive
INTO YEARLY_devdb
FROM FINAL_devdb a
RIGHT JOIN LOOKUP_geo b
ON a.bctcb2010 = b.bctcb2010;