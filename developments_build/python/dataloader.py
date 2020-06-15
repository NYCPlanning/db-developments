from sqlalchemy import create_engine
from cook import Importer
import os
import pandas as pd
import sys

RECIPE_ENGINE = os.environ.get('RECIPE_ENGINE', '')
BUILD_ENGINE=os.environ.get('BUILD_ENGINE', '')
EDM_DATA = os.environ.get('EDM_DATA', '')

def ETL(table):
    importer = Importer(RECIPE_ENGINE, BUILD_ENGINE)
    importer.import_table(schema_name=table)

if __name__ == "__main__":
    table = sys.argv[1]
    ETL(table)