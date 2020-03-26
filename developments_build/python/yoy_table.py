from utils.exporter import exporter
import pandas as pd
import sqlalchemy as sql
import numpy as np
from datetime import datetime
from pathlib import Path
import os


def coalesce(df, years):
    """Fills [df]'s null values with the previous's years value."""
    for i, year in enumerate(years[1:]):
        # is null of every dev for the current year
        is_null = df[year].isnull()

        previous_year = years[i]

        # Assign the current years null values to the previous years unit values
        df.loc[is_null, year] = df.loc[is_null, previous_year]
    return df


def fill_years(df, years, value):
    """Fills each year column in [df] with [value]. If [value] is == 'units_net' 
    then fill with 'units_net' of the job, if not, fill with [value]."""
    for i, year in enumerate(years):
        # Account for pre and post Census
        if ('2010' in year):
            census_cut_off_date = pd.to_datetime('04/01/2010')

            if (year == 'unit_change_2010_a_PreCensus'):
                is_in_year = (df['status_q'] < census_cut_off_date) & (
                    df['status_q'] >= pd.to_datetime('01/01/2010'))
            else:
                is_in_year = (df['status_q'] >= census_cut_off_date) & (
                    df['status_q'] < pd.to_datetime('01/01/2011'))
        else:
            year_str = year.replace('unit_change_', '')
            is_in_year = df['status_q'].dt.strftime(
                '%Y') == year_str

        # Fill the column with [value]
        if value == 'units_net':
            df.loc[is_in_year, year] = df.loc[is_in_year, 'units_net']
        else:
            df.loc[is_in_year, year] = value
    return df


def create_cofo_year_column(row):
    date = row['effectivedate']
    census_cut_off_date = pd.to_datetime('04/01/2010')

    if date.year == 2010:
        if date < census_cut_off_date and date >= pd.to_datetime('01/01/2010'):
            return '2010_a_PreCensus'
        elif date >= census_cut_off_date and date < pd.to_datetime('01/01/2011'):
            return '2010_b_PostCensus'
    else:
        return str(date.year)

def init_developments():
    """Loads certificate of occupancy and developments tables from postgress 
        into DataFrames."""
    print("Loading the tables from postgres...")

    sql_engine = sql.create_engine(os.environ['BUILD_ENGINE'])

    # Load developments
    relevant_columns = ['status_q', 'job_number', 'units_init',
                        'status', 'job_type', 'units_prop', 'units_net', 'x_mixeduse']

    query = "select {} from developments_yoyco ".format(", ".join(relevant_columns))
    developments = pd.read_sql_query(query, sql_engine)

    developments['status_q'] = pd.to_datetime(developments['status_q'])

    # Load certificate of occupancy data
    query = "select * from developments_co"
    developments_co = pd.read_sql_query(query, sql_engine)

    developments_co['effectivedate'] = pd.to_datetime(
        developments_co['effectivedate'])

    # Drop cofos that do not have a units value.
    developments_co = developments_co.dropna(subset=['units'])
    developments_co['units'] = developments_co['units'].astype(int)

    # Make sure effectivedates are not in the future
    developments_co = developments_co[developments_co['effectivedate'] <= pd.Timestamp.now(
    )]

    # Make cofo_year
    developments_co['cofo_year'] = developments_co.apply(
        create_cofo_year_column, axis=1)

    print(set(developments_co['effectivedate'].dt.year))

    print("Finished loading the tables from postgres\n")

    return developments, developments_co, sql_engine


def calculate_yearly_unit_totals(developments_co):
    """Creates a DataFrame of unit values for each year for a given job."""
    job_groups = []

    print("Creating yearly unit totals...")
    for i, job in enumerate(developments_co.groupby('job_number')):
        row = job[1]

        max_units = row.groupby('cofo_year')['units'].max()

        max_units['job_number'] = job[0]

        job_groups.append(max_units.to_dict())

        if (i % 1000 == 0):
            print(i)

    print("Done creating yearly unit totals\n")

    # Convert the dictionary of job_ids :  cofos to a dataframe
    df_job_groups = pd.DataFrame(job_groups)

    cofo_years = set(developments_co['cofo_year'])
    column_name_dict = {year: 'unit_change_' + year for year in cofo_years}

    df_job_groups = df_job_groups.rename(columns=column_name_dict)
    
    return df_job_groups

