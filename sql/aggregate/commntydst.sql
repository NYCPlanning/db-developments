
DROP TABLE IF EXISTS _AGGREGATE_commntydst;
WITH
bctcb2010_aggregate AS (
    SELECT 
        (CASE
            WHEN LEFT(commntydst, 1) = '1' THEN 'Manhattan'
            WHEN LEFT(commntydst, 1) = '2' THEN 'Bronx'
            WHEN LEFT(commntydst, 1) = '3' THEN 'Brooklyn'
            WHEN LEFT(commntydst, 1) = '4' THEN 'Queens'
            WHEN LEFT(commntydst, 1) = '5' THEN 'Staten Island'
        END) as boro,
        cenblock10,
        commntydst,
        SUM(comp2010ap) as comp2010ap,
        {%- for year in years %}
        SUM(comp{{year}}) as comp{{year}},
        {% endfor %}
        SUM(since_cen10) as since_cen10,
        SUM(filed) as filed,
        SUM(approved) as approved,
        SUM(permitted) as permitted,
        SUM(withdrawn) as withdrawn,
        SUM(inactive) as inactive
    FROM YEARLY_devdb
    GROUP BY 
        cenblock10,
        commntydst
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
INTO _AGGREGATE_commntydst
FROM CENSUS_bctcb2010;


DROP TABLE IF EXISTS AGGREGATE_commntydst;
SELECT boro,
    commntydst,
    SUM(comp2010ap) as comp2010ap,
    {%- for year in years %}
    SUM(comp{{year}}) as comp{{year}},
    {% endfor %}
    SUM(filed) as filed,
    SUM(approved) as approved,
    SUM(permitted) as permitted,
    SUM(withdrawn) as withdrawn,
    SUM(inactive) as inactive,
    SUM(cenunits10) as cenunits10,
    SUM(total) as total
INTO AGGREGATE_commntydst
FROM _AGGREGATE_commntydst
GROUP BY
        boro,
		commntydst
ORDER BY commntydst;
