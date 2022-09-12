import pandas as pd
import sys
from sqlalchemy import create_engine

template_lookup = {
    "CDTA": "cdta2020",
    "CensusBlocks": "",
    "CensusTracts": "",
    "CityCouncil": "",
    "CommunityDistricts": "",
    "NTA": "",
}

BUILD_ENGINE = sys.argv[1]


def read_aggregate_template(name: str):
    base = pd.read_csv(f"data/agg_template/{name}.csv")
    base.set_index(template_lookup[name], inplace=True)
    return base


if __name__ == "__main__":

    table = sys.argv[2]
    engine = create_engine(BUILD_ENGINE)

    base = read_aggregate_template(table)
    df = pd.read_sql("""SELECT * FROM """, con=engine)

    final = pd.concat([base, df], axis=1)
