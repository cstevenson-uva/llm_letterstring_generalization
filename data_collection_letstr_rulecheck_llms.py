'''
Script for retrieving LLM letter-string analogy completions
for models from OpenAI, TogetherAI and Anthropic.
Results for each run by each model are written to a seperate csv file.
'''
import sys
import argparse
import os
import requests
import csv
import json
import string
import numpy as np
import pandas as pd
import itertools
import time
from datetime import datetime
import random
import openai
import together
from together import Together
import anthropic

sys.path.append("..")

# load API keys from environment variable
openai.api_key = os.getenv("OPENAI_API_KEY")
together.api_key = os.getenv("TOGETHER_API_KEY")
anthropic.api_key = os.getenv("ANTHROPIC_API_KEY_LS")

# list of models to try for each API
GPT_MODELS = ['gpt-3.5-turbo-0125', 'gpt-4-0613', 'gpt-4o-2024-08-06']#, 'o1-mini-2024-09-12' ,'o1-preview-2024-09-12']
#GPT_MODELS = ['o1-mini-2024-09-12' ,'o1-preview-2024-09-12']
TOGETHER_MODELS = ['meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo', 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo', 
                  'meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo', 'google/gemma-2-27b-it', 'google/gemma-2-9b-it']
                  #'mistralai/Mixtral-8x7B-Instruct-v0.1', 'mistralai/Mixtral-8x22B-Instruct-v0.1',
                  #'Qwen/Qwen1.5-72B-Chat', 'Qwen/Qwen1.5-110B-Chat']
ANTHROPIC_MODELS = ['claude-3-5-sonnet-20241022', 'claude-3-sonnet-20240229']

# system prompt 
SYSTEM_PROMPT = "You are a helpful assistant that solves letter-string analogies. Only give the answer, no other words or text."

# task instruction, only shown at beginning
TASK_INSTR = "We are going to solve puzzles with the letters or symbols "

# alphabet instruction, shown before each item
LATIN_INSTR = r"'a b c d e f g h i j k l m n o p q r s t u v w x y z'.\n"
GREEK_INSTR = r"'alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega'.\n"
SYMBOL_INSTR = r"'* @ % ! ^ # ~ $ { = : ) | + ; \ ( < - & > /'.\n"

# return alphabet instruction given the required alphabet name
def get_alphabet_instr(alphabet):
    if (alphabet == 'Latin'):
        return LATIN_INSTR
    elif (alphabet == 'Greek'):
        return GREEK_INSTR
    else:
        return SYMBOL_INSTR

# text for example item in the 5 different prompt templates
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
    return example + '\n'

# text to present item in the 5 different prompt templates
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

# calls gpt model with prompt and previous messages
def gpt_call(prompt, model):
    '''
    if ('o1' in model):
        response = openai.chat.completions.create(
            model = model,
            max_completion_tokens = 10,
            messages=[
                {"role": "user", "content": SYSTEM_PROMPT + prompt}
            ]
        )
    else:
    '''
    response = openai.chat.completions.create(
        model = model,
        temperature = 0.0,
        max_tokens = 10,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": prompt}
        ]
    )

    return response.choices[0].message.content

# calls together.ai hosted model with prompt and previous messages
def together_call(prompt, model):
    client = Together()
    response = client.chat.completions.create(
        model = model,
        temperature = 0.0,
        max_tokens = 10,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ]
    )

    return response.choices[0].message.content

# calls anthropic model with prompt and previous messages
def anthropic_call(prompt, model):
    client = anthropic.Anthropic(api_key = anthropic.api_key)
    output = client.messages.create(
        model = model, 
        max_tokens = 10,
        system = SYSTEM_PROMPT,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    return output.content[0].text

def main():
    parser = argparse.ArgumentParser()
    # MODIFY FOR ITEM SET AND PROMPT TEMPLATE CHOICE
    parser.add_argument("--path_to_items", default='items/rulecheck_item_variations.csv', type=str, help="Path to data file")
    parser.add_argument("--use_template", default=1, type=int, help="Which template to use? Choices 1 - 5.")
    # MODIFY TO CHANGE MODEL GROUP
    #parser.add_argument("--models", default='gpt', type=str, help="gpt, anthropic or together")
    #parser.add_argument("--models", default='together', type=str, help="gpt, anthropic or together")
    parser.add_argument("--models", default='anthropic', type=str, help="gpt, anthropic or together")
    # DIRECTORY TO STORE OUTPUT IN 
    parser.add_argument("--output_dir", default='data_llms/test_letstr_rulecheck/', type=str, help="Output directory for results")
    # ITEM ROW TO START WITH IN CASE OF TIMEOUTS
    parser.add_argument("--rowid_start", default=0, type=int, help="Rowid to start with if script times out, first row indexed at 0")
    args = parser.parse_args()
    
    # get timestamp of the current date and time
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    
    ## GET ITEMS 
    df = get_items(args.path_to_items)
    # for testing use only a few items
    #df = df.head()
    #print(df.head())
    
    ### OPEN CSV WRITER
    # open csv files to write gpt responses to create writer 
    f = open(f'{args.output_dir}/results_rulecheck_{args.models}_{timestamp}.csv', 'w')
    writer = csv.writer(f)
    # write headers to csv files 
    header = ['model', 'rowid', 'timestamp', 'variationid', 'shift_dist', 'alphabet', 'A', 'B', 'C', 'D', 'item_prompt', 'response']
    writer.writerow(header)
    
    ### VARS FOR DATA COLLECTION
    # get num items
    num_items = len(df) 
    # template number
    template_nr = args.use_template
    
    ### DATA COLLECTION PREP GET MODELS
    if (args.models == 'gpt'):
        models = GPT_MODELS
    elif (args.models == 'together'):
        models = TOGETHER_MODELS
    elif (args.models == 'anthropic'):
        models = ANTHROPIC_MODELS
    else:
        models = []
    
    ### DATA COLLECTION
    # call models
    for idx, model in enumerate(models):
        print(f'_____ Model: {model} ({idx+1}/{len(models)}) _____')
        
        # set previous exchange to an empty string
        previous_exchange = ''
        
        # for each item
        for i in range(0, num_items):
            # get current rowid
            rowid = i 
            
            # get current item info
            variationid = df.loc[rowid, 'variationid']
            shift_dist = df.loc[rowid, 'shift_dist']
            itemid = df.loc[rowid, 'itemid']
            alphabet = df.loc[rowid, 'alphabet']
            A = df.loc[rowid, 'A']
            B = df.loc[rowid, 'B']
            C = df.loc[rowid, 'C']
            D = df.loc[rowid, 'D']
            
            # create instruction part of prompt
            prompt = TASK_INSTR + get_alphabet_instr(alphabet)
            
            # create item prompt
            item_prompt = get_item_prompt(template_nr, A, B, C) 
            
            # add item prompt to instr prompt to send to llm
            prompt = prompt + item_prompt 
            
            # collect data with model
            if (args.models == 'gpt'):
                response = gpt_call( prompt = prompt, model = model)
            elif (args.models == 'together'):
                response = together_call( prompt = prompt, model = model)
            else:
                response = anthropic_call( prompt = prompt, model = model)
            #print(response)
                
            # create row and write response to csv
            #header = ['model', 'rowid', 'timestamp', 'variationid', 'shift_dist', 'itemid', 'alphabet', 'A', 'B', 'C', 'D', 'item_prompt', 'response']
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
            row = [model, rowid, timestamp, variationid, shift_dist, itemid, alphabet, A, B, C, D, item_prompt, response]
            writer.writerow(row)
            
    # close csv writers and files
    f.close()

if __name__ == "__main__":

    main()
