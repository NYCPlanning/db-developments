from multiprocessing import Pool, cpu_count
from sqlalchemy import create_engine
from geosupport import Geosupport, GeosupportError
from utils import psql_insert_copy
import pandas as pd
import json
import os

g = Geosupport()


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
            "BOROUGH BLOCK LOT (BBL)", "",
        ),
        geo_boro=geo.get("BOROUGH BLOCK LOT (BBL)", {}).get("Borough Code", "",),
        geo_cd=geo.get("COMMUNITY DISTRICT", {}).get("COMMUNITY DISTRICT", ""),
        geo_puma=geo.get("PUMA Code", ""),
        geo_firedivision=geo.get("Fire Division", ""),
        geo_firebattalion=geo.get("Fire Battalion", ""),
        geo_firecompany=geo.get("Fire Company Type", "")
        + geo.get("Fire Company Number", ""),
        geo_censustract2010=geo.get("2010 Census Tract", ""),
        geo_censusblock2010=geo.get("2010 Census Block", ""),
        geo_council=geo.get("City Council District", ""),
        geo_csd=geo.get("Community School District", ""),
        geo_policeprct=geo.get("Police Precinct", ""),
        geo_zipcode=geo.get("ZIP Code", ""),
        geo_ntacode2010=geo.get("Neighborhood Tabulation Area (NTA)", ""),
        # the return codes and messaged are for diagnostic puposes
        grc=geo.get("Geosupport Return Code (GRC)", ""),
        grc2=geo.get("Geosupport Return Code 2 (GRC 2)", ""),
        msg=geo.get("Message", "msg err"),
        msg2=geo.get("Message 2", "msg2 err"),
    )


if __name__ == "__main__":
    # connect to BUILD_ENGINE
    engine = create_engine(os.environ["BUILD_ENGINE"])

    df = pd.read_sql(
        """
        SELECT 
            distinct ogc_fid as uid, 
            housenumber as house_number,
            streetname as street_name, 
            borough
        FROM dob_jobapplications
        """,
        engine,
    )

    records = df.to_dict("records")
    del df

    print("geocoding begins here ...")
    # Multiprocess
    with Pool(processes=cpu_count()) as pool:
        it = pool.map(geocode, records, 10000)

    print("geocoding finished, dumping GEO_devdb postgres ...")
    df=pd.DataFrame(it)
    df.to_sql(
        'dob_geocode_results',
        con=engine,
        if_exists="replace",
        index=False,
        method=psql_insert_copy,
    )