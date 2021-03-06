# db-developments
Processing DOB Job Application and Certificate of Occupancy data to identify jobs that will increase or decrease the number of units

## Instructions:
1. `cd developments_build` navigate to the building directory
2. Set environmental variables in `.env`: `RECIPE_ENGINE`, `BUILD_ENGINE`, and `EDM_DATA`. See .env.example.

## Development File Download
> Note that these files are not official releases, they are provided for QAQC purposes only, for official releases, please checkout [Bytes of the Big Apple](https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-housing-database.page#housingdevelopmentproject)

#### Main Tables
  | Devdb | HousingDB
-- | -- | --
CSV | [EXPORT_devdb.csv](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_devdb.csv) | [EXPORT_housing.csv](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/EXPORT_housing.csv)
Shapefile | [SHP_devdb.zip](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/SHP_devdb/SHP_devdb.zip) | [SHP_housing.zip](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/SHP_housing/SHP_housing.zip)

#### Aggregation Tables
[block](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_block.csv) |
[tract](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_tract.csv) |
[commntydst](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_commntydst.csv) |
[councildst](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_councildst.csv) |
[NTA](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_nta.csv) |
[PUMA](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/aggregate_puma.csv)

#### All files [bundle.zip](https://edm-publishing.nyc3.digitaloceanspaces.com/db-developments/latest/output/output.zip)

## Published Versions
<details><summary>20Q4</summary>
  
    | HousingDB | Devdb
 -- | -- | --
CSV        | [dcp_housing.csv](https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dcp_housing/20Q4/dcp_housing.csv) | [dcp_developments.csv](https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dcp_developments/20Q4/dcp_developments.csv)
Zipped CSV | [dcp_housing.csv](https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dcp_housing/20Q4/dcp_housing.csv.zip)  |  [dcp_developments.csv.zip](https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dcp_developments/20Q4/dcp_developments.csv.zip)
Shapefile  |  [dcp_housing.shp.zip](https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dcp_housing/20Q4/dcp_housing.shp.zip) | [dcp_developments.shp.zip](https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dcp_developments/20Q4/dcp_developments.shp.zip)
  
</details>


