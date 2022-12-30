DROP TABLE IF EXISTS AGGREGATE_block_{{ decade }};
with aggregate_units as (SELECT 
    bctcb{{ decade }}::TEXT,
    SUM(comp2010ap) as comp2010ap,

    {%- for year in years %}

        SUM(comp{{year}}) as comp{{year}},
        
    {% endfor %}

    -- SUM(since_cen10) as since_cen10,
    SUM(filed) as filed,
    SUM(approved) as approved,
    SUM(permitted) as permitted,
    SUM(withdrawn) as withdrawn,
    SUM(inactive) as inactive


FROM YEARLY_devdb_{{ decade }}

GROUP BY 
    boro,
    bctcb{{ decade }},
    cenblock{{ decade }}
)
SELECT 
a.*,
c.census_units20 as 
INTO AGGREGATE_block_2020
FROM aggregate_units a LEFT JOIN census_units20 c
ON a.bctcb20 = c.BCTCB2020