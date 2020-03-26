-- Create an empty hny_id and job_number lookup table
DROP TABLE IF EXISTS hny_job_lookup;
CREATE TABLE hny_job_lookup(
    hny_id text,
    job_number text,
    match_method text,
    dob_type text,
    one_to_many_flag text,
    many_to_one_flag text,
    hny_to_job_relat text
);