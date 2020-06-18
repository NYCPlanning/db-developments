from sqlalchemy import create_engine
from utils.exporter import exporter
import pandas as pd
import numpy as np
import os

if __name__ == "__main__":
    # connect to postgres db
    engine = create_engine(os.environ["BUILD_ENGINE"])

    df = pd.read_sql("SELECT * FROM yearly_unitchange", engine)
    corr = pd.read_sql(
        "SELECT job_number, field, old_value, new_value\
                        FROM housing_input_research\
                        WHERE job_number IN (\
                            SELECT DISTINCT job_number::TEXT FROM yearly_unitchange\
                        )",
        engine,
    )

    df.rename(columns={"unit_exist_preapr2010": "unit_change_preapr2010"}, inplace=True)
    unit_change = list(filter(lambda x: "unit_change_" in x, list(df.columns)))
    stable_columns = [
        "job_number",
        "job_type",
        "status_q",
        "status",
        "units_init",
        "units_prop",
        "units_net",
        "x_mixeduse",
    ]
    df = df.melt(stable_columns, var_name="field", value_name="value").sort_values(
        by=stable_columns + ["field"]
    )

    df["job_number"] = df.job_number.astype("str")
    df = pd.merge(df, corr, how="left", on=["job_number", "field"])

    df["value"] = np.where(
        (df.value == df.old_value) | (df.old_value == None), df.new_value, df.value
    )
    df = df.reset_index().drop(columns=["index", "old_value", "new_value"])
    df["value"] = df.value.apply(lambda x: "" if x == None else x)
    df = df.set_index(stable_columns + ["field"]).value.unstack().reset_index()

    df = df[stable_columns + unit_change].rename(
        columns={"unit_change_preapr2010": "unit_exist_preapr2010"}
    )

    print("dump into postgres...")
    df.to_sql(
        "yearly_unitchange", engine, if_exists="replace", chunksize=2000, index=False
    )
