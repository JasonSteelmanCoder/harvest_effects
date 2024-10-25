import os
from dotenv import load_dotenv
import csv
import matplotlib.pyplot as plt
import numpy as np

load_dotenv()

# name the indexes of different columns
original_cn_col = 0
cn_sequence_col = 1
years_col = 2
harvested_col = 3
am_trees_col = 4
em_trees_col = 5
other_trees_col = 6

new_reader = []

with open(f"C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/tree_count/interrupted_time_series_data_for_tree_count.csv", "r") as file:
    reader = csv.reader(file)

    next(reader)

    for row in reader:
        new_row = []

        new_row.append(int(row[original_cn_col]))
        new_row.append([int(val.strip("\'\"")) for val in row[cn_sequence_col].strip("[]").split(",")])
        new_row.append([int(val.strip("\'\"")) for val in row[years_col].strip("[]").split(",")])
        harvest_list = []
        for val in row[harvested_col].strip("[]").split(","):
            if val == 'null':
                harvest_list.append(None)
            else:
                harvest_list.append(int(val.strip("\'\"")))
        new_row.append(harvest_list)
        new_row.append([int(val.strip("\'\"")) for val in row[am_trees_col].strip("[]").split(",")])
        new_row.append([int(val.strip("\'\"")) for val in row[em_trees_col].strip("[]").split(",")])
        new_row.append([int(val.strip("\'\"")) for val in row[other_trees_col].strip("[]").split(",")])

        new_reader.append(new_row)
        

total_timespans = []
t1_timespans = []
t2_timespans = []

for row in new_reader:
    total_timespan = row[years_col][-1] - row[years_col][0]
    total_timespans.append(total_timespan)

    first_year = row[years_col][0]
    harvest_index = row[harvested_col].index(10)
    harvest_year = row[years_col][harvest_index]
    pre_harvest_year = row[years_col][harvest_index - 1]
    last_obs_year = row[years_col][-1]
    
    t1_timespan = pre_harvest_year - first_year
    t1_timespans.append(t1_timespan)

    t2_timespan = last_obs_year - harvest_year
    t2_timespans.append(t2_timespan)

mean_total_timespan = np.mean(total_timespans)
mean_t1_timespan = np.mean(t1_timespans)
mean_t2_timespan = np.mean(t2_timespans)
print()
print("Total plots analyzed: 3785")
print()
print(f"Mean total timespan for each plot: {mean_total_timespan}")
print(f"Mean t1 timespan for each plot: {mean_t1_timespan}")
print(f"Mean t2 timespan for each plot: {mean_t2_timespan}")
print()

