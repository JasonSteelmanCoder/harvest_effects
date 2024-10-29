import os
from dotenv import load_dotenv
import json
import statistics
from scipy import stats
import matplotlib.pyplot as plt
import numpy as np

# get the data from a json file
load_dotenv()
input_file = f"C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/growth/including_timberland/growth_itsa_data.json"
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
    first_year = row["measyear"][0]
    harvest_year = row["measyear"][i]
    last_year = row["measyear"][-1]

    starting_dia = row["dia"][0]
    harvest_dia = row["dia"][i]
    final_dia = row["dia"][-1]
    
    # find growth and timespans
    years_until_harvest = harvest_year - first_year
    years_after_harvest = last_year - harvest_year

    growth_until_harvest = round(harvest_dia - starting_dia, 2)
    growth_after_harvest = round(final_dia - harvest_dia, 2)

    # guard against divide-by-zero errors
    if years_until_harvest == 0 or years_after_harvest == 0:
        continue

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
print()
am_mean_change = statistics.mean(am_rate_changes)
em_mean_change = statistics.mean(em_rate_changes)
print(f"Mean change in AM growth rates: {am_mean_change}")
print(f"Mean change in EM growth rates: {em_mean_change}")
print()

# perform a paired t-test
tstatistic, pvalue = stats.ttest_ind(am_rate_changes, em_rate_changes)
print(f"t-statistic: {tstatistic}")
print(f"p-value: {pvalue}")
print()

# find the effect size
pooled_std = np.sqrt((np.std(am_rate_changes) ** 2 + np.std(em_rate_changes) ** 2) / 2)
cohens_d = (am_mean_change - em_mean_change) / pooled_std
print(f"effect size: {cohens_d}")
print()

# plot the distribution of delta growth for both associations of trees
fig, (ax1, ax2) = plt.subplots(2, 1)
fig.suptitle("Changes in Growth Rate After Harvesting")

bin_width = 0.01
num_am_bins = int((max(am_rate_changes) - min(am_rate_changes)) // bin_width)
num_em_bins = int((max(em_rate_changes) - min(em_rate_changes)) // bin_width)

ax1.hist(am_rate_changes, bins=num_am_bins, color="orange")
ax1.set_xlim(-0.6, 0.6)
ax1.set_ylim(0, 6000)
ax1.set_ylabel("frequency")
ax1.set_xlabel("Δ growth rate")
ax1.set_title("Arbuscular Mycorrhizal")

ax2.hist(em_rate_changes, bins=num_em_bins)
ax2.set_xlim(-0.6, 0.6)
ax2.set_ylim(0, 6000)
ax2.set_ylabel("frequency")
ax2.set_xlabel("Δ growth rate")
ax2.set_title("Ectomycorrhizal")

plt.tight_layout()
plt.show()