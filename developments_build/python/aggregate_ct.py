from sqlalchemy import create_engine
from utils.exporter import exporter
import pandas as pd
import numpy as np
import os
import datetime as dt

def get_year(x):
    if (x.year<2010)|((x.year==2010)&(x.month<4)):
        return 'preapr2010'
    elif (x.year==2010)&(x.month>=4):
        return 'postapr2010'
    return 'y' + str(x.year)

if __name__ == '__main__':
    # connect to postgres db
    engine = create_engine(os.environ['BUILD_ENGINE'])
    df1 = pd.read_sql("	SELECT a.*, b.geo_censustract2010 AS ct2010, b.geo_boro AS boro\
                        FROM yearly_unitchange a\
                        LEFT JOIN developments_yoyco b\
                        ON a.job_number::TEXT = b.job_number\
                        WHERE geo_censustract2010 != '000000'", engine)

    unit_change = list(filter(lambda x: 'unit_change_' in x, list(df1.columns)))[1:]
    df1 = df1[['unit_exist_preapr2010','unit_change_postapr2010']+unit_change+['boro','ct2010']]
    year = list(map(lambda x: 'y' + x[len('unit_change_'):], unit_change))
    df1.columns = ['preapr2010','postapr2010']+year+['boro','ct2010']
    df1 = df1.groupby(['boro','ct2010']).sum().reset_index()
    df1['status'] = 'Complete'

    df2 = pd.read_sql(" SELECT job_number, geo_censustract2010 AS ct2010,\
                        geo_boro AS boro, units_net::INTEGER,\
                        status_a\
                        FROM developments_yoyco\
                        WHERE status = 'Filed'\
                        OR status = 'Permit issued'\
                        OR status = 'In progress'\
                        AND geo_censustract2010 != '000000';", engine)
    df2['status_a'] = pd.to_datetime(df2['status_a'])
    df2['year'] = df2.status_a.apply(lambda x: get_year(x))
    df2 = df2.groupby(['boro', 'ct2010', 'year']).units_net.sum().unstack(fill_value=0).reset_index()
    df2['status'] = 'Permited'
    
    df = df1.append(df2, sort=False)
    df = df[df.ct2010!='000000']
    df.rename(columns={'postapr2010':'pstapr2010'}, inplace = True)
    
    print('dumping to postgres...')
    exporter(df=df, table_name='qc_aggregate_ct', con=engine)