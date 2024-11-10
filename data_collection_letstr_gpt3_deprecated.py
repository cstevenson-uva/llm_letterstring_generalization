'''
Script for retrieving the GPT-3 letter-string analogy completions.
Results are written to a seperate csv file.
'''
import sys
import argparse
import csv
import numpy as np
import pandas as pd
import itertools
import os
import openai
import string
from datetime import datetime

# load API key from environment variable 
openai.api_key = os.getenv("OPENAI_API_KEY")

# get alphabet letters/symbols
def get_alphabet(alphabet):
    # specify letters of the alphabet
    if (alphabet == 'Greek'):
        alphabet = ['alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta', 'theta', 'iota',
                    'kappa', 'lambda', 'mu', 'nu', 'xi', 'omicron', 'pi', 'rho', 'sigma', 'tau',
                    'upsilon', 'phi', 'chi', 'psi', 'omega']
    elif(alphabet == 'Symbol'):
        alphabet = ['*', '@', '%', '!', '^', '#', '~', '$', '{', '=', ':', ')']
    else:
        alphabet = string.ascii_lowercase
    
    # join letters of alphabet into a string with spaces in between
    alphabet = ' '.join(alphabet)
    
    return alphabet

def get_example(template_nr):
    if (template_nr == 1):
        example = "if a changes to b, then j changes to k"
    elif (template_nr == 2):
        example = "a is to b, as j is to k"
    elif (template_nr == 3):
        example = "a →  b \n j →  k"
    elif (template_nr == 4):
        example = "Let's try to complete the pattern:\n\n[ a ] [ b ] \n[ j ] [ k ]"
    elif (template_nr == 5):
        example = "[ a ] [ b ] \n[ j ] [ k ]"
    else:
        example = "if a changes to b, then j changes to k"
    return example

def get_instruction(template_nr, alphabet):
    start_general = "We are going to do puzzels with the letters or symbols '"
    letters = get_alphabet(alphabet)
    end_general = "'."
    start_example = " For example, in the Latin alphabet '"
    example = get_example(template_nr)
    end_example = "'."
    return start_general + letters + end_general + start_example + example + end_example

def get_alphabet_instruction(alphabet):
    start_general = "The letter or symbol list is '"
    letters = get_alphabet(alphabet)
    end_general = "'."
    return start_general + letters + end_general

def get_item_prompt(template_nr, A, B, C):
    if (template_nr == 1):
        item = f"If {A} changes to {B}, what does {C} change to ?"
    elif (template_nr == 2):
        item = f"{A} is to {B}, as {C} is to"
    elif (template_nr == 3):
        item = f"{A} →  {B}\n{C} → "
    elif (template_nr == 4):
        item = f"Let's try to complete the pattern:\n\n[ {A} ] [ {B} ]\n[ {C} ] ["
    elif (template_nr == 5):
        item = f"[ {A} ] [ {B} ]\n[ {C} ] ["
    else:
        item = f"If {A} changes to {B}, what does {C} change to ?"
    return item

def get_items(path_to_file):
    df = pd.read_csv(path_to_file)
    return df

# function to use instead of gpt request to test programming logic
def ask_gpt_test(engine, prompt):
    response = 'test response'
    finish_reason = 'test finish'
    first_token_index = len(prompt)
    d_avg_logprob = first_token_index
    
    return response, finish_reason, d_avg_logprob

# function to get chatgpt version gpt-4 responses to letter-string analogies
def ask_chatgpt(engine, prompt):
    
    response = openai.ChatCompletion.create(
      model = engine,
      messages = [
            {"role": "user", "content": prompt}
        ],
        max_tokens = 20,
        temperature = 0
    )
    #print(response['choices'][0])
    
    # can't get logprobs so return missing value
    logprob = 'NA'
    
    return response['choices'][0]['message']['content'], response['choices'][0]['finish_reason'], logprob

# function to get gpt responses to analogies, incl avg logprobs of response
def get_gpt_generate_logprobs(engine, prompt):
    
    response = openai.Completion.create(
        engine=engine,
        prompt=prompt,
        max_tokens=20,
        n=1,
        temperature=0, # no randomization in response
        logprobs=1 # request log probabilities for each output token
    )
    
    #print(response['choices'][0])
    first_token_index = np.where(np.array(response['choices'][0]['logprobs']['text_offset']) <= len(prompt))[0][-1]
    d_avg_logprob = np.mean(response['choices'][0]['logprobs']['token_logprobs'][first_token_index:])
    
    return response["choices"][0]["text"], response['choices'][0]['finish_reason'], d_avg_logprob

