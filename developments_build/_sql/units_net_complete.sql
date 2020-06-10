-- for each job number
-- units_net_complete = max(dob_cofos.numofdwellingunits)

UPDATE developments a
SET units_complete = b.max_unit
FROM (
    SELECT jobnum, max(numofdwellingunits) AS max_unit
    FROM dob_cofos
    GROUP BY jobnum
    ) AS b
WHERE a.job_number = b.jobnum;
