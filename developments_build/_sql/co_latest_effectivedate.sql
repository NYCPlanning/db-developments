UPDATE developments a
SET co_latest_effectivedate = b.latest_effective_date
FROM (
    SELECT jobnum, max(effectivedate::date) AS latest_effective_date
    FROM dob_cofos
    GROUP BY jobnum
    ) AS b
WHERE a.job_number = b.jobnum;
