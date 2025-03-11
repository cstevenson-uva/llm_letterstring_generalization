import pandas as pd
import string

# input and output file names
input_file = 'letterstring_base_items.csv'
output_file = 'letterstring_item_variations.csv'

# define vars
num_testlets = 5
alphabets = ["Latin", "Greek", "Symbol"]
itemid_examples = [101, 102]
shift_dist = -2 # start with shift_dist -2 and move to +2 in for loop (so 5 versions of items)

# get alphabet letters/symbols
def get_alphabet(alphabet):
    # specify letters of the alphabet
    if (alphabet == 'Greek'):
        alphabet = ['alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta', 'theta', 'iota',
                    'kappa', 'lambda', 'mu', 'nu', 'xi', 'omicron', 'pi', 'rho', 'sigma', 'tau',
                    'upsilon', 'phi', 'chi', 'psi', 'omega']
    elif(alphabet == 'Symbol'):
        #alphabet = ['*', '@', '%', '!', '^', '#', '~', '$', '{', '=', ':', ')']
        alphabet = ['!', '#', '$', '%', '&', '(', ')', '*', '+', '-', ':', ';']
    else:
        alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o']
        #alphabet = string.ascii_lowercase
    
    return alphabet

def shift_letters(string, string_list, shift_dist):
    # split string into separate letters
    letters = string.split()
    new_letters = []
    
    for letter in letters:
        # replace letter with letter at location + shift_dist in the ordered list
        index = string_list.index(letter)
        new_letter = string_list[(index + shift_dist)]
        new_letters.append(new_letter)
    
    # join the modified letters to create a new string
    new_string = ' '.join(new_letters)
    return new_string

# read in input file
df = pd.read_csv(input_file)
new_df = df

# iterate through sequence of 1 to num_testlets+1 (so 6 in our case)
# and create 5 new versions of each base item in input_file
# note that shift_dist = 0 means that we copy the base item
# base items are not the exact same as human items b/c we needed them to 
# be in a specific location of the alphabet to work with shifting back and forth
for testletid in range(1, num_testlets + 1):
    # iterate through the rows and create item variations
    for index, row in df.iterrows():
        # copy row
        copied_row = df.loc[index].copy()
        
        # update testletid
        copied_row['testletid'] = testletid
        
        # if row doesn't contain example item, then modify to new variation
        if (copied_row['itemid'] not in itemid_examples):
            alphabet = get_alphabet(copied_row['alphabet'])
            copied_row['A'] = shift_letters(copied_row['A'], alphabet, shift_dist)
            copied_row['B'] = shift_letters(copied_row['B'], alphabet, shift_dist)
            copied_row['C'] = shift_letters(copied_row['C'], alphabet, shift_dist)
            copied_row['D'] = shift_letters(copied_row['D'], alphabet, shift_dist)
                
        # append copied and modified row to df
        new_df = pd.concat([new_df, copied_row], ignore_index=True)

    # increase shift distance by 1
    shift_dist = shift_dist + 1

new_df.to_csv(output_file, index=False)
