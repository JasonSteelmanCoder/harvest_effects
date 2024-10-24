import os
from dotenv import load_dotenv
import csv
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt

load_dotenv()

# initiate lists to populate later
t1_am_deaths_per_tree_per_year_list = []
t1_em_deaths_per_tree_per_year_list = []
t2_am_deaths_per_tree_per_year_list = []
t2_em_deaths_per_tree_per_year_list = []

# go through the csv row by row
with open(f"C:/Users/{os.getenv("MS_USER_NAME")}/desktop/harvest_data/mortality/plots_with_tree_counts_and_death_counts_for_t1_and_t2.csv") as data:
    reader = csv.reader(data)

    next(reader)        # skip the header row

    # name each of the columns in the csv for easy reference
    for row in reader:
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

        # calculate deaths per tree per year
        # divide by zero errors happen when there are zero of a certain kind of tree in a plot
        # except blocks assign None in those cases
        try:
            t1_am_deaths_per_tree_per_year = (t1_am_death_count / t1_am_tree_count) / t1_timespan
        except:             
            t1_am_deaths_per_tree_per_year = None

        try:
            t1_em_deaths_per_tree_per_year = (t1_em_death_count / t1_em_tree_count) / t1_timespan
        except:
            t1_em_deaths_per_tree_per_year = None

        try:
            t2_am_deaths_per_tree_per_year = (t2_am_death_count / t2_am_tree_count) / t2_timespan
        except:
            t2_am_deaths_per_tree_per_year = None

        try:
            t2_em_deaths_per_tree_per_year = (t2_em_death_count / t2_em_tree_count) / t2_timespan
        except:
            t2_em_deaths_per_tree_per_year = None

        # add the data from this row to the global lists
        t1_am_deaths_per_tree_per_year_list.append(t1_am_deaths_per_tree_per_year)
        t1_em_deaths_per_tree_per_year_list.append(t1_em_deaths_per_tree_per_year)
        t2_am_deaths_per_tree_per_year_list.append(t2_am_deaths_per_tree_per_year)
        t2_em_deaths_per_tree_per_year_list.append(t2_em_deaths_per_tree_per_year)


# populate lists of AM mortality changes from t1 to t2 and EM mortality changes from t1 to t2. 
# if either t1 or t2 didn't have trees of that association, None is added to the list in that spot
delta_am_deaths_list = []
delta_em_deaths_list = []
for i in range(len(t1_am_deaths_per_tree_per_year_list)):
    if t2_am_deaths_per_tree_per_year_list[i] == None or t1_am_deaths_per_tree_per_year_list[i] == None:
        delta_am_deaths_list.append(None)
    else: 
        delta_am = t2_am_deaths_per_tree_per_year_list[i] - t1_am_deaths_per_tree_per_year_list[i]
        delta_am_deaths_list.append(delta_am)

    if t2_em_deaths_per_tree_per_year_list[i] == None or t1_em_deaths_per_tree_per_year_list[i] == None: 
        delta_em_deaths_list.append(None)
    else:
        delta_em = t2_em_deaths_per_tree_per_year_list[i] - t1_em_deaths_per_tree_per_year_list[i]
        delta_em_deaths_list.append(delta_em)


# before filtering out plots that have None in one of the two associations, average each association
print()
mean_am_delta_deaths_before_filtering =  np.nanmean(np.array([x if x is not None else np.nan for x in delta_am_deaths_list]))
print(f"pre-filtering mean AM delta deaths: {mean_am_delta_deaths_before_filtering}")

mean_em_delta_deaths_before_filtering =  np.nanmean(np.array([x if x is not None else np.nan for x in delta_em_deaths_list]))
print(f"pre-filtering mean EM delta deaths: {mean_em_delta_deaths_before_filtering}")


# filter out plots that have None for either delta AM or delta EM
filtered_delta_am_deaths_list = []
filtered_delta_em_deaths_list = []
for item in zip(delta_am_deaths_list, delta_em_deaths_list):
    if item[0] is not None and item[1] is not None:
        filtered_delta_am_deaths_list.append(item[0])
        filtered_delta_em_deaths_list.append(item[1])

# find the mean deltas for plots without Nones
mean_am_delta_deaths_filtered = np.mean(filtered_delta_am_deaths_list)
mean_em_delta_deaths_filtered = np.mean(filtered_delta_em_deaths_list)
print()
print(f"filtered mean AM delta deaths: {mean_am_delta_deaths_filtered}")
print(f"filtered mean EM delta deaths: {mean_em_delta_deaths_filtered}")
print()

# perform a paired t-test for the filtered means
t_stat, p_value = stats.ttest_rel(filtered_delta_am_deaths_list, filtered_delta_em_deaths_list)
print(f"t-statistic: {t_stat}")
print(f"p-value: {p_value}")
print()


# find effect size
all_unfiltered_means = []
for val in delta_am_deaths_list:
    if val is not None:
        all_unfiltered_means.append(val)
for val in delta_em_deaths_list:
    if val is not None:
        all_unfiltered_means.append(val)
pooled_std_dev = np.std(all_unfiltered_means)
cohens_d = mean_am_delta_deaths_before_filtering - mean_em_delta_deaths_before_filtering / pooled_std_dev

print(f"effect size: {cohens_d}")


# plot the distribution of filtered delta deaths
fig, (ax1, ax2) = plt.subplots(2, 1)
fig.suptitle("Changes in Mortality Rates After Cutting")

ax1.hist(filtered_delta_am_deaths_list, bins=500, color='orange')
ax1.set_title("Arbuscular Mycorrhizal")
ax1.set_xlabel("Δ deaths per tree per year")
ax1.set_ylabel("frequency")
ax1.set_xlim(-0.3, 0.2)
ax1.set_ylim(0, 200)

ax2.hist(filtered_delta_em_deaths_list, bins=500)
ax2.set_title("Ectomycorrhizal")
ax2.set_xlabel("Δ deaths per tree per year")
ax2.set_ylabel("frequency")
ax2.set_xlim(-0.3, 0.2)
ax2.set_ylim(0, 200)

plt.tight_layout()
plt.show()

