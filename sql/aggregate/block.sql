DROP TABLE IF EXISTS _AGGREGATE_block;
WITH
bctcb2010_aggregate AS (
    SELECT 
        boro,
        bctcb2010,
        cenblock10,
        bct2010,
        centract10,
        nta2010,
        ntaname2010,
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
    GROUP BY boro,
        bctcb2010,
        cenblock10,
        bct2010,
        centract10,
        nta2010,
        ntaname2010),
CENSUS_bctcb2010 AS (
    SELECT 
        a.*,
        b.cenunits10, 
        COALESCE(a.since_cen10, 0) + COALESCE(b.cenunits10, 0) as total
    FROM bctcb2010_aggregate a 
    JOIN census_units10 b
    ON a.cenblock10 = b.cenblock10
)
SELECT *
INTO _AGGREGATE_block
FROM CENSUS_bctcb2010;

DROP TABLE IF EXISTS AGGREGATE_block;
SELECT boro,
    bctcb2010,
    cenblock10,
    comp2010ap,
    {%- for year in years %}
    comp{{year}},
    {% endfor %}
    filed,
    approved,
    permitted,
    withdrawn,
    inactive,
    cenunits10,
    total
INTO AGGREGATE_block
FROM _AGGREGATE_block
ORDER BY bctcb2010;