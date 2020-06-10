-- for each job number
-- units_net_incomplete = units_net - units_net_complete

UPDATE developments a
SET units_incomplete = a.units_net::INTEGER - a.units_net_complete::integer;
