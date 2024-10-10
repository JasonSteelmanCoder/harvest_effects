import os
from dotenv import load_dotenv
import json
import statistics
from scipy import stats

# get the data from a json file
load_dotenv()
input_file = f"C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/growth/growth_itsa_data_first_draft.json"
with open(input_file, "r") as file:
    myjson = json.load(file)

# set empty lists to populate as we go through the trees
am_rate_changes = []
em_rate_changes = []

# loop through all of the trees in the data
for row in myjson:
    # find the index (i) of the first observation with a harvest code of 10
    i = 0
    for obs in row["harvested"]:
        if obs == 10:
            break
        else:
            i += 1

    # name variables
    first_year = row["invyr"][0]
    harvest_year = row["invyr"][i]
    last_year = row["invyr"][-1]

    starting_dia = row["dia"][0]
    harvest_dia = row["dia"][i]
    final_dia = row["dia"][-1]
    
    # find growth and timespans
    years_until_harvest = harvest_year - first_year
    years_after_harvest = last_year - harvest_year

    growth_until_harvest = round(harvest_dia - starting_dia, 2)
    growth_after_harvest = round(final_dia - harvest_dia, 2)

    # calculate growth per year before and after harvesting
    growth_rate_before = growth_until_harvest / years_until_harvest
    growth_rate_after = growth_after_harvest / years_after_harvest

    # find difference in growth rates before and after
    change_in_rate = growth_rate_after - growth_rate_before

    # add the change in rate for this tree to the list of changes for all AM trees or all EM trees
    association = row["association"]
    if association == 'AM':
        am_rate_changes.append(change_in_rate)
    elif association == 'EM':
        em_rate_changes.append(change_in_rate)

# find the average change in growth rates for AM and EM trees
am_mean_change = statistics.mean(am_rate_changes)
print(f"Mean change in AM growth rates: {am_mean_change}")
em_mean_change = statistics.mean(em_rate_changes)
print(f"Mean change in EM growth rates: {em_mean_change}")

tstatistic, pvalue = stats.ttest_ind(am_rate_changes, em_rate_changes)
print(f"t-statistic: {tstatistic}")
print(f"p-value: {pvalue}")
