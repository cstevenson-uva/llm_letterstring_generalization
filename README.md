# llm_letterstring_generalization
Code for the paper: [Can Large Language Models generalize analogy solving like people can?](https://arxiv.org/abs/2411.02348)

# Authorship
All code was written by Claire Stevenson. 

# OSF Preregistration
Preregistration for this study can be found on OSF [https://osf.io/5u623](https://osf.io/5u623). 

#  Dataset
Open data including LLM, adult and child responses are available for direct re-analyis and can be found in:
```
analysis/letstr_data_all.csv
```
Open data including data coding for errors can be found in:
```
analysis/letstr_data_errorcoded.csv 
```

# Requirements for Replication of Data Collection and Analyses
## Prerequisites for LLM data collection
* Python: please see yaml file for exact environment and library conditions
* [TogetherAI Python library](https://docs.together.ai/docs/quickstart)
* [OpenAI Python library](https://platform.openai.com/docs/overview)
* [Anthropic Python library](https://docs.anthropic.com/en/api/getting-started)

## Prerequisites for data analyses
* R (Studio) with included libraries

## Repository tree structure
```
├── analysis
│   ├── letstr_data_all.csv         # Dataset
│   ├── letstr_data_errorcoded.csv  # Dataset with error coding
│   ├── letstr_errors_analyze.R     # Data analysis: RQ3 error analysis R script 
│   ├── letstr_transformations.R    # included in error analysis script
│   └── letterstring_analyze.R      # Data Analysis: RQ1-3, analysis R script
├── data_collection_humans          # Human Data Collection: screenshots of task
│   ├── adults_instruction_1.png
│   ├── adults_instruction_2.png
│   ├── adults_instruction_3.png
│   ├── adults_instruction_4.png
│   ├── item1_Greek.png
│   ├── item1_Latin.png
│   ├── item1_Symbol.png
│   ├── practice_item1.png
│   └── practice_item2.png
├── data_collection_letstr_gpt3_deprecated.py   # LLM Data Collection: gpt3, deprecated
├── data_collection_letstr_llms_noprevmsg.py    # LLM Data Collection: without previous messages
├── data_collection_letstr_llms.py              # LLM Data Collection: Letter-String Analogy Task
├── data_collection_letstr_rulecheck_llms.py    # LLM Data Collection: Rule Check Task
├── data_collection_nextprevlet_llms.py         # LLM Data Collection: Next-Previous Letter Task
├── data_humans                     # Data Humans: all anonymized human data, plus data prep R scripts  
│   ├── 01_letterstring_response_humans_cleaned.csv
│   ├── 02_letterstring_response_humans_prepped.csv
│   ├── 03_letterstring_response_humans_flag_exclude.csv
│   ├── 04_letterstring_response_humans_scored.csv
│   ├── letterstring_humans_apply_exclusion_criteria.R
│   ├── letterstring_humans_cleaning_and_prep.R
│   └── letterstring_humans_descriptives.R
├── data_llms                       # Data LLMs: all llm data, data prep R scripts and llm specific data analysis scripts 
│   ├── letstr_helper_dataprep.R
│   ├── letstr_llm_all_data.csv
│   ├── letstr_llm_dat_combine.R
│   ├── letstr_llms_scale.R                     # LLM Data Analysis: 4 RQ4 Effect of size/scaling
│   ├── results_letstr
│   │   ├── *.csv
│   ├── results_prevnextletter
│   │   ├── prevnextlet_compare.R               # LLM Data Analysis: 3.3.2 Next-Previous Letter Task
│   │   ├── *.csv
│   ├── test_letstr_noprevmsg
│   │   ├── *.csv
│   │   └── test_letstr_noprevmsg.R             # LLM Data Analysis: Appendix C: Previous vs No Previous Messages
│   ├── test_letstr_orderedsymbols
│   │   ├── letstr_orderedsymbols_compare.R
│   │   ├── *.csv
│   ├── test_letstr_rulecheck
│   │   ├── letstr_rulecheck_compare.R          # LLM Data Analysis: 3.3.3 Rule Check Task
│   │   ├── *.csv
│   └── test_letstr_templates
│       ├── letstr_template_test.R              # LLM Data Analysis: Appendix B: Symbol Task with Ordered vs Not Ordered by Unicode
│       ├── *.csv
├── items                       # python scripts to create item variations, csvs of item variations for each task 
│   ├── create_letterstring_item_variations.py
│   ├── create_letterstring_llm_testlets.py
│   ├── create_rulecheck_item_variations.py
│   ├── letterstring_base_items.csv
│   ├── letterstring_items_humans.csv
│   ├── letterstring_item_variations.csv
│   ├── letterstring_orderedsymbols_base_items.csv
│   ├── nextprevletter_items_llms.csv
│   ├── rulecheck_base_items.csv
│   ├── rulecheck_item_variations.csv
│   └── testlets                # csv files with all items of each of 55 testlets
│       ├── letterstring_testlet[0-54].csv
├── letstr_generalization.yml   # python requirements for reproducing llm data collection
└── README.md
```
