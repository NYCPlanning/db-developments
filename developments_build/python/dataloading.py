from sqlalchemy import create_engine
from cook import Importer
import os
import pandas as pd
from utils.exporter import exporter
from multiprocessing import Pool, cpu_count

RECIPE_ENGINE = os.environ.get('RECIPE_ENGINE', '')
BUILD_ENGINE=os.environ.get('BUILD_ENGINE', '')
EDM_DATA = os.environ.get('EDM_DATA', '')

def ETL(schema_name):
    importer = Importer(RECIPE_ENGINE, BUILD_ENGINE)
    if schema_name == 'dob_cofos_append':
        dob_cofos_append()
    elif schema_name == 'developments':
        old_developments()
    else: 
        importer.import_table(schema_name=schema_name)

def dob_cofos_append():
    df = pd.read_sql("SELECT * FROM dob_cofos.append", create_engine(RECIPE_ENGINE))
    exporter(df, 'dob_cofos_append', con=create_engine(BUILD_ENGINE))

def old_developments():
    importer = Importer(EDM_DATA, BUILD_ENGINE)
    importer.import_table(schema_name='developments', version="2019/09/10")

if __name__ == "__main__":
    tables = ['dob_permitissuance',
            'dob_jobapplications',
            'dob_cofos',
            'housing_input_lookup_occupancy',
            'housing_input_lookup_status',
            'housing_input_research',
            'dof_dtm',
            'dcp_mappluto',
            'doitt_buildingfootprints',
            'dcp_ntaboundaries',
            'dcp_cdboundaries',
            'dcp_censusblocks',
            'dcp_censustracts',
            'dcp_school_districts',
            'dcp_boroboundaries_wi',
            'doitt_zipcodeboundaries',
            'dcp_councildistricts',
            'housing_input_hny_job_manual',
            'hpd_hny_units_by_building',
            'hpd_hny_units_by_project',
            'housing_input_hny',
            'developments',
            'dob_cofos_append']

    with Pool(processes=cpu_count()) as pool:
        pool.map(ETL, tables)