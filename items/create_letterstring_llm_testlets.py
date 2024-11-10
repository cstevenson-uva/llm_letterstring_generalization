# This script creates num_testlets from the num_variations of items 
# based on the items that were created for children
# A random seed is set to the testletid number so that the same item
# testlets will be created each time

import pandas as pd
import string
import random

# filenames containing item variations
filenames_item_variations = ['testlets/letterstring_testlet0.csv', # this is a copy of the items administered to people
        'testlets/letterstring_testlet1.csv', # copy of variation 1 items from letterstring_item_variations.csv created with script create_letterstring_item_variations.py
        'testlets/letterstring_testlet2.csv', # copy of variation 2 items
        'testlets/letterstring_testlet3.csv', # copy of variation 3 items
        'testlets/letterstring_testlet4.csv', # copy of variation 4 items
        'testlets/letterstring_testlet5.csv'] # copy of variation 5 items

# empty dictionary to hold item dfs
dfs = {}

# read each testlet into a df and store in the dictionary with keys df1, df2, etc.
for i, variation_csv in enumerate(filenames_item_variations, 0):
    dfs[f'df{i}'] = pd.read_csv(variation_csv)

# define loop vars
num_variations = 6 # we already have variations 0-5, these are also the first 5 testlets
num_testlets = 54 # in preregistration we specified 54 testlets
num_items = 5 # num items per alphabet per testlet
alphabets = ["Latin", "Greek", "Symbol"]

itemid_examples = [101, 102]

def get_example_items():
    # examples are first two items in each df
    example1 = dfs['df0'].loc[0].copy()
    example2 = dfs['df0'].loc[1].copy()
    
    return example1, example2

def get_item_variations_list(seed):
    item_vars = []
    
    # set seed to create reproducible item sets
    random.seed(seed)
    
    # now choose a random variation id for each item
    # note only 5 items so that the same item in different alphabets 
    # are parallel (i.e., have same location in alphabet sequence)
    for i in range(1, num_items + 1): 
        item_vars.append(random.randint(0, num_variations - 1))
    
    return item_vars

# function to find the right index of the item to copy from a testlet
def get_item_index(alphabet, index):
    # index + 2 because we want to skip the two example items
    new_index = index + 2 
    
    if (alphabet == 'Greek'):
        new_index = new_index + 5 # to skip the Latin items
    if (alphabet == 'Symbol'):
        new_index = new_index + 10 # to skip the Latin and Greek items
    
    return new_index

for testletid in range(num_variations, num_testlets + 1):
    # create an empty df
    new_df = pd.DataFrame(columns=dfs['df0'].columns.tolist())
    
    # add two example items to new df
    example1, example2 = get_example_items()
    new_df = new_df.append(example1, ignore_index=True)
    new_df = new_df.append(example2, ignore_index=True)
    
    # generate list of item variations to use for this testlet
    item_variations = get_item_variations_list(testletid)
    
    # iterate through alphabets
    for alphabet in alphabets:
        # iterate through item variations
        for i, var in enumerate(item_variations, 0):
            # copy item from testlet with variationnr var append to new df
            copied_item = dfs[f'df{var}'].loc[get_item_index(alphabet, i)].copy()
            new_df = new_df.append(copied_item, ignore_index=True)
    
    # set testletid for new testlet
    new_df['testletid'] = testletid
    # set output filename to 'letterstring_testletx.csv' where x=testletid
    # write new df csv to file
    new_df.to_csv(f'testlets/letterstring_testlet{testletid}.csv', index=False)
    print(f'testlet{testletid} done')
