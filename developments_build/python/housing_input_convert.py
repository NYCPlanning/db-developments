from sqlalchemy import create_engine
from utils.exporter import exporter
import pandas as pd
import numpy as np
import os


def rename_field(c):
    if c == "dcp_occ_category":
        return "occ_category"
    if c == "dcp_occ_pr":
        return "occ_prop"
    if c == "prop_stories":
        return "stories_prop"
    if c == "u_net_comp":
        return "units_complete"
    if c == "u_net_inc":
        return "units_incomplete"
    else:
        return c


if __name__ == "__main__":
    # connect to postgres db
    engine = create_engine(os.environ["BUILD_ENGINE"])

    df = pd.read_sql("SELECT * FROM housing_input_dcpattributes", engine)
    old_dev = pd.read_sql(
        "SELECT job_number, bbl, bin, units_net,\
                            units_complete AS u_net_comp, units_incomplete AS u_net_inc,\
                            units_prop, occ_prop AS dcp_occ_pr, occ_init,\
                            stories_prop AS prop_stories, occ_category AS dcp_occ_category,\
                            x_mixeduse, latitude, longitude, x_inactive\
                            FROM developments_wo_manual\
                            WHERE job_number IN (\
                                SELECT DISTINCT job_number FROM housing_input_dcpattributes\
                            )",
        engine,
    )
    yearly_unitschange = pd.read_sql(
        "SELECT *, unit_exist_preapr2010 AS unit_change_preapr2010\
                             FROM yearly_unitchange_wo_manual\
                             WHERE job_number::TEXT IN (\
                                SELECT DISTINCT job_number FROM housing_input_dcpattributes\
                            )",
        engine,
    )

    print("melting old DevDB...")
    df = df[df.reason != "HNY manual match"].drop(
        columns=["ogc_fid", "v", "hny_id", "extra"]
    )
    df = df.melt(
        ["job_number", "reason"], var_name="field", value_name="new_value"
    ).sort_values(by=["job_number", "field"])
    df = df[~df.new_value.isna()]

    # drop duplications
    df = df.drop_duplicates(subset=["job_number", "field"], keep="last")
    df["edited_date"] = "2019/08/13"

    print("melting old DevDB without correction...")
    old_dev = old_dev.melt(
        "job_number", var_name="field", value_name="old_value"
    ).sort_values(by=["job_number", "old_value"])
    old_dev = old_dev[~old_dev.old_value.isna()]

    print("melting old yearly_unitschange without correction...")
    unit_change = list(
        filter(lambda x: "unit_change_" in x, list(yearly_unitschange.columns))
    )[1:]
    yearly_unitschange = yearly_unitschange[["job_number"] + unit_change]
    yearly_unitschange = yearly_unitschange.melt(
        "job_number", var_name="field", value_name="old_value"
    ).sort_values(by=["job_number", "old_value"])
    yearly_unitschange = yearly_unitschange[~yearly_unitschange.old_value.isna()]

    # merge the research table with old_developments
    old_value = old_dev.append(yearly_unitschange)
    df = pd.merge(df, old_value, how="left", on=["job_number", "field"])
    df = df[["job_number", "field", "old_value", "new_value", "reason", "edited_date"]]
    df = df[df.new_value != df.old_value]

    df["field"] = df.field.apply(lambda x: rename_field(x))

    print("dump into postgres...")
    exporter(df=df, table_name="housing_input_research", con=engine)
    df.to_csv("data/housing_input_research.csv", index=False)
