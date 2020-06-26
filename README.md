# db-developments
Processing DOB Job Application and Certificate of Occupancy data to identify jobs that will increase or decrease the number of units

## File Download
### Main Tables
  | Devdb | HousingDB
-- | -- | --
CSV | [EXPORT_devdb.csv](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_devdb.csv) | [EXPORT_housing.csv](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_housing.csv)
Shapefile | [SHP_devdb.zip](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/SHP_devdb/SHP_devdb.zip) | [SHP_housing.zip](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/SHP_housing/SHP_housing.zip)

### Aggregation Tables
[block](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_block.csv) |
[tract](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_tract.csv) |
[comunitydist](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_comunitydist.csv) |
[councildist](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_councildist.csv) |
[NTA](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_nta.csv) |
[PUMA](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_puma.csv)

### All files [bundle.zip](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/output.zip)

## Building Preparation:
1. `cd developments_build` navigate to the building directory
2. Set environmental variables in `.env`: `RECIPE_ENGINE`, `BUILD_ENGINE`, and `EDM_DATA`. See .env.example.
