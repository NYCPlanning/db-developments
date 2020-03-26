# db-developments
Processing DOB Job Application and Certificate of Occupancy data to identify jobs that will increase or decrease the number of units

## Building Preparation:
1. `cd developments_build` navigate to the building directory
2. Set environmental variables in `.env`: `RECIPE_ENGINE`, `BUILD_ENGINE`, and `EDM_DATA`. See .env.example.

## Building Instructions:
1. `./01_dataloading.sh` to load all source data into `BUILD_ENGINE`, which is a postgreSQL server.
2. build and geocode
    - `./02.1_build_devdb.sh` to build developments database
    - `./02.2_geocoding.sh` to geocode developments database
    - `./02.3_build_yoyco.sh` to build yearly units change table based on the certificate of occupancy data
    - `./02.4_build_hny.sh` to pair up each DOB permit with its corresponding HPD/HNY affordable housing projects
3. `./03_export.sh` to export the finished developments database, housing database and yearly units change table
4. `./04_qaqc.sh` to create and output the QC tables
5. `./05_archive.sh` to archive developments DB, housing DB and yearly_unitchange into `EDM_DATA`, which is another postgreSQL server.

##### Output tables:
1. Live output tables are in the `BUILD_ENGINE` under the schemas named `devdb_export`, `housing_export` and `yearly_unitchange`
2. Archived output tables are in the `EDM_DATA` under the schemas named `developments`, `dcp_housing` and `yearly_unitchange`