def new_building_unit_correction(developments):
    years = list(filter(lambda x: 'unit_change_' in x, list(developments)))
    
    is_new_building = developments['job_type'] == 'New Building'
    
    new_building_developments = developments[is_new_building]

    for i in range(len(years) - 1):
        current_year = years[i]
        next_year = years[i+1]

        current_year_greater = (new_building_developments[current_year].astype('float') > new_building_developments[next_year].astype('float'))
        new_building_developments.loc[current_year_greater, current_year] = new_building_developments.loc[current_year_greater, next_year]
    
    developments[is_new_building] = new_building_developments
    return developments

def clean_up():
    tmp_path = Path(__file__).parent/'yoyco_tmp.csv'
    os.system(f'rm -r {tmp_path}')

def main():
    """This code is a refactor of the year over year table (YoY) found in the 
    original housing repo (https://github.com/NYCPlanning/db-housing). The goal 
    of the refactor was to remove the hardcoded columns and simplify the logic."""
    developments, developments_co, sql_engine = init_developments()

    # For each job_id, group all of the cofos and grab the max number of units for a given year
    # Original code can be found here: (https://github.com/NYCPlanning/db-housing/blob/master/housing_build/sql/cofos.sql)
    df_job_groups = calculate_yearly_unit_totals(developments_co)

    # Merge the cofo total unit table with developments.
    developments = developments.merge(
        df_job_groups, how='left', on='job_number')
    ############# Fill in values ###############
    # Original code can be found here: (https://github.com/NYCPlanning/db-housing/blob/master/housing_build/sql/cofosfillexisting.sql)
    # If the building was demolished, set the year the job recieved its first
    # partial permit to 0.  If a building was demolished, it should not have any
    # more units in the table.

    is_complete_demolition = developments['status'] == 'Complete (demolition)'
    years = list(df_job_groups.drop('job_number', axis=1))
    developments.loc[is_complete_demolition] = fill_years(
        developments.loc[is_complete_demolition], years, 0)

    # For each year, fill in Null values with the most recent unit count.
    years = list(df_job_groups.drop('job_number', axis=1))
    years = ['units_init'] + years

    developments = coalesce(developments, years)

    developments = new_building_unit_correction(developments)

    ############# Calculate unit change for developments. ###############
    # Do not include alteration developments that do not have a change in units.
    developments[years] = developments[years].fillna(
        value=pd.np.nan).astype(float)

    is_non_alteration_developments = ~(
        (developments['job_type'] == 'Alteration') & (developments['units_net'] == '0'))

    unit_change = developments[years] - \
        developments[years].shift(axis='columns')
    years.remove('units_init')
    developments.loc[is_non_alteration_developments,
                     years] = unit_change.loc[is_non_alteration_developments, years]

    # Do not calculate unit change if a job is an alteration and does not change the number of units
    developments.loc[~is_non_alteration_developments, years] = np.nan

    # If the building was demolished, set the year the job recieved its first
    # partial permit to the net change in units.
    is_demolition = developments['job_type'] == 'Demolition'
    developments.loc[is_demolition] = fill_years(
        developments.loc[is_demolition], years, 'units_net')

    # Rename 2010 census column names.

    developments = developments.rename(columns={
                                       "unit_change_2010_a_PreCensus": "unit_change_preapr2010", "unit_change_2010_b_PostCensus": "unit_change_postapr2010"})

    developments = developments.drop(columns=['unit_change_2007', 'unit_change_2008', 'unit_change_2009'])
    developments = developments.rename(columns={'unit_change_preapr2010': 'unit_exist_preapr2010'})

    developments.to_csv('python/yoyco_tmp.csv')
    developments = pd.read_csv('python/yoyco_tmp.csv')
    clean_up()

    # Remove records that are 0 or NULL for all unit change years
    unit_change_loc = list(developments.columns).index('unit_exist_preapr2010')
    developments = developments.loc[~(developments.iloc[:,unit_change_loc:]==0).all(axis=1)]
    developments = developments.loc[~(developments.iloc[:,unit_change_loc:].isna()).all(axis=1)]

    developments.drop(columns='Unnamed: 0', inplace = True)


    # Dump back to postgres
    print("Dumping it back to postgres...")
    developments.to_sql('yearly_unitchange', con=sql_engine, if_exists='replace', chunksize=5000, index=False)
    print("Done dumping it back to postgres...")


if __name__ == '__main__':
    pd.options.mode.chained_assignment = None
    main()