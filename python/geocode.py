from multiprocessing import Pool, cpu_count
from sqlalchemy import create_engine
from geosupport import Geosupport, GeosupportError
from python.utils import psql_insert_copy
import pandas as pd
import os
from dotenv import main

main.load_dotenv()

g = Geosupport()

OUTPUT_TABLE_NAME = "_init_geocoded"


def geocode(input):
    # collect inputs
    uid = input.get("uid", "")
    hnum = input.get("house_number", "")
    sname = input.get("street_name", "")
    borough = input.get("borough", "")

    try:
        geo = g["1B"](
            street_name=sname, house_number=hnum, borough=borough, mode="regular"
        )
        geo = parse_output(geo)
        geo.update(dict(uid=uid, mode="regular", func="1B", status="success"))
    except GeosupportError:
        try:
            geo = g["1B"](
                street_name=sname, house_number=hnum, borough=borough, mode="tpad"
            )
            geo = parse_output(geo)
            geo.update(dict(uid=uid, mode="tpad", func="1B", status="success"))
        except GeosupportError as e:
            geo = parse_output(e.result)
            geo.update(uid=uid, mode="tpad", func="1B", status="failure")

    geo.update(input)
    return geo


def parse_output(geo):
    return dict(
        # Normalized address:
        geo_address_street=geo.get("First Street Name Normalized", ""),
        geo_address_numbr=geo.get("House Number - Display Format", ""),
        # longitude and latitude of lot center
        latitude=geo.get("Latitude", ""),
        longitude=geo.get("Longitude", ""),
        # Some sample administrative areas:
        geo_bin=geo.get(
            "Building Identification Number (BIN) of Input Address or NAP", ""
        ),
        geo_bbl=geo.get("BOROUGH BLOCK LOT (BBL)", {}).get(
            "BOROUGH BLOCK LOT (BBL)",
            "",
        ),
        geo_boro=geo.get("BOROUGH BLOCK LOT (BBL)", {}).get(
            "Borough Code",
            "",
        ),
        geo_cd=geo.get("COMMUNITY DISTRICT", {}).get("COMMUNITY DISTRICT", ""),
        geo_firedivision=geo.get("Fire Division", ""),
        geo_firebattalion=geo.get("Fire Battalion", ""),
        geo_firecompany=geo.get("Fire Company Type", "")
        + geo.get("Fire Company Number", ""),
        geo_council=geo.get("City Council District", ""),
        geo_csd=geo.get("Community School District", ""),
        geo_policeprct=geo.get("Police Precinct", ""),
        geo_zipcode=geo.get("ZIP Code", ""),
        geo_nta2010=geo.get("Neighborhood Tabulation Area (NTA)", None),
        geo_nta2020=geo.get("2020 Neighborhood Tabulation Area (NTA)", None),
        geo_ct2010=geo.get("2010 Census Tract", None),
        geo_ct2020=geo.get("2020 Census Tract", None),
        geo_cb2010=geo.get("2010 Census Block", None),
        geo_cb2020=geo.get("2020 Census Block", None),
        geo_cdta2020=geo.get("2020 Community District Tabulation Area (CDTA)", None),
        # the return codes and messaged are for diagnostic puposes
        grc=geo.get("Geosupport Return Code (GRC)", ""),
        grc2=geo.get("Geosupport Return Code 2 (GRC 2)", ""),
        msg=geo.get("Message", "msg err"),
        msg2=geo.get("Message 2", "msg2 err"),
    )


def load_init_devdb(engine):
    df = pd.read_sql(
        """
        SELECT 
            uid, 
            job_number, 
            address_numbr as house_number,
            REGEXP_REPLACE(address_street, '[\s]{2,}' ,' ' , 'g') as street_name, 
            boro as borough
        FROM _INIT_devdb 
        """,
        engine,
    )
    print("loaded df from database")
    return df


def geocode_insert_sql(records, engine):

    # Multiprocess
    with Pool(processes=cpu_count()) as pool:
        it = pool.map(geocode, records, len(records) // 4)

    df = pd.DataFrame(it)
    df.replace({"latitude": {"": None}, "longitude": {"": None}}, inplace=True)
    df.to_sql(
        OUTPUT_TABLE_NAME,
        con=engine,
        if_exists="append",
        index=False,
    )


def clear_dob_geocode_results(engine):
    engine.execute(f"DROP TABLE IF EXISTS {OUTPUT_TABLE_NAME}")


if __name__ == "__main__":
    # connect to BUILD_ENGINE
    engine = create_engine(os.environ["BUILD_ENGINE"])

    clear_dob_geocode_results(engine)

    df = load_init_devdb(engine)
    records = df.to_dict("records")

    del df
    start = 0
    chunk_size = 10**4
    end = min(chunk_size, len(records))
    while start < len(records):
        print(f"geocoding records {start} through {end}")
        geocode_insert_sql(records[start:end], engine)
        start = end
        end = min(end + chunk_size, len(records))
