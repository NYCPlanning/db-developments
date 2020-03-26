-- get the earliest and latest date for the COs of each job number
WITH cosum AS(
	SELECT job_number,
	min(effectivedate::date) AS co_earliest_effectivedate,
	LEFT(min(effectivedate::date)::text,4) AS year_complete,
	max(effectivedate::date) AS co_latest_effectivedate
	FROM developments_co
	GROUP BY job_number)

UPDATE developments a
SET co_earliest_effectivedate = b.co_earliest_effectivedate,
	year_complete = b.year_complete,
	co_latest_effectivedate = b.co_latest_effectivedate
FROM cosum b
WHERE a.job_number=b.job_number;

-- populate the certificate type and number of units associated with the latest co
UPDATE developments a
SET co_latest_certtype = b.certtype,
	co_latest_units = b.units
FROM developments_co b
WHERE a.job_number=b.job_number
AND a.co_latest_effectivedate::date = b.effectivedate::date;

-- if a job number is associated with multiple COs on its co_latest_effectivedate,
-- assign the COs with C-CO as certype to developments if both C-CO and T-CO certtype exit.
WITH multiple AS (
	SELECT a.job_number
	FROM developments a, developments_co b
	WHERE a.job_number=b.job_number
	AND a.co_latest_effectivedate::date = b.effectivedate::date
	GROUP BY a.job_number
	HAVING count(*) > 1
)
UPDATE developments a
SET co_latest_certtype = b.certtype,
	co_latest_units = b.units
FROM developments_co b
WHERE a.job_number=b.job_number
AND a.co_latest_effectivedate::date = b.effectivedate::date
AND a.job_number IN (
SELECT job_number FROM multiple)
AND certtype = 'C- CO';
