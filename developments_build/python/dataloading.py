from sqlalchemy import create_engine
from cook import Importer
import os
import pandas as pd
from multiprocessing import Pool, cpu_count
from utils.exporter import exporter

RECIPE_ENGINE = os.environ.get("RECIPE_ENGINE", "")
BUILD_ENGINE = os.environ.get("BUILD_ENGINE", "")
EDM_DATA = os.environ.get("EDM_DATA", "")


def ETL(table):
    importer = Importer(RECIPE_ENGINE, BUILD_ENGINE)
    importer.import_table(schema_name=table)


tables = [
    "dof_shoreline",
    "council_members",
    "dcp_mappluto",
    "doitt_buildingfootprints",
    "doitt_buildingfootprints_historical",
    "doitt_zipcodeboundaries",
    "dcp_ntaboundaries",
    "dcp_cdboundaries",
    "dcp_censusblocks",
    "dcp_censustracts",
    "dcp_school_districts",
    "dcp_boroboundaries_wi",
    "dcp_councildistricts",
    "dcp_puma",
    "dcp_firecompanies",
    "doe_school_subdistricts",
    "doe_eszones",
    "doe_mszones",
    "dcp_policeprecincts",
    "hpd_hny_units_by_building",
    "hpd_hny_units_by_project",
    "housing_input_hny_job_manual"
]


def dcp_mappluto():
    recipe_engine = create_engine(RECIPE_ENGINE)
    build_engine = create_engine(BUILD_ENGINE)

    df = pd.read_sql(
        """
        SELECT 
            b.version,
            b.bbl::numeric::bigint::text,
            b.unitsres,
            b.bldgarea,
            b.comarea,
            b.officearea,
            b.retailarea,
            b.resarea,
            b.yearbuilt,
            b.yearalter1,
            b.yearalter2,
            b.bldgclass,
            b.landuse,
            b.ownertype,
            b.ownername,
            b.condono,
            b.numbldgs,
            b.numfloors,
            b.firm07_fla,
            b.pfirm15_fl,
            b.wkb_geometry
        FROM dcp_mappluto.latest b
        """,
        recipe_engine,
    )
    exporter(df=df, table_name="dcp_mappluto", sep="|", con=build_engine)
    build_engine.execute(
        """
        ALTER TABLE dcp_mappluto 
        ALTER COLUMN wkb_geometry TYPE Geometry USING ST_SetSRID(ST_GeomFromText(ST_AsText(wkb_geometry)), 4326);
        """
    )
    del df


def dob_jobapplications():

    recipe_engine = create_engine(RECIPE_ENGINE)
    build_engine = create_engine(BUILD_ENGINE)

    df = pd.read_sql(
        """
        SELECT * 
        FROM dob_jobapplications.latest
        WHERE jobdocnumber = '01'
		AND jobtype ~* 'A1|DM|NB'
        """,
        recipe_engine,
    )

    exporter(df=df, table_name="dob_jobapplications", con=build_engine)
    del df


def dob_permitissuance():
    recipe_engine = create_engine(RECIPE_ENGINE)
    build_engine = create_engine(BUILD_ENGINE)

    df = pd.read_sql(
        """
        SELECT 
            v,
            jobnum,
            jobdocnum,
            jobtype,
            issuancedate
        FROM dob_permitissuance.latest
        WHERE jobdocnum = '01'
        AND jobtype ~* 'A1|DM|NB'
        """,
        recipe_engine,
    )

    exporter(df=df, table_name="dob_permitissuance", con=build_engine)
    del df


def dob_cofos():
    recipe_engine = create_engine(RECIPE_ENGINE)
    build_engine = create_engine(BUILD_ENGINE)
    df = pd.read_sql(
        """
        SELECT
            v,
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
        FROM dob_cofos.latest
        UNION
        SELECT 
            NULL as v,
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
        FROM dob_cofos.append
        """,
        recipe_engine,
    )
    exporter(df=df, table_name="dob_cofos", con=build_engine)
    del df


# def old_developments():
#     importer = Importer(EDM_DATA, BUILD_ENGINE)
#     importer.import_table(schema_name='developments', version="2019/09/10")

if __name__ == "__main__":
    with Pool(processes=cpu_count()) as pool:
        pool.map(ETL, tables)

    dob_cofos()
    dob_jobapplications()
    dob_permitissuance()
