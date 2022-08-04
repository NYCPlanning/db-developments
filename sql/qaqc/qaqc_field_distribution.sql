DROP TABLE IF EXISTS field_dist_qaqc;
CREATE TABLE IF NOT EXISTS field_dist_qaqc(
    field_name character varying,
    result character varying
);

INSERT INTO field_dist_qaqc (
    SELECT 'Job_Type' as field_name,
            jsonb_agg(json_build_object('job_type',tmp.job_type,'count',tmp.count)) as result
    FROM(
        SELECT job_type, COUNT(DISTINCT job_number) as count
        FROM final_devdb
        WHERE date_filed >= CAST(:PRE_DATE AS VARCHAR)
        GROUP BY job_type) tmp );

INSERT INTO field_dist_qaqc (
    SELECT 'Job_Status' as field_name,
            jsonb_agg(json_build_object('job_status',tmp.job_status,'count',tmp.count)) as result 
    FROM(
        SELECT job_status, COUNT(DISTINCT job_number) as count
        FROM final_devdb
        WHERE date_filed >= CAST(:PRE_DATE AS VARCHAR)
        GROUP BY job_status) tmp );