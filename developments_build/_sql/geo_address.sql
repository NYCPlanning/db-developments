-- remove extra spaces from address number and street field
-- populate the address field.
-- where street address is not null and house number only contains numbers
-- similar to how we create address from address_street and address_house

UPDATE developments a
SET geo_address_house = trim(regexp_replace(a.geo_address_house, '\s+', ' ', 'g')),
	geo_address_street = trim(regexp_replace(a.geo_address_street, '\s+', ' ', 'g')),
	geo_address = trim(regexp_replace(a.geo_address_house, '\s+', ' ', 'g'))||' '||trim(regexp_replace(a.geo_address_street, '\s+', ' ', 'g'))
WHERE a.geo_address_street IS NOT NULL
	AND replace(a.geo_address_house, '-', '') ~ '[0-9]';
