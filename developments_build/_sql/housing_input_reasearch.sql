INSERT INTO housing_input_research (
    job_number, 
    field
)
SELECT 
    job_number, 
    'remove' as field
FROM developments
WHERE UPPER(job_description) LIKE '%BIS%TEST%' 
    OR UPPER(job_description) LIKE '% TEST %'
AND job_number NOT IN(
    SELECT 
        DISTINCT job_number
    FROM housing_input_research
    WHERE field = 'remove'
);

DELETE FROM developments a
USING housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'remove';