-- overwite DOB data with DCP researched values
-- where DCP reseached value is valid
-- clean the housing_input_research table
UPDATE housing_input_research
SET old_value = nullif(old_value, ' '),
	new_value = nullif(new_value, ' ');

-- occ_category
UPDATE developments a
SET occ_category = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'occ_category'
AND (a.occ_category=b.old_value OR (a.occ_category IS NULL AND b.old_value IS NULL));

-- occ_init
UPDATE developments a
SET occ_init = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'occ_init'
AND (a.occ_init=b.old_value OR (a.occ_init IS NULL AND b.old_value IS NULL));

-- occ_prop
UPDATE developments a
SET occ_prop = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'occ_prop'
AND (a.occ_prop=b.old_value OR (a.occ_prop IS NULL AND b.old_value IS NULL));

-- stories_prop
UPDATE developments a
SET stories_prop = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'stories_prop'
AND (a.stories_prop::numeric=b.old_value::numeric OR (a.stories_prop IS NULL AND b.old_value IS NULL));

-- units_init
UPDATE developments a
SET units_init = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_init'
AND (a.units_init::numeric=b.old_value::numeric OR (a.units_init IS NULL AND b.old_value IS NULL));

-- units_prop_res
UPDATE developments a
SET units_prop = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_prop_res'
AND (a.units_prop::numeric=b.old_value::numeric OR (a.units_prop IS NULL AND b.old_value IS NULL));

-- units_prop
UPDATE developments a
SET units_prop = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_prop'
AND (a.units_prop::numeric=b.old_value::numeric OR (a.units_prop IS NULL AND b.old_value IS NULL))
AND a.job_number NOT IN (SELECT job_number FROM housing_input_research WHERE field = 'units_prop_res');

-- units_complete
UPDATE developments a
SET units_complete = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_complete'
AND (a.units_complete::numeric=b.old_value::numeric OR (a.units_complete IS NULL AND b.old_value IS NULL));

-- units_incomplete
UPDATE developments a
SET units_incomplete = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_incomplete'
AND (a.units_incomplete::numeric=b.old_value::numeric OR (a.units_incomplete IS NULL AND b.old_value IS NULL));

-- x_inactive
UPDATE developments a
SET x_inactive = b.new_value,
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'x_inactive'
AND (upper(a.x_inactive)=upper(b.old_value) OR (a.x_inactive IS NULL AND (b.old_value IS NULL OR b.old_value = 'false')));

UPDATE developments
	SET x_inactive = 'Inactive'
	WHERE x_mixeduse IS NOT NULL;

-- x_mixeduse
UPDATE developments a
SET x_mixeduse = b.new_value,
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'x_mixeduse'
AND (upper(a.x_mixeduse)=upper(b.old_value) OR (a.x_mixeduse IS NULL AND (b.old_value IS NULL OR b.old_value = 'false')));

UPDATE developments
	SET x_mixeduse = 'Mixed Use'
	WHERE x_mixeduse IS NOT NULL; 

-- bbl
UPDATE developments a
SET bbl = b.new_value,
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'bbl'
AND a.bbl IS NULL AND b.old_value IS NOT NULL;

-- bin
UPDATE developments a
SET bin = b.new_value,
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'bin'
AND a.bin IS NULL AND b.old_value IS NOT NULL;

UPDATE developments
	SET x_dcpedited = 'Edited'
	WHERE x_dcpedited IS NOT NULL; 

-- UPDATE developments a
-- SET co_latest_units = TRIM(b.c_u_latest),
-- 	x_dcpedited = TRUE,
-- 	x_reason = b.reason
-- FROM housing_input_dcpattributes b
-- WHERE b.c_u_latest ~ '[0-9]'
-- 	AND a.job_number=b.job_number;

-- UPDATE developments a
-- SET x_inactive = TRIM(b.x_inactive),
-- 	x_dcpedited = TRUE,
-- 	x_reason = b.reason
-- FROM housing_input_dcpattributes b
-- WHERE b.x_inactive IS NOT NULL
-- 	AND a.job_number=b.job_number;