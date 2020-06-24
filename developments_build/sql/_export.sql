-- EXPORT DevDB
DROP TABLE IF EXISTS EXPORT_devdb;
SELECT * 
INTO EXPORT_devdb
FROM FINAL_devdb
WHERE ((Date_Complete::date >= '2010-01-01' 
		AND Date_Complete::date <=  :'CAPTURE_DATE')
	OR (Date_Complete IS NULL 
		AND Date_Permittd::date >= '2010-01-01' 
		AND Date_Permittd::date <=  :'CAPTURE_DATE')
	OR (Date_Complete IS NULL 
		AND Date_Permittd IS NULL 
		AND Date_Filed::date >= '2010-01-01' 
		AND Date_Filed::date <=  :'CAPTURE_DATE'));

-- EXPORT HousingDB
DROP TABLE IF EXISTS EXPORT_housing;
SELECT * INTO EXPORT_housing
FROM EXPORT_devdb
WHERE resid_flag = 'Residential';