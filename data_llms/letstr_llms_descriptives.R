### llm letterstring responses: descriptive statistics

# load libraries
library(dplyr)
library(stringr)
library(tidyr)

# read cleaned data
dat <- read.csv("letstr_llm_all_data.csv")

# create dataframe for analysis with 
# add all needed vars to compare with human data
dat_vars <- dat %>%
  # rename models with shorter names
  mutate(model_short = case_when(
    model == "claude-3-5-sonnet-20241022" ~ "claude-3.5",
    model == "claude-3-sonnet-20240229" ~ "claude-3",
    model == "gpt-3_text-davinci-003" ~ "gpt-3",
    model == "gpt-3.5-turbo-0125" ~ "gpt-3.5",
    model == "gpt-4-0613" ~ "gpt-4",
    model == "gpt-4o-2024-08-06" ~ "gpt-4o",
    model == "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo" ~ "Llama-3.1-8B",
    model == "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo" ~ "Llama-3.1-70B",
    model == "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo" ~ "Llama-3.1-400B",
    model == "google/gemma-2-27b-it" ~ "gemma-2-27B",
    model == "google/gemma-2-9b-it" ~ "gemma-2-9B",
    TRUE ~ model
  )) %>%
  mutate(participant_id = paste(model_short, testletid, sep = "_")) %>%
  # change example items alphabet to example (itemid is 101 or 102)
  mutate(alphabet = ifelse(itemid == 101 | itemid == 102, 'Example', alphabet)) %>%
  # make each var the right type
  mutate(model = as.factor(model),
         model_short = as.factor(model_short),
         participant_id = as.factor(participant_id),
         participant_group = as.factor(model_short),
         itemid = as.factor(itemid),
         alphabet = as.factor(alphabet))

### COMPUTE MAIN VARS FOR ANALYSIS
## total correct per participant per alphabet
dat_analyze <- dat_vars %>%
  # step 1: group by participant_id and alphabet
  group_by(participant_id, alphabet) %>%
  # step 2: create counts of how many responses are empty, correct, and incorrect
  summarize(sum_correct = sum(correct),
            prop_correct = mean(correct)) %>%
  # step 3: from long to wide dataframe
  pivot_wider(names_from = alphabet, 
              values_from = c(sum_correct, prop_correct))
  
# write dataset llms to analyze to csv
write.csv(dat_analyze, 'letstr_llm_analyze.csv', row.names = FALSE)
