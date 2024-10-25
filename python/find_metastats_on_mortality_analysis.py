# total plots analyzed for mortality:
#   4,669 including plots that have None in one of their tree categories
#   3,886 excluding plots that missing trees from one of the four categories

import os
from dotenv import load_dotenv
import csv
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

load_dotenv()

# initialize some lists to populate later
t1_timespans = []
t2_timespans = []
total_timespans = []
t1_tree_counts = []
t2_tree_counts = []
t1_death_counts = []
t2_death_counts = []

# go through each row of the csv
with open(f'C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/mortality/plots_with_tree_counts_and_death_counts_for_t1_and_t2.csv') as input:
    reader = csv.reader(input)

    # skip the header row of the csv
    next(reader)

    # find durations of T1, T2 and total for mortality
    for row in reader:

        # name the columns for ease of use
        t1_timespan = int(row[0])
        t1_am_tree_count = int(row[1])
        t1_em_tree_count = int(row[2])
        t1_am_death_count = int(row[3])
        t1_em_death_count = int(row[4])
        t2_timespan = int(row[5])
        t2_am_tree_count = int(row[6])
        t2_em_tree_count = int(row[7])
        t2_am_death_count = int(row[8])
        t2_em_death_count = int(row[9])
        first_plot_obs_year = int(row[10])
        last_pre_harvest_year = int(row[11])
        first_harvest_year = int(row[12])
        last_plot_obs_year = int(row[13])
        original_plot_cn = int(row[14])

        t1_timespans.append(t1_timespan)
        t2_timespans.append(t2_timespan)
        total_timespans.append(last_plot_obs_year - first_plot_obs_year)

        t1_tree_counts.append(t1_am_tree_count + t1_em_tree_count)
        t2_tree_counts.append(t2_am_tree_count + t2_em_tree_count)

        t1_death_counts.append(t1_am_death_count + t1_em_death_count)
        t2_death_counts.append(t2_am_death_count + t2_em_death_count)

# print stats
mean_t1_timespan = np.mean(t1_timespans)
mean_t2_timespan = np.mean(t2_timespans)
mean_total_timespan = np.mean(total_timespans)

print()
print(f"mean t1 timespan: {mean_t1_timespan}")
print(f"mean t2 timespan: {mean_t2_timespan}")
print(f"mean total timespan: {mean_total_timespan}")
print()

mean_t1_tree_count = np.mean(t1_tree_counts)
mean_t2_tree_count = np.mean(t2_tree_counts)

print(f"mean number of trees in a plot during t1: {mean_t1_tree_count}")
print(f"mean number of trees in a plot during t2: {mean_t2_tree_count}")
print()

mean_t1_death_count = np.mean(t1_death_counts)
mean_t2_death_count = np.mean(t2_death_counts)

print(f"mean number of deaths in a plot during t1: {mean_t1_death_count}")
print(f"mean number of deaths in a plot during t2: {mean_t2_death_count}")
print()

# plot distributions
fig, (ax1, ax2) = plt.subplots(1, 2)
fig.suptitle("Distributions of Timespans")

ax1.hist(t1_timespans, bins=np.arange(0, 18, 1))
ax1.set_title("t1")
ax1.set_xlabel("Years Elapsed in t1")
ax1.set_ylabel("Number of Plots")
ax1.set_xlim(0, 18)
ax1.xaxis.set_major_locator(ticker.MultipleLocator(2))

ax2.hist(t2_timespans, bins=np.arange(0, 18, 1))
ax2.set_title("t2")
ax2.set_xlabel("Years Elapsed in t2")
ax2.set_ylabel("Number of Plots")
ax2.set_xlim(0, 18)
ax2.xaxis.set_major_locator(ticker.MultipleLocator(2))

plt.tight_layout()
plt.show()
plt.clf()

plt.hist(total_timespans, bins=np.arange(0, 24, 1))
plt.title("Distribution of Total Observation Timespans in Years")
plt.xlabel("Years Elapsed During Plot Observations")
plt.ylabel("Number of Plots")
plt.xlim(0, 24)
plt.xticks([0,2,4,6,8,10,12,14,16,18,20,22])
plt.show()


