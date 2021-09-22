
DROP TABLE IF EXISTS _AGGREGATE_tract;
WITH
CENSUS_by_tract AS (
    SELECT centract10, SUM(cenunits10) as cenunits10
    FROM census_units10
    GROUP BY centract10
),
bct2010_aggregate AS (
    SELECT 
        boro,
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
        bct2010,
        centract10,
        nta2010,
        ntaname2010
        ),
CENSUS_bct2010 AS (
    SELECT a.*,  
            b.cenunits10, 
            COALESCE(a.since_cen10, 0) + COALESCE(b.cenunits10, 0) as total
    FROM bct2010_aggregate a 
    JOIN CENSUS_by_tract b
    ON a.centract10 = b.centract10
),
CENSUS_adj_bct2010 AS(
    SELECT a.*,
            b.adjunits10,
            COALESCE(a.since_cen10, 0) + COALESCE(b.adjunits10, 0) as totaladj
    FROM CENSUS_bct2010 a 
    JOIN census_units10adj b
    ON a.centract10 = b.centract10
)
SELECT *
INTO _AGGREGATE_tract
FROM CENSUS_adj_bct2010;

DROP TABLE IF EXISTS AGGREGATE_tract;
SELECT boro,
    bct2010,
    centract10,
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
    adjunits10,
    total,
    totaladj
INTO AGGREGATE_tract
FROM _AGGREGATE_tract
ORDER BY bct2010;