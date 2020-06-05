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
    uid = input.pop('uid')
    hnum = input.pop('house_number')
    sname = input.pop('street_name')
    borough = input.pop('borough')

    try: 
        geo1 = g['AP'](street_name=sname, house_number=hnum, borough=borough, mode='regular')
        geo2 = g['1B'](street_name=sname, house_number=hnum, borough=borough, mode='regular')
        geo2.pop('Longitude')
        geo2.pop('Latitude')
        geo = {**geo1, **geo2}
        geo = parse_output(geo)
        geo.update(dict(uid=uid, mode='regular', func='AP+1B', status='success'))
    except GeosupportError:
        try: 
            geo = g['1B'](street_name=sname, house_number=hnum, borough=borough, mode='tpad')
            geo = parse_output(geo)
            geo.update(dict(uid=uid, mode='tpad', func='1B', status='success'))
        except GeosupportError as e:
            geo = parse_output(e.result)
            geo.update(uid=uid, mode='tpad', func='1B', status='failure')

    geo.update(input)
    return geo

def parse_output(geo):
    return dict(
        # Normalized address: 
        geo_address_street = geo.get('First Street Name Normalized', ''),
        geo_address_house = geo.get('House Number - Display Format', ''),
        
        # longitude and latitude of lot center
        latitude = geo.get('Latitude', ''),
        longitude = geo.get('Longitude', ''),
        
        # Some sample administrative areas: 
        geo_bin = geo.get('Building Identification Number (BIN) of Input Address or NAP',''),
        geo_bbl = geo.get('BOROUGH BLOCK LOT (BBL)', {})\
                    .get('BOROUGH BLOCK LOT (BBL)', '',),
        geo_boro = geo.get('BOROUGH BLOCK LOT (BBL)', {})\
                    .get('Borough Code', '',),
        geo_cd = geo.get('COMMUNITY DISTRICT', {})\
                    .get('COMMUNITY DISTRICT', ''),
        geo_censustract2010 = geo.get('2010 Census Tract', ''),
        geo_censusblock2010 = geo.get('2010 Census Block', ''),
        geo_council = geo.get('City Council District', ''),
        geo_csd = geo.get('Community School District', ''),
        geo_policeprct = geo.get('Police Precinct', ''),
        geo_zipcode = geo.get('ZIP Code', ''), 
        geo_ntacode2010 = geo.get('Neighborhood Tabulation Area (NTA)', ''),

        # the return codes and messaged are for diagnostic puposes
        GRC = geo.get('Geosupport Return Code (GRC)', ''),
        GRC2 = geo.get('Geosupport Return Code 2 (GRC 2)', ''),
        msg = geo.get('Message', 'msg err'),
        msg2 = geo.get('Message 2', 'msg2 err')
    )

if __name__ == '__main__':
    # connect to BUILD_ENGINE
    engine = create_engine(os.environ['BUILD_ENGINE'])

    df = pd.read_sql('''
        SELECT 
            distinct uid, 
            address_house as house_number,
            address_street as street_name, 
            boro as borough
        FROM _INIT_devdb
    ''', engine)

    records = df.to_dict('records')
    
    print('geocoding begins here ...')
    # Multiprocess
    with Pool(processes=cpu_count()) as pool:
        it = pool.map(geocode, records, 10000)
    
    print('geocoding finished, dumping GEO_devdb postgres ...')
    exporter(df=pd.DataFrame(it), table_name='GEO_devdb', con=engine)