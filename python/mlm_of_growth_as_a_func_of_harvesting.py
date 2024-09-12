import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf
import os
from dotenv import load_dotenv

load_dotenv()


# MODEL AM DATA

# get AM data
am_growth = pd.read_csv(f'C:/Users/{os.getenv('MS_USER_NAME')}/Desktop/harvest_data/yearly_growth_for_am_trees.csv')
print("AM data obtained...")
am_growth["unique_plot"] = am_growth["statecd"].astype(str) + "_" + am_growth["unitcd"].astype(str) + "_" + am_growth["countycd"].astype(str) + "_" + am_growth["plot"].astype(str)
am_growth["unique_subp"] = am_growth["statecd"].astype(str) + "_" + am_growth["unitcd"].astype(str) + "_" + am_growth["countycd"].astype(str) + "_" + am_growth["plot"].astype(str) + "_" + am_growth["subp"].astype(str)
print("AM data prepared...")

# set up model
am_model = smf.mixedlm("growth_per_year ~ harvested_on_obs1", am_growth, groups=am_growth["unique_plot"], re_formula="1 + unique_subp")
print("AM model created...")
am_result = am_model.fit()
print("AM model fitted... \n")

# print summary of results
print(am_result.summary())


# MODEL ECM DATA

# get ECM data
em_growth = pd.read_csv(f'C:/Users/{os.getenv('MS_USER_NAME')}/Desktop/harvest_data/yearly_growth_for_em_trees.csv')
print("ECM data obtained...")
em_growth["unique_plot"] = em_growth["statecd"].astype(str) + "_" + em_growth["unitcd"].astype(str) + "_" + em_growth["countycd"].astype(str) + "_" + em_growth["plot"].astype(str)
em_growth["unique_subp"] = em_growth["statecd"].astype(str) + "_" + em_growth["unitcd"].astype(str) + "_" + em_growth["countycd"].astype(str) + "_" + em_growth["plot"].astype(str) + "_" + em_growth["subp"].astype(str)
print("ECM data prepared...")

# set up model
em_model = smf.mixedlm("growth_per_year ~ harvested_on_obs1", em_growth, groups=em_growth["unique_plot"], re_formula="1 + unique_subp")
print("ECM model created...")
em_result = em_model.fit()
print("ECM model fitted... \n")

# print summary of results
print(em_result.summary())