def nr_ends_with_1(nr):
    return nr % 10 == 1

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--path_to_file", default='items/testlets/letterstring_testlet0.csv', type=str, help="Path to data file")
    parser.add_argument("--testlet_nr", default=1, type=int, help="Testlet nr, i.e. variation nr for item set")
    parser.add_argument("--num_templates", default=1, type=int, help="Number of templates to use")
    parser.add_argument("--use_template", default=1, type=int, help="Which template to use")
    parser.add_argument("--model_name_or_path", default='text-davinci-003', type=str, help="Pretrained model path")
    parser.add_argument("--model_shortname", default='gpt3', type=str, help="Short name to refer to model")
    args = parser.parse_args()
    
    # get timestamp of the current date and time
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    
    # get dataframe containing analogy items
    df = get_items(args.path_to_file)
    #df = df.head()
    print(df.head())
    
    # open csv files to write gpt responses and conversation log to, create writer and logger
    f = open(f'data/gpt/template_best/{args.model_shortname}_testlet{args.testlet_nr}_template{args.use_template}_{timestamp}.csv', 'w')
    log = open(f'data/gpt/template_best/log/{args.model_shortname}_testlet{args.testlet_nr}_template{args.use_template}_prompt_{timestamp}.csv', 'w')
    writer = csv.writer(f)
    logger = csv.writer(log)
    # write headers to csv files 
    header = ['rowid', 'timestamp', 'testletid', 'itemid', 'alphabet', 'A', 'B', 'C', 'D', 'template_nr', 'response', 'logprob', 'finish_reason']
    writer.writerow(header)
    log_header = ['rowid', 'timestamp', 'testletid', 'itemid', 'prompt']
    logger.writerow(header)
    
    # get num items
    num_items = len(df) 
    
    # get answers for each analogy in df for analogy template j on item i in dataframe
    # for each template
    for j in range(1, args.num_templates + 1):
        # select template_nr based on arg.use_template
        if (args.num_templates == 1):
            template_nr = args.use_template
        else:
            # else looping through all templates and
            # template number is j
            template_nr = j
        
        # reset previous exchange to an empty string
        previous_exchange = ''
        
        # for each item
        for i in range(0, num_items):
            # get current rowid
            rowid = i 
            
            # get current item info
            # columns are: "testletid", "itemid","alphabet","A","B","C","D"
            testletid = df.loc[rowid, 'testletid']
            itemid = df.loc[rowid, 'itemid']
            alphabet = df.loc[rowid, 'alphabet']
            A = df.loc[rowid, 'A']
            B = df.loc[rowid, 'B']
            C = df.loc[rowid, 'C']
            D = df.loc[rowid, 'D']
            
            # start prompt with previous exchange(s)
            prompt = previous_exchange
            
            # add instruction to prompt if itemid ends in a 1
            if (nr_ends_with_1(itemid)):
                instr = get_instruction(template_nr, alphabet)
            else:
                instr = get_alphabet_instruction(alphabet)
            prompt = prompt + instr
            
            # create item prompt
            item_prompt = get_item_prompt(template_nr, A, B, C) 
            # add item prompt to the prompt to send to gpt
            prompt = prompt + '\n' + item_prompt 
            
            # get response and when possible logprobs of each letter-string analogy completion in rowid
            if (args.model_shortname == 'gpt4' or args.model_shortname == 'gpt3-5'):
                response, finish_reason, logprob = ask_chatgpt(args.model_name_or_path, prompt)
            elif (args.model_shortname == 'gpt3'):
                response, finish_reason, logprob = get_gpt_generate_logprobs(args.model_name_or_path, prompt)
            else:
                response, finish_reason, logprob = ask_chatgpt(args.model_name_or_path, prompt)
                #response, finish_reason, logprob = ask_gpt_test(args.model_name_or_path, prompt)
            
            # create row and write response to csv
            # ['rowid', 'timestamp', 'testletid', 'itemid', 'alphabet', 'A', 'B', 'C', 'D', 'template_nr', 'response', 'logprob', 'finish_reason']
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
            row = [rowid, timestamp, testletid, itemid, alphabet, A, B, C, D, template_nr, response, logprob, finish_reason]
            writer.writerow(row)
            
            # create row and log exchange to csv
            # log_header = ['rowid', 'timestamp', 'testletid', 'itemid', 'prompt']
            log_row = [rowid, timestamp, testletid, itemid, prompt]
            logger.writerow(log_row)
            
            # update previous exchange with prompt and response
            previous_exchange = prompt + ' ' + response + '\n'
    
    # close csv writers and files
    f.close()
    log.close()

if __name__ == "__main__":

    main()
