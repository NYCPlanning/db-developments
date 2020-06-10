-- co_latest_certype
-- by definition co_latest_certtype is the certificatetype for the latest certificate occupancy record in dob_cofos

UPDATE developments a
SET co_latest_certtype = b.certificatetype
FROM (
    SELECT jobnum, certificatetype, max(effectivedate::date)
    FROM dob_cofos
    GROUP BY jobnum, certificatetype
    ) AS b
WHERE a.job_number = b.jobnum;
