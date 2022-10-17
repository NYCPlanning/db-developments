from multiprocessing import Pool, cpu_count
from sqlalchemy import create_engine
from geosupport import Geosupport, GeosupportError
from python.utils import psql_insert_copy
import pandas as pd
import json
import os
from dotenv import main

main.load_dotenv()

g = Geosupport()


def geocode(hny):
    # collect inputs
    uid = str(hny.get("ogc_fid"))
    hnum = hny.get("number")
    sname = hny.get("street")
    borough = hny.get("borough")

    try:
        geo = g["1B"](
            street_name=sname, house_number=hnum, borough=borough, mode="regular"
        )
        geo = add_geocode(hny, geo)
        geo.update(dict(uid=uid, mode="regular", func="1B", status="success"))
        return geo
    except GeosupportError:
        try:
            geo = g["1B"](
                street_name=sname, house_number=hnum, borough=borough, mode="tpad"
            )
            geo = add_geocode(hny, geo)
            geo.update(dict(uid=uid, mode="tpad", func="1B", status="success"))
            return geo
        except GeosupportError as e:
            geo = add_geocode(hny, e.result)
            geo.update(uid=uid, mode="tpad", func="1B", status="failure")
            return geo


def add_geocode(hny, geo):

    new_fields = dict(
        # Normalized address:
        geo_sname=geo.get("First Street Name Normalized", ""),
        geo_hnum=geo.get("House Number - Display Format", ""),
        # Longitude and latitude of lot center
        geo_latitude=geo.get("Latitude", ""),
        geo_longitude=geo.get("Longitude", ""),
        # Some sample administrative areas:
        geo_bin=geo.get(
            "Building Identification Number (BIN) of Input Address or NAP", ""
        ),
        geo_bbl=geo.get("BOROUGH BLOCK LOT (BBL)", {}).get(
            "BOROUGH BLOCK LOT (BBL)",
            "",
        ),
    )

    return  hny | new_fields

if __name__ == "__main__":
    # connect to postgres db
    engine = create_engine(os.environ["BUILD_ENGINE"])

    # read in housing table
    df = pd.read_sql(
        """
        SELECT * 
        FROM hpd_hny_units_by_building
        WHERE reporting_construction_type = 'New Construction'
        AND project_name <> 'CONFIDENTIAL';
        """,
        engine,
    )

    # get the row number
    df = df.rename(
        columns={
            "latitude_(internal)": "latitude_internal",
            "longitude_(internal)": "longitude_internal",
        }
    )

    records = df.to_dict("records")

    print("Geocoding HNY...")
    # Multiprocess
    with Pool(processes=5) as pool:
        it = pool.map(geocode, records, 1000)
        # it = map(geocode, records)

    print("Geocoding finished, dumping to postgres ...")
    df = pd.DataFrame(it)
    df.to_sql(
        "hny_geocode_results",
        con=engine,
        if_exists="replace",
        index=False,
        method=psql_insert_copy,
    )
