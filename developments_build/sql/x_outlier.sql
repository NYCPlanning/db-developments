UPDATE developments
SET x_outlier = TRUE
WHERE job_number IN
	(SELECT DISTINCT job_number
		FROM qc_outliers 
			WHERE job_number NOT IN 
			(SELECT DISTINCT job_number 
				FROM qc_outliersacrhived 
				WHERE outlier = 'N') 
			AND job_number NOT IN 
			(SELECT DISTINCT job_number 
				FROM developments 
				WHERE x_dcpedited = 'true'));
-- -- Remove the data table
-- DROP TABLE IF EXISTS qc_outliers;