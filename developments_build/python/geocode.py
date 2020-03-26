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
                sname = geo.get('First Street Name Normalized', ''),
                hnum = geo.get('House Number - Display Format', ''),
                boro = geo.get('First Borough Name', ''),
                
                # longitude and latitude of lot center
                lat = geo.get('Latitude', ''),
                lon = geo.get('Longitude', ''),
                
                # Some sample administrative areas: 
                BIN = geo.get('Building Identification Number (BIN) of Input Address or NAP',''),
                BBL = geo.get('BOROUGH BLOCK LOT (BBL)', {}).get('BOROUGH BLOCK LOT (BBL)', '',),
                bcode = geo.get('BOROUGH BLOCK LOT (BBL)', {}).get('Borough Code', '',),
                cd = geo.get('COMMUNITY DISTRICT', {}).get('COMMUNITY DISTRICT', ''),
                ct = geo.get('2010 Census Tract', ''),
                cblock = geo.get('2010 Census Block', ''),
                ctract = geo.get('2010 Census Tract', ''),
                council = geo.get('City Council District', ''),
                csd = geo.get('Community School District', ''),
                policeprct = geo.get('Police Precinct', ''),
                zipcode = geo.get('ZIP Code', ''), 
                nta = geo.get('Neighborhood Tabulation Area (NTA)', ''),
                ntan = geo.get('NTA Name', ''),

                # the return codes and messaged are for diagnostic puposes
                GRC = geo.get('Geosupport Return Code (GRC)', ''),
                GRC2 = geo.get('Geosupport Return Code 2 (GRC 2)', ''),
                msg = geo.get('Message', 'msg err'),
                msg2 = geo.get('Message 2', 'msg2 err'),
            )

if __name__ == '__main__':
    # connect to postgres db
    engine = create_engine(os.environ['BUILD_ENGINE'])

    # read in housing table
    df = pd.read_sql("SELECT job_number, job_number||status_date AS uid, address_house, address_street, boro,\
                        co_earliest_effectivedate, status_q, status_a, x_outlier\
                                      FROM developments;", engine)

    #get the row number
    df = df.rename(columns={'address_house':'house_number', 
                            'address_street':'street_name',
                            'boro':'borough'})

    records = df.to_dict('records')
    
    print('** Geosupport calls begins here **')
    # Multiprocess
    with Pool(processes=cpu_count()) as pool:
        it = pool.map(geocode, records, 10000)
    
    print('** Geocoding finished, dumping to postgres **')
    exporter(df=pd.DataFrame(it), table_name='development_tmp', con=engine)