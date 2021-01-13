/*
DESCRIPTION:
    Creates six aggregate tables, containing unit counts
    summed over different geographies, with completions grouped by year.
    
INPUTS:
    YEARLY_devdb (
        * job_number,
        boro,
        bctcb2010,
        bct2010,
        nta2010,
        ntaname2010,
        puma2010,
        pumaname10,
        commntydst,
        councildst,
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
        since_cen10,
        filed,
        approved,
        permitted,
        withdrawn,
        inactive
    ),

    council_members(
        * district
        name
    ),

    census_units10 (
        * cenblock10,
        cenunits10
    ),

    census_units10adj(
        * centract10,
        cenunits10adj
    )

OUTPUTS:
    _AGGREGATE_block (
        boro,
        * bctcb2010,
        bct2010,
        nta2010,
        ntaname2010,
        puma2010,
        pumaname10,
        commntydst,
        councildst,
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
        filed,
        approved,
        permitted,
        withdrawn,
        inactive,
        cenunits10,
        total20q2
    ),

    _AGGREGATE_tract(
        boro,
        * bct2010,
        nta2010,
        ntaname2010,
        puma2010,
        pumaname10,
        commntydst,
        councildst,
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
        filed,
        approved,
        permitted,
        withdrawn,
        inactive,
        cenunits10,
        total20q2,
        cenunits10adj,
        total20q2adj
    ),

    AGGREGATE_block (
        boro,
        bctcb2010,
        cenblock10,
        comp2010ap,
        comp2010,
        ...
        cenunits10,
        total20q2
    ),

    AGGREGATE_tract (
        boro,
        bct2010,
        centract10,
        comp2010ap,
        comp2010,
        ...
        cenunits10,
        total20q2,
        cenunits10adj,
        total20q2adj
    ),

    AGGREGATE_nta (
        boro,
        nta2010,
        ntaname10,
        comp2010ap,
        comp2010,
        ...
        cenunits10,
        total20q2,
        cenunits10adj,
        total20q2adj
    ),

    AGGREGATE_puma (
        boro,
        puma2010,
        pumaname10,
        comp2010ap,
        comp2010,
        ...
        cenunits10,
        total20q2,
        cenunits10adj,
        total20q2adj
    ),

    AGGREGATE_commntydst (
        commntydst,
        comp2010ap,
        comp2010,
        ...
        cenunits10,
        total20q2,
        cenunits10adj,
        total20q2adj
    ),

    AGGREGATE_councildst (
        councildst,
        councilmbr,
        comp2010ap,
        comp2010,
        ...
        cenunits10,
        total20q2,
        cenunits10adj,
        total20q2adj
    )

*/


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
        puma2010,
        pumaname10,
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
        ntaname2010,
        puma2010,
        pumaname10
        ),
CENSUS_bctcb2010 AS (
    SELECT a.*,  
            b.cenunits10, 
            COALESCE(a.since_cen10, 0) + COALESCE(b.cenunits10, 0) as total20q2
    FROM bctcb2010_aggregate a 
    JOIN census_units10 b
    ON a.cenblock10 = b.cenblock10
)
SELECT *
INTO _AGGREGATE_block
FROM CENSUS_bctcb2010;

-- Create _AGGREGATE_commntydst

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
            COALESCE(a.since_cen10, 0) + COALESCE(b.cenunits10, 0) as total20q2
    FROM bctcb2010_aggregate a 
    JOIN census_units10 b
    ON a.cenblock10 = b.cenblock10
)
SELECT *
INTO _AGGREGATE_commntydst
FROM CENSUS_bctcb2010;


-- Create _AGGREGATE_councildst
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
            COALESCE(a.since_cen10, 0) + COALESCE(b.cenunits10, 0) as total20q2
    FROM bctcb2010_aggregate a 
    JOIN census_units10 b
    ON a.cenblock10 = b.cenblock10
)
SELECT *
INTO _AGGREGATE_councildst
FROM CENSUS_bctcb2010;

-- Create _AGGREGATE_tract;

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
        puma2010,
        pumaname10,
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
        ntaname2010,
        puma2010,
        pumaname10
        ),
