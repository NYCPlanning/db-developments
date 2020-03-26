drop table if exists qc_null;

select * into qc_null from (select
	'total' as field,
	count(*) as geosupport, 
	count(*) as spatialjoin
	from qc_geom a
union
select
	 'geom' as field,
	sum(case when a.geom is null then 1 else 0 end) as geosupport, 
	sum(case when a.geom is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'bbl' as field,
	sum(case when a.geo_bbl is null then 1 else 0 end) as geosupport, 
	sum(case when a.bbl is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'bin' as field,
	sum(case when a.geo_bin is null then 1 else 0 end) as geosupport, 
	sum(case when a.bin is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'zipcode' as field,
	sum(case when a.geo_zipcode is null then 1 else 0 end) as geosupport, 
	sum(case when a.zipcode is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'boro' as field,
	sum(case when a.geo_boro is null then 1 else 0 end) as geosupport, 
	sum(case when a.boro is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'cd' as field,
	sum(case when a.geo_cd is null then 1 else 0 end) as geosupport, 
	sum(case when a.cd is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'council' as field,
	sum(case when a.geo_council is null then 1 else 0 end) as geosupport, 
	sum(case when a.council is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'ntacode2010' as field,
	sum(case when a.geo_ntacode2010 is null then 1 else 0 end) as geosupport, 
	sum(case when a.ntacode2010 is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'censusblock2010' as field,
	sum(case when a.geo_censusblock2010 is null then 1 else 0 end) as geosupport, 
	sum(case when a.censusblock2010 is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'censustract2010' as field,
	sum(case when a.geo_censustract2010 is null then 1 else 0 end) as geosupport, 
	sum(case when a.censustract2010 is null then 1 else 0 end) as spatialjoin
	from qc_geom a
union
select
	 'csd' as field,
	sum(case when a.geo_csd is null then 1 else 0 end) as geosupport, 
	sum(case when a.csd is null then 1 else 0 end) as spatialjoin
	from qc_geom a) b;