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
        comunitydist,
        councildist,
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
        SUM(comp2020q2) as comp2020q2,
        SUM(since_cen10) as since_cen10,
        SUM(incmpfiled) as incmpfiled,
        SUM(incmpprgrs) as incmpprgrs,
        SUM(incmprmtd) as incmprmtd,
        SUM(incmpwtdrn) as incmpwtdrn,
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
        comunitydist,
        councildist
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
        comunitydist,
        councildist,
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
        SUM(comp2020q2) as comp2020q2,
        SUM(since_cen10) as since_cen10,
        SUM(incmpfiled) as incmpfiled,
        SUM(incmpprgrs) as incmpprgrs,
        SUM(incmprmtd) as incmprmtd,
        SUM(incmpwtdrn) as incmpwtdrn,
        SUM(inactive) as inactive
    FROM YEARLY_devdb
    GROUP BY boro,
        bct2010,
        centract10,
        nta2010,
        ntaname2010,
        puma2010,
        comunitydist,
        councildist
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
    comp2020q2,
    incmpfiled,
    incmpprgrs,
    incmprmtd,
    incmpwtdrn,
    inactive,
    cenunits10,
    total20q2
INTO AGGREGATE_block
FROM _AGGREGATE_block;

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
    comp2020q2,
    incmpfiled,
    incmpprgrs,
    incmprmtd,
    incmpwtdrn,
    inactive,
    cenunits10,
    cenunits10adj,
    total20q2,
    total20q2adj
INTO AGGREGATE_tract
FROM _AGGREGATE_tract;

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
    SUM(comp2020q2) as comp2020q2,
    SUM(incmpfiled) as incmpfiled,
    SUM(incmpprgrs) as incmpprgrs,
    SUM(incmprmtd) as incmprmtd,
    SUM(incmpwtdrn) as incmpwtdrn,
    SUM(inactive) as inactive,
    SUM(cenunits10) as cenunits10,
    SUM(cenunits10adj) as cenunits10adj,
    SUM(total20q2) as total20q2,
    SUM(total20q2adj) as total20q2adj
INTO AGGREGATE_nta
FROM _AGGREGATE_tract
GROUP BY boro,
        nta2010,
        ntaname2010;

-- Create AGGREGATE_puma
DROP TABLE IF EXISTS AGGREGATE_puma;
SELECT boro,
    puma2010,
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
    SUM(comp2020q2) as comp2020q2,
    SUM(incmpfiled) as incmpfiled,
    SUM(incmpprgrs) as incmpprgrs,
    SUM(incmprmtd) as incmprmtd,
    SUM(incmpwtdrn) as incmpwtdrn,
    SUM(inactive) as inactive,
    SUM(cenunits10) as cenunits10,
    SUM(cenunits10adj) as cenunits10adj,
    SUM(total20q2) as total20q2,
    SUM(total20q2adj) as total20q2adj
INTO AGGREGATE_puma
FROM _AGGREGATE_tract
GROUP BY boro,
        puma2010;

-- Create AGGREGATE_comunitydist
DROP TABLE IF EXISTS AGGREGATE_comunitydist;
SELECT boro,
    comunitydist,
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
    SUM(comp2020q2) as comp2020q2,
    SUM(incmpfiled) as incmpfiled,
    SUM(incmpprgrs) as incmpprgrs,
    SUM(incmprmtd) as incmprmtd,
    SUM(incmpwtdrn) as incmpwtdrn,
    SUM(inactive) as inactive,
    SUM(cenunits10) as cenunits10,
    SUM(cenunits10adj) as cenunits10adj,
    SUM(total20q2) as total20q2,
    SUM(total20q2adj) as total20q2adj
INTO AGGREGATE_comunitydist
FROM _AGGREGATE_tract
GROUP BY boro,
        comunitydist;

-- Create AGGREGATE_councildist
DROP TABLE IF EXISTS AGGREGATE_councildist;
WITH 
ADJ as (
SELECT 
    councildist,
    SUM(cenunits10adj) as cenunits10adj,
    SUM(total20q2adj) as total20q2adj
FROM _AGGREGATE_tract
GROUP BY councildist
),
DRAFT as (
SELECT a.boro,
    a.councildist,
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
    SUM(a.comp2020q2) as comp2020q2,
    SUM(a.incmpfiled) as incmpfiled,
    SUM(a.incmpprgrs) as incmpprgrs,
    SUM(a.incmprmtd) as incmprmtd,
    SUM(a.incmpwtdrn) as incmpwtdrn,
    SUM(a.inactive) as inactive,
    SUM(a.cenunits10) as cenunits10,
    SUM(a.total20q2) as total20q2
FROM _AGGREGATE_block a
JOIN council_members b
ON a.councildist = b.district
GROUP BY a.boro, a.councildist, b.name
)
SELECT 
    a.*,
    b.cenunits10adj,
    b.total20q2adj
INTO AGGREGATE_councildist
FROM DRAFT a 
JOIN ADJ b
ON a.councildist = b.councildist;