### letter-string experiment study 1
### combine LLM data, clean, score and write to csv
### plus some exploratory plots of model performance

# load libraries
library(dplyr)
library(stringr)
library(tidyr)
library(tibble)
library(ggplot2)
library(stringdist)

# setwd
#setwd("YOUR_DIR_PATH_HERE/llm_letterstring_generalization/data_llms/results_prevnextletter")
### LOAD HELPER SCRIPTS
source("../letstr_helper_dataprep.R")

### GET DATA
# get dir where all csv's are
dir_results <-getwd()
## get data 
dat <- lapply_read_csv_bind_rows(dir_results, "results_.*.csv")
## cleanup workspace
rm(dir_results, lapply_read_csv_bind_rows)

### CLEAN AND SCORE DATA
dat <- dat %>%
  # clean responses
  clean_llm_responses() %>%
  # is cleaned response correct?
  mutate(correct = score_response_correct(cleaned_response, solution)) %>%
  # change true/false to 1/0 for easier comparison of sums/means
  mutate(correct = as.integer(correct)) %>%  
  # rename models with shorter names
  mutate(model_short = case_when(
    model == "claude-3-5-sonnet-20241022" ~ "Claude-3.5",
    model == "claude-3-sonnet-20240229" ~ "Claude-3",
    model == "gpt-3_text-davinci-003" ~ "GPT-3",
    model == "gpt-3.5-turbo-0125" ~ "GPT-3.5",
    model == "gpt-4-0613" ~ "GPT-4",
    model == "gpt-4o-2024-08-06" ~ "GPT-4o",
    model == "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo" ~ "Llama-3.1 8B",
    model == "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo" ~ "Llama-3.1 70B",
    model == "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo" ~ "Llama-3.1 405B",
    model == "google/gemma-2-27b-it" ~ "Gemma-2 27B",
    model == "google/gemma-2-9b-it" ~ "Gemma-2 9B",
    TRUE ~ model
  )) 

#write.csv(dat, "../../analysis/prevnextlet_llm_all_data.csv", row.names = FALSE)

## DESCRIPTIVES
# put alphabet factor in order of degree of transfer instead of alphabetical
dat$alphabet <- factor(dat$alphabet, levels = c("Latin", "Greek", "Symbol"))
dat$itemid <- as.factor(dat$itemid)
selected_models <- c("Claude-3.5", "Gemma-2 27B", "GPT-4o", "Llama-3.1 405B")

dat_by_alphabet_condition <- dat %>%
  filter(prev_next_dist != 0, model_short %in% selected_models) %>%
  mutate(condition = paste(prev_next, prev_next_dist, sep='_')) %>%
  group_by(model_short, alphabet, condition) %>%
  summarise(mean_correct = mean(correct, na.rm = TRUE),
            sd_correct = sd(correct, na.rm = TRUE),
            se_correct = sd(correct, na.rm = TRUE)/sqrt(sum(!is.na(correct))))

ggplot(dat_by_alphabet_condition, aes(fill=condition, y=mean_correct, x=alphabet)) +
  geom_bar(position="dodge", stat="identity") +
  geom_errorbar(aes(ymin = mean_correct - se_correct,
                    ymax = mean_correct + se_correct),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  facet_wrap(~model_short) +
  ggtitle("Next-Previous Letter Task") +
  xlab("")
