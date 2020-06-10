-- remove extra spaces from address number and street field
-- populate the address field.
-- where street address is not null and house number only contains numbers
UPDATE developments a
SET address_house = trim(regexp_replace(a.address_house, '\s+', ' ', 'g')),
	address_street = trim(regexp_replace(a.address_street, '\s+', ' ', 'g')),
	address = trim(regexp_replace(a.address_house, '\s+', ' ', 'g'))||' '||trim(regexp_replace(a.address_street, '\s+', ' ', 'g'))
WHERE a.address_street IS NOT NULL
	AND replace(a.address_house, '-', '') ~ '[0-9]';