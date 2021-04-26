from sqlalchemy import create_engine
from cook import Importer
import os
import pandas as pd
from utils import psql_insert_copy

RECIPE_ENGINE = os.environ.get("RECIPE_ENGINE", "")
BUILD_ENGINE = os.environ.get("BUILD_ENGINE", "")

def dob_cofos():
    recipe_engine = create_engine(RECIPE_ENGINE)
    build_engine = create_engine(BUILD_ENGINE)
    table_names = [record[0] for record in recipe_engine.execute(
        '''
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'dob_cofos' and table_type = 'BASE TABLE'
        '''
    )]
    template = '''
        SELECT 
            '{0}' as v,
            jobnum,
            effectivedate,
            bin,
            boroname,
            housenumber,
            streetname,
            block,
            lot,
            numofdwellingunits,
            occupancyclass,
            certificatetype,
            buildingtypedesc,
            docstatus
        FROM dob_cofos."{0}"
    '''
    query = ' UNION '.join([template.format(tb_name) for tb_name in table_names])
    df=pd.read_sql(query, recipe_engine).to_sql(
        'dob_cofos',
        con=build_engine,
        if_exists="replace",
        index=False,
        method=psql_insert_copy,
    )

if __name__ == "__main__":
    dob_cofos()
