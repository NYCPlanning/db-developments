DROP TABLE IF EXISTS AGGREGATE_nta;
SELECT boro,
    nta2010,
    ntaname2010,
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
    SUM(adjunits10) as adjunits10,
    SUM(total) as total,
    SUM(totaladj) as totaladj
INTO AGGREGATE_nta
FROM _AGGREGATE_tract
GROUP BY boro,
        nta2010,
        ntaname2010
ORDER BY nta2010;
