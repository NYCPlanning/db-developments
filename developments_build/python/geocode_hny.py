from multiprocessing import Pool, cpu_count
from sqlalchemy import create_engine
from geosupport import Geosupport, GeosupportError
from utils.exporter import exporter
import pandas as pd
import json
import os

g = Geosupport()


def geocode(input):
    # collect inputs
    uid = input.pop("ogc_fid")
    hnum = input.pop("number")
    sname = input.pop("street")
    borough = input.pop("borough")

    try:
        geo1 = g["AP"](
            street_name=sname, house_number=hnum, borough=borough, mode="regular"
        )
        geo2 = g["1B"](
            street_name=sname, house_number=hnum, borough=borough, mode="regular"
        )
        geo2.pop("Longitude")
        geo2.pop("Latitude")
        geo = {**geo1, **geo2}
        geo = parse_output(geo)
        geo.update(dict(uid=uid, mode="regular", func="AP+1B", status="success"))
        return geo
    except GeosupportError:
        try:
            geo = g["1B"](
                street_name=sname, house_number=hnum, borough=borough, mode="tpad"
            )
            geo = parse_output(geo)
            geo.update(dict(uid=uid, mode="tpad", func="1B", status="success"))
            return geo
        except GeosupportError as e:
            geo = parse_output(e.result)
            geo.update(uid=uid, mode="tpad", func="1B", status="failure")
            return geo


def parse_output(geo):
    return dict(
        # Normalized address:
        geo_sname=geo.get("First Street Name Normalized", ""),
        geo_hnum=geo.get("House Number - Display Format", ""),
        # boro = geo.get('First Borough Name', ''),
        # longitude and latitude of lot center
        geo_latitude=geo.get("Latitude", ""),
        geo_longitude=geo.get("Longitude", ""),
        # Some sample administrative areas:
        geo_bin=geo.get(
            "Building Identification Number (BIN) of Input Address or NAP", ""
        ),
        geo_bbl=geo.get("BOROUGH BLOCK LOT (BBL)", {}).get(
            "BOROUGH BLOCK LOT (BBL)", "",
        ),
    )


if __name__ == "__main__":
    # connect to postgres db
    engine = create_engine(os.environ["BUILD_ENGINE"])

    # read in housing table
    df1 = pd.read_sql(
        """
        SELECT * 
        FROM hpd_hny_units_by_building
        WHERE reporting_construction_type = 'New Construction'
        AND project_name <> 'CONFIDENTIAL';
        """,
        engine,
    )

    df2 = pd.read_sql(
        """
        SELECT * 
        FROM housing_input_hny_job_manual;
        """,
        engine,
    )

    # get the row number
    df1 = df1.rename(
        columns={
            "latitude_(internal)": "latitude_internal",
            "longitude_(internal)": "longitude_internal",
        }
    )

    records1 = df1.to_dict("records")
    records2 = df2.to_dict("records")

    # records = geocode(records)

    print("geocoding begins here ...")
    # Multiprocess
    with Pool(processes=cpu_count()) as pool:
        it1 = pool.map(geocode, records1, 10000)

    with Pool(processes=cpu_count()) as pool:
        it2 = pool.map(geocode, records2, 10000)

    print("geocoding finished, dumping tp postgres ...")
    exporter(df=pd.DataFrame(it1), table_name="hny_geocode_results", con=engine)
    exporter(df=pd.DataFrame(it2), table_name="hny_manual_geocode_results", con=engine)
