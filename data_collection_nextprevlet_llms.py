'''
Script for retrieving LLM prev-next letter task completions
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
import pandas as pd
import itertools
import time
from datetime import datetime
import random
from num2words import num2words
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
TOGETHER_MODELS = ['meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo', 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo', 
                  'meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo', 'google/gemma-2-27b-it', 'google/gemma-2-9b-it']#,
                   #'mistralai/Mixtral-8x7B-Instruct-v0.1', 'mistralai/Mixtral-8x22B-Instruct-v0.1',
                   #'Qwen/Qwen1.5-72B-Chat', 'Qwen/Qwen1.5-110B-Chat']

ANTHROPIC_MODELS = ['claude-3-5-sonnet-20241022', 'claude-3-sonnet-20240229']

# system prompt 
SYSTEM_PROMPT = "You are a helpful assistant that solves puzzles. Only give the answer, no other words or text.\n"

# task instruction, only shown at beginning
TASK_INSTR = "Here is an ordered list of letters or symbols "

# alphabet instruction, shown before each item
LATIN_INSTR = "'a b c d e f g h i j k l m n o p q r s t u v w x y z'.\n"
GREEK_INSTR = "'alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega'.\n"
SYMBOL_INSTR = "'* @ % ! ^ # ~ $ { = : )'.\n"

# return alphabet instruction given the required alphabet name
def get_alphabet_instr(alphabet):
    if (alphabet == 'Latin'):
        return LATIN_INSTR
    elif (alphabet == 'Greek'):
        return GREEK_INSTR
    else:
        return SYMBOL_INSTR

def get_item_prompt(prev_next, prev_next_dist, stimulus, template_nr):
    end_q = " ? Respond with only the letter or symbol."
    # template 0: Which letter or symbol is one|two before|after x ?
    # template 1: Which letter or symbol is one|two place|s before|after x ?
    start_q = "Which letter or symbol is "
    prev_next_dist = num2words(prev_next_dist)
    if (prev_next == "prev"):
        if (template_nr == 0):
            before_after = " before "
        elif (template_nr == 1 and prev_next_dist == 1):
            before_after = " place before "
        else:
            before_after = " places before "
    else: # prev_next == "next"
        if (template_nr == 0):
            before_after = " after "
        elif (template_nr == 1 and prev_next_dist == 1):
            before_after = " place after "
        else: # template 1 and 2 after
            before_after = " places after "
    return start_q + prev_next_dist + before_after + stimulus + end_q

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
    parser.add_argument("--path_to_items", default='items/nextprevletter_items_llms.csv', type=str, help="Path to items")
    parser.add_argument("--use_template", default=0, type=int, help="Which template to use? 0 or 1?")
    # MODIFY TO CHANGE MODEL GROUP
    #parser.add_argument("--models", default='gpt', type=str, help="gpt, anthropic or together")
    #parser.add_argument("--models", default='together', type=str, help="gpt, anthropic or together")
    parser.add_argument("--models", default='anthropic', type=str, help="gpt, anthropic or together")
    # DIRECTORY TO STORE OUTPUT IN 
    parser.add_argument("--output_dir", default='data_llms/test_prevnextletter', type=str, help="Output directory for results")
    # ITEM ROW TO START WITH IN CASE OF TIMEOUTS
    parser.add_argument("--rowid_start", default=0, type=int, help="Rowid to start with if script times out, first row indexed at 0")
    args = parser.parse_args()
    
    # get timestamp of the current date and time
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    
    ## GET ITEMS 
    df = get_items(args.path_to_items)
    # for testing use only a few items
    #df = df.head()
    print(df.head())
    
    ### OPEN CSV WRITER
    # open csv files to write llm responses and conversation log to, create writer and logger
    f = open(f'{args.output_dir}/results_template{args.use_template}_{args.models}_{timestamp}.csv', 'w')
    log = open(f'{args.output_dir}/log/log_template{args.use_template}_{args.models}_{timestamp}.csv', 'w')
    writer = csv.writer(f)
    logger = csv.writer(log)
    # write headers to csv files 
    header = ['model', 'rowid', 'timestamp', 'itemid', 'prev_next', 'prev_next_dist', 'alphabet', 'stimulus', 'solution', 'response', 'template_nr']
    writer.writerow(header)
    log_header = ['model', 'rowid', 'timestamp', 'itemid', 'prompt', 'response', 'template_nr']
    logger.writerow(header)

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
        
        # for each item
        for i in range(0, num_items):
            # get current rowid
            rowid = i 
            
            # get current item info
            # columns are: "itemid","prev_next","prev_next_dist","alphabet","stimulus","solution"
            itemid = df.loc[rowid, 'itemid']
            prev_next = df.loc[rowid, 'prev_next']
            prev_next_dist = df.loc[rowid, 'prev_next_dist']
            alphabet = df.loc[rowid, 'alphabet']
            stimulus = df.loc[rowid, 'stimulus']
            solution = df.loc[rowid, 'solution']
             
            # get alphabet for instruction
            instr = get_alphabet_instr(alphabet)
               
            # get item prompt
            item = get_item_prompt(prev_next, prev_next_dist, stimulus, args.use_template)
              
            # prompt is instr + item
            prompt = instr + item
            #print(prompt)
                
            # collect data with model
            if (args.models == 'gpt'):
                response = gpt_call( prompt = prompt, model = model)
            elif (args.models == 'together'):
                response = together_call( prompt = prompt, model = model)
            else:
                response = anthropic_call( prompt = prompt, model = model)
            #print(response)
                
            # create row and write response to csv
            # ['rowid', 'timestamp', 'itemid', 'prev_next', 'prev_next_dist', 'alphabet', 'stimulus', 'solution', 'response']
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
            row = [model, rowid, timestamp, itemid, prev_next, prev_next_dist, alphabet, stimulus, solution, response, template_nr]
            writer.writerow(row)
                
            # create row and log exchange to csv
            # [rowid', 'timestamp', 'itemid', 'prompt', 'response']
            log_row = [model, rowid, timestamp, itemid, prompt, response, template_nr]
            logger.writerow(log_row)
            
    # close csv writers and files
    f.close()
    log.close()

if __name__ == "__main__":
    main()
