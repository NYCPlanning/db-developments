# db-developments
Processing DOB Job Application and Certificate of Occupancy data to identify jobs that will increase or decrease the number of units

## File Download
### Shapefiles
+ [DevDB](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_devdb/EXPORT_devdb.zip)
+ [HousingDB](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_housing/EXPORT_housing.zip)

### CSV
#### All records
+ [DevDB](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_devdb.csv)
+ [HousingDB](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_housing.csv)

#### No geom records
+ [DevDB no geom](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_devdb_nogeom.csv)
+ [HousingDB no geom](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_housing_nogeom.csv)

#### Aggregation tables
+ [block](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_block.csv) |
[tract](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_tract.csv) |
[comunitydist](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_comunitydist.csv) |
[councildist](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_councildist.csv) |
[NTA](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_nta.csv) |
[PUMA](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_puma.csv)

## Building Preparation:
1. `cd developments_build` navigate to the building directory
2. Set environmental variables in `.env`: `RECIPE_ENGINE`, `BUILD_ENGINE`, and `EDM_DATA`. See .env.example.
