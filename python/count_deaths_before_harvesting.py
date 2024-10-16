import os
from dotenv import load_dotenv
import json
import numpy as np
from scipy import stats

load_dotenv()

file_path = f"C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/mortality/dying_trees_in_harvested_plots.json"
with open(file_path, "r") as input:
    data = json.load(input)

death_counts = {}
for i in range(len(data)):

    harvested = data[i]["plot_harvested_sequence"]
    harvest_index = harvested.index(10)
    harvest_year = data[i]["plot_year_sequence"][harvest_index]

    statuses = data[i]["tree_status_sequence"]
    death_index = statuses.index(2)
    death_year = data[i]["tree_year_sequence"][death_index]

    association = data[i]["association"]

    first_obs_year = data[i]["plot_year_sequence"][0]

    if str(data[i]["plot_original_cn"]) not in death_counts:
        death_counts[str(data[i]["plot_original_cn"])] = {"am deaths": 0, "em deaths": 0, "years before harvest": harvest_year - first_obs_year}

    if death_year < harvest_year:
        if association == 'AM':
            death_counts[str(data[i]["plot_original_cn"])]["am deaths"] += 1
        elif association == 'EM':
            death_counts[str(data[i]["plot_original_cn"])]["em deaths"] += 1

am_death_per_year_values = []
em_death_per_year_values = []
for value in death_counts.values():
    if value["years before harvest"] > 0:
        am_death_per_year_values.append(value["am deaths"] / value["years before harvest"])
        em_death_per_year_values.append(value["em deaths"] / value["years before harvest"])
        
print()
print(f"average am deaths per year: {np.mean(am_death_per_year_values)}")
print(f"average em deaths per year: {np.mean(em_death_per_year_values)}")
print()

t_statistic, p_value = stats.ttest_rel(am_death_per_year_values, em_death_per_year_values)

print(f"t-statistic: {t_statistic}")
print(f"p-value: {p_value}")
print()

