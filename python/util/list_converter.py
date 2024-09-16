my_var = "[1991, 2005]"

my_var = my_var.strip("[]")
my_list = my_var.split(',')
my_int_list = [int(year) for year in my_list]

print(my_int_list[0])