import pandas as pd
import string
import csv
#import itertools

# input and output file names
input_file = 'rulecheck_base_items.csv'
output_file = 'rulecheck_item_variations.csv'

# define vars
num_variations = 5
alphabets = ["Latin", "Greek", "Symbol"]
shift_dist = -2 # start with shift_dist -2 and move to +2 in for loop (so 5 versions of items)

# get alphabet letters/symbols
def get_alphabet(alphabet):
    # specify letters of the alphabet
    if (alphabet == 'Greek'):
        alphabet = ['alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta', 'theta', 'iota',
                    'kappa', 'lambda', 'mu', 'nu', 'xi', 'omicron', 'pi', 'rho', 'sigma', 'tau',
                    'upsilon', 'phi', 'chi', 'psi', 'omega']
    elif(alphabet == 'Symbol'):
        alphabet = ['*', '@', '%', '!', '^', '#', '~', '$', '{', '=', ':', ')', '|', '+', ';']
    else:
        alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 
                    'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
        #alphabet = string.ascii_lowercase
    
    return alphabet

def shift_letters(string, alphabet, shift_dist):
    # split strings into separate letters
    letters = string.split()
    shifted_string = ""
    
    for letter in letters:
        # replace letter with letter at location + shift_dist in the ordered list
        original_index = alphabet.index(letter)
        new_index = (original_index + shift_dist)
        shifted_string += alphabet[new_index] + " "
    
    return shifted_string.rstrip()

# read in input file
df = pd.read_csv(input_file)
print(df)
# create output file
f = open('rulecheck_item_variations.csv', 'w')
writer = csv.writer(f)
header = ['itemid','alphabet','A','B','C','D','rule_AB','shift_dist','variationid']
writer.writerow(header)

# iterate through sequence of 1 to num_variations+1 
# and create 5 new versions of each base item in input_file
# note that shift_dist = 0 means that we copy the base item
for variationid in range(1, num_variations + 1):
    # iterate through the rows and create item variations
    for index, row in df.iterrows():
        # copy row
        copied_row = df.loc[index].copy()
        
        # update variationid
        copied_row['shift_dist'] = shift_dist
        copied_row['variationid'] = variationid
        
        # modify copied row to new variation
        alphabet = get_alphabet(copied_row['alphabet'])
        copied_row['A'] = shift_letters(copied_row['A'], alphabet, shift_dist)
        copied_row['B'] = shift_letters(copied_row['B'], alphabet, shift_dist)
        copied_row['C'] = shift_letters(copied_row['C'], alphabet, shift_dist)
        copied_row['D'] = shift_letters(copied_row['D'], alphabet, shift_dist)

        # append copied and modified row to df
        writer.writerow(copied_row)
    
    # increase shift distance by 1
    shift_dist = shift_dist + 1
