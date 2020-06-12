CREATE OR REPLACE FUNCTION is_date(s varchar) RETURNS boolean AS $$
BEGIN
  perform s::date;
  RETURN true;
exception WHEN others THEN
  RETURN false;
END;
$$ LANGUAGE plpgsql;