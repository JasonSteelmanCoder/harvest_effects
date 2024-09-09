import os
from dotenv import load_dotenv
import psycopg2
import pandas as pd

# set up
load_dotenv()

connection = psycopg2.connect(
    dbname = os.getenv('DBNAME'),
    user = os.getenv("USER"),
    password = os.getenv("PASSWORD"),
    host = os.getenv("HOST"),
    port = os.getenv("PORT")
)

cursor = connection.cursor()

# find all the trees that are observed more than once
cursor.execute("""
    
    WITH counting AS (
        -- grab each live tree with its count of observations, first observation year and last observation year
        SELECT statecd, unitcd, countycd, plot, subp, tree, COUNT(invyr) AS num_obs, MIN(invyr) AS obs_1_year, MAX(invyr) AS obs_2_year 
        FROM east_us_tree
        WHERE 
            statuscd = 1					-- only accept live trees
            AND invyr != 9999               -- trees must have valid observation years
        GROUP BY statecd, unitcd, countycd, plot, subp, tree 
        ORDER BY COUNT(invyr)
    )
    -- grab everything about the trees that are observed at least twice
    SELECT * 
    FROM counting
    WHERE num_obs > 1

""")

trees = cursor.fetchall()

# use a pandas dataframe to boil the list of trees down to plots
trees_df = pd.DataFrame(trees, columns=["statecd", "unitcd", "countycd", "plot", "subp", "tree", "num_obs", "obs_1_year", "obs_2_year"])

plots = trees_df.iloc[:, 0:4].drop_duplicates()

# ... what do we need here?
for i in range(len(plots["plot"])): 

    cursor.execute(f"""

        SELECT east_us_cond.invyr, trtcd1, trtcd2, trtcd3 
        FROM east_us_cond 
        WHERE 
            east_us_cond.statecd = {plots["statecd"].iloc[i]}
            AND east_us_cond.unitcd = {plots["unitcd"].iloc[i]}
            AND east_us_cond.countycd = {plots["countycd"].iloc[i]}    
            AND east_us_cond.plot = {plots["plot"].iloc[i]}::text
        ORDER BY east_us_cond.invyr

    """)

    county_treatment = cursor.fetchall()

    print(county_treatment)