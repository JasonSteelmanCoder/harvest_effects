
row = [13,3,159,43,1,5,"AM",311,"[2009,2014,2019]","[0,10,0]","[1.1,2.1,3.2]"]
# row = [13, 3, 239, 5, 4, 11, "AM", 311, "[1997,2004,2009,2014,2019]", "[0,0,10,0,0]", "[5.8,5.8,5.9,6.4,5.8]"]

# make strings back into lists
year_strings = row[8].strip("[]").split(",")
years = [int(value) for value in year_strings]

treatment_strings = row[9].strip("[]").split(",")
treatments = [int(value) for value in treatment_strings]

diameter_strings = row[10].strip("[]").split(",")
diameters = [float(value) for value in diameter_strings]

# bundle observations
observations = list(zip(years, treatments, diameters))


# prepare named variables
starting_diameter = observations[0][2]
starting_year = observations[0][0]

harvest_diameter = None
harvest_year = None
for observation in observations:
    if observation[1] == 10:
        harvest_diameter = observation[2]
        harvest_year = observation[0]
        break

final_diameter = observations[-1][-1]
final_year = observations[-1][0]


# calculate change in slope
growth_til_harvest = harvest_diameter - starting_diameter
years_til_harvest = harvest_year - starting_year

growth_after_harvest = final_diameter - harvest_diameter
years_after_harvest = final_year - harvest_year

growth_per_year_before = growth_til_harvest / years_til_harvest
growth_per_year_after = growth_after_harvest / years_after_harvest

print(f"growth per year before harvesting: {growth_per_year_before}")
print(f"growth per year after harvesting: {growth_per_year_after}")
