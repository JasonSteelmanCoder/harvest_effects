import os
from dotenv import load_dotenv
import json
import matplotlib.pyplot as plt
import numpy as np

# get the data from a json file
load_dotenv()
input_file = f"C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/growth/growth_itsa_data.json"
with open(input_file, "r") as file:
    myjson = json.load(file)

# set empty lists to populate as we go through the trees
t1_timespans = []
t2_timespans = []
total_timespans = []

# loop through all of the trees in the data
for row in myjson:
    harvest_index = row['harvested'].index(10)
    first_year = row["measyear"][0]
    harvest_year = row["measyear"][harvest_index]
    last_year = row["measyear"][-1]
    
    t1_timespan = harvest_year - first_year
    t2_timespan = last_year - harvest_year
    total_timespan = last_year - first_year
    
    t1_timespans.append(t1_timespan)
    t2_timespans.append(t2_timespan)
    total_timespans.append(total_timespan)

mean_t1_timespan = np.mean(t1_timespans)
mean_t2_timespan = np.mean(t2_timespans)
mean_total_timespan = np.mean(total_timespans)

print()
print(f"Total trees analyzed: {len(myjson)}")
print()
print(f"Mean t1 timespan: {mean_t1_timespan}")
print(f"Mean t2 timespan: {mean_t2_timespan}")
print(f"Mean total timespan: {mean_total_timespan}")
print()


