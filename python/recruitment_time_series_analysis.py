import os
from dotenv import load_dotenv
import csv
from statistics import mean
from scipy import stats
import sys

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

with open(f"C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/recruitment/interrupted_time_series_data_for_recruitment.csv", "r") as file:
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
        

changes_in_am_slope = []
changes_in_em_slope = []

for row in new_reader:
    # print(row)

    starting_am_trees = row[am_trees_col][0]
    starting_year = row[years_col][0]

    i = 0
    harvested_indices = []
    for observation in row[harvested_col]:
        if observation == 10:
            harvested_indices.append(i)
        i += 1
    first_harvest_i = harvested_indices[0]
    last_harvest_i = harvested_indices[-1]

    am_trees_before_harvest = row[am_trees_col][first_harvest_i - 1]
    pre_harvest_year = row[years_col][first_harvest_i - 1]

    am_trees_after_harvest = row[am_trees_col][last_harvest_i]
    post_harvest_year = row[years_col][last_harvest_i]

    final_am_trees = row[am_trees_col][-1]
    final_year = row[years_col][-1]

    # calculate change in slope
    delta_am_before_harvest = am_trees_before_harvest - starting_am_trees
    years_before_harvest = pre_harvest_year - starting_year

    delta_am_after_harvest = final_am_trees - am_trees_after_harvest
    years_after_harvest = final_year - post_harvest_year

    delta_am_per_year_before = delta_am_before_harvest / years_before_harvest
    delta_am_per_year_after = delta_am_after_harvest / years_after_harvest

    change_in_am_slope = delta_am_per_year_after - delta_am_per_year_before

    print("\n")
    print(f"delta AM per year before harvesting: {delta_am_per_year_before}")
    print(f"delta AM per year after harvesting: {delta_am_per_year_after}")
    print(f"change in AM slope: {change_in_am_slope}")

    changes_in_am_slope.append(change_in_am_slope)

    # REPEAT FOR EM TREES

    # print(row)

    starting_em_trees = row[em_trees_col][0]
    starting_year = row[years_col][0]

    em_trees_before_harvest = row[em_trees_col][first_harvest_i - 1]
    pre_harvest_year = row[years_col][first_harvest_i - 1]

    em_trees_after_harvest = row[em_trees_col][last_harvest_i]
    post_harvest_year = row[years_col][last_harvest_i]

    final_em_trees = row[em_trees_col][-1]
    final_year = row[years_col][-1]

    # calculate change in slope
    delta_em_before_harvest = em_trees_before_harvest - starting_em_trees
    years_before_harvest = pre_harvest_year - starting_year

    delta_em_after_harvest = final_em_trees - em_trees_after_harvest
    years_after_harvest = final_year - post_harvest_year

    delta_em_per_year_before = delta_em_before_harvest / years_before_harvest
    delta_em_per_year_after = delta_em_after_harvest / years_after_harvest

    change_in_em_slope = delta_em_per_year_after - delta_em_per_year_before

    print(f"delta EM per year before harvesting: {delta_em_per_year_before}")
    print(f"delta EM per year after harvesting: {delta_em_per_year_after}")
    print(f"change in EM slope: {change_in_em_slope}")

    changes_in_em_slope.append(change_in_em_slope)

t_statistic, p_value = stats.ttest_ind(changes_in_am_slope, changes_in_em_slope)

print(f"\naverage change in slope for AM trees: {mean(changes_in_am_slope)}")
print(f"average change in slope for EM trees: {mean(changes_in_em_slope)}\n")

print(f"t-statistic: {t_statistic}")
print(f"p-value: {p_value}")