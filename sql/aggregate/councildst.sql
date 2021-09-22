DROP TABLE IF EXISTS _AGGREGATE_councildst;
WITH
bctcb2010_aggregate AS (
    SELECT 
        cenblock10,
        councildst,
        SUM(comp2010ap) as comp2010ap,
        SUM(comp2010) as comp2010,
        SUM(comp2011) as comp2011,
        SUM(comp2012) as comp2012,
        SUM(comp2013) as comp2013,
        SUM(comp2014) as comp2014,
        SUM(comp2015) as comp2015,
        SUM(comp2016) as comp2016,
        SUM(comp2017) as comp2017,
        SUM(comp2018) as comp2018,
        SUM(comp2019) as comp2019,
        SUM(comp2020) as comp2020,
        SUM(comp2021) as comp2021,
        SUM(since_cen10) as since_cen10,
        SUM(filed) as filed,
        SUM(approved) as approved,
        SUM(permitted) as permitted,
        SUM(withdrawn) as withdrawn,
        SUM(inactive) as inactive
    FROM YEARLY_devdb
    GROUP BY 
        cenblock10,
        councildst
        ),
CENSUS_bctcb2010 AS (
    SELECT a.*,  
            b.cenunits10, 
            COALESCE(a.since_cen10, 0) + COALESCE(b.cenunits10, 0) as total
    FROM bctcb2010_aggregate a 
    JOIN census_units10 b
    ON a.cenblock10 = b.cenblock10
)
SELECT *
INTO _AGGREGATE_councildst
FROM CENSUS_bctcb2010;


DROP TABLE IF EXISTS AGGREGATE_councildst;
SELECT
    a.councildst,
    b.name as councilmbr,
    SUM(a.comp2010ap) as comp2010ap,
    {%- for year in years %}
    SUM(comp{{year}}) as comp{{year}},
    {% endfor %}
    SUM(a.filed) as filed,
    SUM(a.approved) as approved,
    SUM(a.permitted) as permitted,
    SUM(a.withdrawn) as withdrawn,
    SUM(a.inactive) as inactive,
    SUM(a.cenunits10) as cenunits10,
    SUM(a.total) as total
INTO AGGREGATE_councildst
FROM _AGGREGATE_councildst a
JOIN council_members b
ON a.councildst::int = b.district::int
GROUP BY a.councildst, b.name
ORDER BY councildst;