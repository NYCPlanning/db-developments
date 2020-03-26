-- create the certificate of occupancy table
DROP TABLE IF EXISTS developments_co;
CREATE TABLE developments_co AS (
SELECT jobnum as job_number, 
	effectivedate, 
	numofdwellingunits as units,
	certificatetype as certtype
FROM dob_cofos
WHERE jobnum IN (
	SELECT DISTINCT job_number 
	FROM developments));