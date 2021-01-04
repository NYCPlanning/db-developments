---
name: Update
about: Master issue for DevDB releases
title: "{Version, i.e. 20Q4} UPDATE"
labels: ''
assignees: mgraber, SPTKL

---

## Update source data

- [ ] Update version.env to:
```
CAPTURE_DATE=2021-01-03
CAPTURE_DATE_PREV=2020-06-30
DOB_DATA_DATE=2020/01/01
VERSION=20Q4
VERSION_PREV=20Q2
```
### Make sure the following are up-to-date in recipes:
- [ ] `dcp_mappluto`
- [ ] `dof_shoreline` updated with zoningtaxlots, safe to ignore
- [ ] `council_members` [check opendate](https://data.cityofnewyork.us/City-Government/Council-Members/uvw5-9znb)
- [ ] `doitt_buildingfootprints` [check opendata](https://data.cityofnewyork.us/Housing-Development/Building-Footprints/nqwf-w8eh)
- [ ] `doitt_buildingfootprints_historical`[check opendata](https://data.cityofnewyork.us/Housing-Development/Building-Footprints-Historical-Shape/s5zg-yzea)
- [ ] `doitt_zipcodeboundaries` -> never changed, safe to ignore
- [ ] `doe_school_subdistricts` -> received from capital planning
- [ ] `doe_eszones` -> the url for this changes year by year, [search on opendata](https://data.cityofnewyork.us/browse?q=school+zones)
- [ ] `doe_mszones` -> same as above
- [ ] `hpd_hny_units_by_building` [check opendata](https://data.cityofnewyork.us/Housing-Development/Housing-New-York-Units-by-Building/hg8x-zxpr)

**DCP Admin Boundaries from Bytes**
- [ ] `dcp_cdboundaries`
- [ ] `dcp_censusblocks`
- [ ] `dcp_censustracts`
- [ ] `dcp_school_districts`
- [ ] `dcp_boroboundaries_wi`
- [ ] `dcp_councildistricts`
- [ ] `dcp_firecompanies`
- [ ] `dcp_policeprecincts`

**DOB data**
- [ ]  `dob_cofos` -> manually updated, received by email
- [ ]  `dob_jobapplications` [check actions](https://github.com/NYCPlanning/recipes/actions?query=workflow%3A%22DOB+pull+for+HED%22)
- [ ]  `dob_permitissuance` [check actions](https://github.com/NYCPlanning/recipes/actions?query=workflow%3A%22DOB+pull+for+HED%22)
