import os
from dotenv import load_dotenv
import json

load_dotenv()

file_path = f"C:/Users/{os.getenv("MS_USER_NAME")}/Desktop/harvest_data/mortality/all_multi_observed_trees_in_harvested_plots.json"

with open(file_path, 'r') as input:
    data = json.load(input)

# row = data[15]
row = data[3]

harvest_index = row['plot_harvested_sequence'].index(10)
harvest_year = row['plot_year_sequence'][harvest_index]
print(harvest_year)

print(row['tree_status_sequence'])
print(row['tree_year_sequence'])
death_index = row['tree_status_sequence'].index(2)
death_year = row['tree_year_sequence'][death_index]
print(death_year)

print(row['association'])

