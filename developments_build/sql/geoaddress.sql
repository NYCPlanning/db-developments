-- setting the address from geosupport
UPDATE developments a
SET geo_address = trim(regexp_replace(a.geo_address_house, '\s+', ' ', 'g'))||' '||trim(regexp_replace(a.geo_address_street, '\s+', ' ', 'g'))
WHERE a.geo_address_street IS NOT NULL;