-- removing leading . in occupancy code value
UPDATE developments
SET occ_init = split_part(occ_init, '.', 2)
WHERE occ_init LIKE '.%';

UPDATE developments
SET occ_prop = split_part(occ_prop, '.', 2)
WHERE occ_prop LIKE '.%';

-- make units null when it doesn't contain only numbers
UPDATE developments a
SET units_prop = NULL 
WHERE a.units_prop ~ '[^0-9]';
-- make boro proper case
UPDATE developments a
SET boro = INITCAP(boro) 
WHERE boro IS NOT NULL;

-- replace 0 with NULL, since 0 is likely incorrect in the following cases
UPDATE developments
SET stories_init = NULL
WHERE stories_init = '0'
AND (job_type = 'A1'
OR job_type = 'DM');

UPDATE developments
SET zoningsft_init = NULL
WHERE zoningsft_init = '0'
AND (job_type = 'A1'
OR job_type = 'DM');

UPDATE developments
SET zoningsft_prop = NULL
WHERE zoningsft_prop = '0'
AND (job_type = 'A1'
OR job_type = 'NB');