# Summary
This repository contains software for investigating the effects of harvesting on growth, recruitment, and mortality among forest trees, based on the Forest Inventory Analysis database. 

# Readme Structure
Below, you will find the steps taken, organized by indentation. In the leftmost layer of indentation, you will find intermediate goals. Below and to the right of those goals are the steps to complete them. Most steps include the name of a script that was used. When that script output a file or several files, they are named in the third layer of indentation, along with any important notes.

# Steps and Details
    Growth by harvesting pipeline:
        download tree_grm_component tables for each state and assemble them into east_us_tree_grm_component
        find individual trees with a list of all of their observation cn's using find_individual_trees_with_all_observations_from_tree_table
            make the table east_us_multi_observed_trees with it
        grab the growth data using collect_growth_data_for_interrupted_time_series.sql
            use that to make growth_itsa_data.json
        analyze the growth data using growth_time_series_analysis.py

        Notes:
        plots are not accepted where there has been evidence of artificial regeneration (stdorgcd = 1) or where stdorgcd is null and cond_status_cd != 1 (code 1 represents accessible forest land)
        cutting anywhere on the plot is counted as "harvesting" (not necessarily the subplot or condition where the tree is)
        only accept trees that were observed at least 3x
        only accept live trees with valid diameters
        trees needed to not be harvested or null for their first observation (or first few), but be harvested some time before their last observation
        T1 runs from the first observation of the tree to the first observation of the tree that shows evidence of harvesting
        T2 runs from the first observation with evidence of harvesting to the final observation of that tree
        there may be more than one harvesting event. harvesting may continue to happen after T2 has started. There may also be null harvest codes after harvesting has started.
        compare the change in slopes for t1 and t2, then compare AM trees to EM trees

    Tree count by harvesting pipeline:
        grab the data using collect_data_for_interrupted_time_series_for_tree_count.sql
            use it to make interrupted_time_series_data_for_tree_count.csv
        analyze the data using tree_count_time_series_analysis.py

        Notes: 
        plots are not accepted where there has been evidence of artificial regeneration (stdorgcd = 1) or where stdorgcd is null and cond_status_cd != 1 (code 1 represents accessible forest land)
        plots have to be observed at least 4x
        the plot must not be harvested or null in the first 2 observations
        the last observation may not be harvested or null
        the plot needs to be harvested between the second and last observations
        t1 is from the first observation until the last non-harvested observation
        t2 starts after the last harvested observation and ends at the final observation
        there may not be harvesting after the start of t2
        compare the change in slopes for t1 and t2, then compare AM trees to EM trees

    Mortality by harvesting pipeline:
        get all trees in multi observed plots with harvesting using find_dying_and_undying_trees_on_harvested_plots.sql
            use it to make tree_observations_in_harvested_plots_for_mortality.csv
        group trees by plot using group_trees_on_harvested_plots.sql
            use it to make plots_with_tree_counts_and_death_counts_for_t1_and_t2.csv
        analyze changes using calculate_change_in_deaths_per_capita_for_am_vs_em.py
        find meta-stats using find_metastats_on_mortality_analysis.py

        constraints:
        plots are not accepted where there has been evidence of artificial regeneration (stdorgcd = 1) or where stdorgcd is null and cond_status_cd != 1 (code 1 represents accessible forest land)
        the plot needs to be observed at least 4x
        the plot needs to not be harvested on the first or second observations
        the plot must have a trtcd indicating harvesting *before* the last observation
        (
            the plot must have trees in both t1 and t2 (enforced during secondary processing)
            the plot must have am and em trees in t1 and t2 (enforced by python to prevent divide by zero errors)
        )
