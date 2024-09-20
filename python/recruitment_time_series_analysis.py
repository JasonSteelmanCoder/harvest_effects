import os
from dotenv import load_dotenv
import csv
from statistics import mean

load_dotenv()

# name the indexes of different columns
statecd_col = 0
unitcd_col = 1
countycd_col = 2
plot_col = 3
years_col = 4
harvested_col = 5
am_trees_col = 6
em_trees_col = 7
other_trees_col = 8

new_reader = []

with open(f"C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/recruitment/interrupted_time_series_data_for_recruitment.csv", "r") as file:
    reader = csv.reader(file)

    next(reader)

    for row in reader:
        new_row = []

        new_row.append(int(row[statecd_col]))
        new_row.append(int(row[unitcd_col]))
        new_row.append(int(row[countycd_col]))
        new_row.append(int(row[plot_col]))
        new_row.append([int(val) for val in row[years_col].strip("[]").split(",")])
        new_row.append([int(val.strip("\"")) for val in row[harvested_col].strip("[]").split(",")])
        new_row.append([int(val.strip("\"")) for val in row[am_trees_col].strip("[]").split(",")])
        new_row.append([int(val.strip("\"")) for val in row[em_trees_col].strip("[]").split(",")])
        new_row.append([int(val.strip("\"")) for val in row[other_trees_col].strip("[]").split(",")])

        new_reader.append(new_row)

changes_in_am_slope = []

for row in new_reader:
    # print(row)

    starting_am_trees = row[am_trees_col][0]
    starting_year = row[years_col][0]

    i = 0
    for observation in row[harvested_col]:
        if observation == 10:
            break
        else: 
            i += 1
    am_trees_at_harvest = row[am_trees_col][i]
    harvest_year = row[years_col][i]

    final_am_trees = row[am_trees_col][-1]
    final_year = row[years_col][-1]


    # calculate change in slope
    delta_am_before_harvest = am_trees_at_harvest - starting_am_trees
    years_before_harvest = harvest_year - starting_year

    delta_am_after_harvest = final_am_trees - am_trees_at_harvest
    years_after_harvest = final_year - harvest_year

    delta_am_per_year_before = delta_am_before_harvest / years_before_harvest
    delta_am_per_year_after = delta_am_after_harvest / years_after_harvest

    change_in_am_slope = delta_am_per_year_after - delta_am_per_year_before

    print("\n")
    print(f"delta AM per year before harvesting: {delta_am_per_year_before}")
    print(f"delta AM per year after harvesting: {delta_am_per_year_after}")
    print(f"change in AM slope: {change_in_am_slope}")

    changes_in_am_slope.append(change_in_am_slope)

print(f"\naverage change in delta AM trees per year: {mean(changes_in_am_slope)}")