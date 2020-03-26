-- the latest number of reported number of dwellingunits

UPDATE developments a
SET co_latest_units = b.numofdwellingunits
FROM (
    SELECT jobnum, numofdwellingunits, max(effectivedate::date)
    FROM dob_cofos
    GROUP BY jobnum, numofdwellingunits
    ) AS b
WHERE a.job_number = b.jobnum;