CENSUS_bct2010 AS (
    SELECT a.*,  
            b.cenunits10, 
            COALESCE(a.since_cen10, 0) + COALESCE(b.cenunits10, 0) as total20q2
    FROM bct2010_aggregate a 
    JOIN CENSUS_by_tract b
    ON a.centract10 = b.centract10
),
CENSUS_adj_bct2010 AS(
    SELECT a.*,
            b.cenunits10adj,
            COALESCE(a.since_cen10, 0) + COALESCE(b.cenunits10adj, 0) as total20q2adj
    FROM CENSUS_bct2010 a 
    JOIN census_units10adj b
    ON a.centract10 = b.centract10
)
SELECT *
INTO _AGGREGATE_tract
FROM CENSUS_adj_bct2010;


-- Create AGGREGATE_block
DROP TABLE IF EXISTS AGGREGATE_block;
SELECT boro,
    bctcb2010,
    cenblock10,
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
    filed,
    approved,
    permitted,
    withdrawn,
    inactive,
    cenunits10,
    total20q2
INTO AGGREGATE_block
FROM _AGGREGATE_block
ORDER BY bctcb2010;

-- Create AGGREGATE_tract
DROP TABLE IF EXISTS AGGREGATE_tract;
SELECT boro,
    bct2010,
    centract10,
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
    filed,
    approved,
    permitted,
    withdrawn,
    inactive,
    cenunits10,
    cenunits10adj,
    total20q2,
    total20q2adj
INTO AGGREGATE_tract
FROM _AGGREGATE_tract
ORDER BY bct2010;

-- Create AGGREGATE_nta
DROP TABLE IF EXISTS AGGREGATE_nta;
SELECT boro,
    nta2010,
    ntaname2010,
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
    SUM(filed) as filed,
    SUM(approved) as approved,
    SUM(permitted) as permitted,
    SUM(withdrawn) as withdrawn,
    SUM(inactive) as inactive,
    SUM(cenunits10) as cenunits10,
    SUM(cenunits10adj) as cenunits10adj,
    SUM(total20q2) as total20q2,
    SUM(total20q2adj) as total20q2adj
INTO AGGREGATE_nta
FROM _AGGREGATE_tract
GROUP BY boro,
        nta2010,
        ntaname2010
ORDER BY nta2010;

-- Create AGGREGATE_puma
DROP TABLE IF EXISTS AGGREGATE_puma;
SELECT boro,
    puma2010,
    pumaname10,
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
    SUM(filed) as filed,
    SUM(approved) as approved,
    SUM(permitted) as permitted,
    SUM(withdrawn) as withdrawn,
    SUM(inactive) as inactive,
    SUM(cenunits10) as cenunits10,
    SUM(cenunits10adj) as cenunits10adj,
    SUM(total20q2) as total20q2,
    SUM(total20q2adj) as total20q2adj
INTO AGGREGATE_puma
FROM _AGGREGATE_tract
GROUP BY boro,
        puma2010,
        pumaname10
ORDER BY puma2010;

-- Create AGGREGATE_commntydst
DROP TABLE IF EXISTS AGGREGATE_commntydst;
SELECT boro,
    commntydst,
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
    SUM(filed) as filed,
    SUM(approved) as approved,
    SUM(permitted) as permitted,
    SUM(withdrawn) as withdrawn,
    SUM(inactive) as inactive,
    SUM(cenunits10) as cenunits10,
    SUM(total20q2) as total20q2
INTO AGGREGATE_commntydst
FROM _AGGREGATE_commntydst
GROUP BY
        boro,
		commntydst
ORDER BY commntydst;


-- Create AGGREGATE_councildst
DROP TABLE IF EXISTS AGGREGATE_councildst;
SELECT
    a.councildst,
    b.name as councilmbr,
    SUM(a.comp2010ap) as comp2010ap,
    SUM(a.comp2010) as comp2010,
    SUM(a.comp2011) as comp2011,
    SUM(a.comp2012) as comp2012,
    SUM(a.comp2013) as comp2013,
    SUM(a.comp2014) as comp2014,
    SUM(a.comp2015) as comp2015,
    SUM(a.comp2016) as comp2016,
    SUM(a.comp2017) as comp2017,
    SUM(a.comp2018) as comp2018,
    SUM(a.comp2019) as comp2019,
    SUM(a.comp2020) as comp2020,
    SUM(a.filed) as filed,
    SUM(a.approved) as approved,
    SUM(a.permitted) as permitted,
    SUM(a.withdrawn) as withdrawn,
    SUM(a.inactive) as inactive,
    SUM(a.cenunits10) as cenunits10,
    SUM(a.total20q2) as total20q2
INTO AGGREGATE_councildst
FROM _AGGREGATE_councildst a
JOIN council_members b
ON a.councildst::int = b.district::int
GROUP BY a.councildst, b.name
ORDER BY councildst;