-- co_earliest_effectivedate
-- created by selecting the earliest effective date from dob_cofos

UPDATE developments a
SET co_earliest_effectivedate = b.earliest_effective_date
FROM (
    SELECT jobnum, min(effectivedate::date) AS earliest_effective_date
    FROM dob_cofos
    GROUP BY jobnum
    ) AS b
WHERE a.job_number = b.jobnum;
