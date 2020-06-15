from sqlalchemy import create_engine
from cook import Importer
import os
import pandas as pd
from multiprocessing import Pool, cpu_count

RECIPE_ENGINE = os.environ.get('RECIPE_ENGINE', '')
BUILD_ENGINE=os.environ.get('BUILD_ENGINE', '')
EDM_DATA = os.environ.get('EDM_DATA', '')

def ETL(table):
    importer = Importer(RECIPE_ENGINE, BUILD_ENGINE)
    importer.import_table(schema_name=table)


large_tables = ['dob_permitissuance',
                'dob_jobapplications',
                'dob_cofos',
                'dof_dtm',
                'dcp_mappluto',
                'doitt_buildingfootprints',
                'doitt_zipcodeboundaries']

small_tables = ['housing_input_lookup_occupancy',
                'housing_input_lookup_status',
                'housing_input_research',
                'dcp_ntaboundaries',
                'dcp_cdboundaries',
                'dcp_censusblocks',
                'dcp_censustracts',
                'dcp_school_districts',
                'dcp_boroboundaries_wi',

                'dcp_councildistricts',
                'dcp_firecompanies',
                'doe_school_subdistricts',
                'doe_eszones',
                'doe_mszones',

                'dcp_policeprecincts',
                'housing_input_hny_job_manual',
                'hpd_hny_units_by_building',
                'hpd_hny_units_by_project',
                'housing_input_hny']

if __name__ == "__main__":
    with Pool(processes=cpu_count()) as pool:
            pool.map(ETL, small_tables)