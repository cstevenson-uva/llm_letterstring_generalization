### letterstring llm rulecheck analysis

# load libraries
library(dplyr)
library(stringr)
library(tidyr)
library(tibble)
library(ggplot2)
library(stringdist)

# setwd
#setwd("YOUR_DIR_HERE/data_llms/test_letstr_rulecheck")

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
dat_scored <- dat %>%
  # clean responses
  clean_llm_responses() %>%
  # is cleaned response correct?
  mutate(correct = score_response_correct(cleaned_response, D)) %>%
  # change true/false to 1/0 for easier comparison of sums/means
  mutate(correct = as.integer(correct)) %>%
  # now calculate string distance between response and correct string 
  # using optimal string alignment with Greek converted to Latin
  mutate(stringdist = stringdist(str_replace_all(recode_greek_to_latin(D)," ", ""), 
                                 str_replace_all(recode_greek_to_latin(cleaned_response)," ", ""), 
                                 method = "osa")) %>%
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
    TRUE ~ model)) %>%
  # convert itemids to rules they test
  mutate(itemid = as.character(itemid)) %>%
  mutate(rule = case_when(
    itemid == 201 ~ "successor_1",
    itemid == 202 ~ "successor_2",
    itemid == 203 ~ "predecessor_1",
    itemid == 204 ~ "predecessor_2",
    itemid == 205 ~ "repeat_1",
    itemid == 206 ~ "repeat_2",
    TRUE ~ itemid))

### SET UP DATA FOR ANALYSIS
# model short names we'd like to plot
selected_models <- c("Claude-3.5", "Gemma-2 27B", "GPT-4o", "Llama-3.1 405B")
# put alphabet factor in order of degree of transfer instead of alphabetical
dat_scored$alphabet <- factor(dat_scored$alphabet, levels = c("Latin", "Greek", "Symbol"))
# select data for analysis
dat_analyze <- dat_scored %>% 
  filter(alphabet != 'Example') %>%
  filter(model_short %in% selected_models)
dat_summary <- dat_analyze %>% 
  group_by(model_short, alphabet, rule) %>%
  summarise(N = length(model_short),
            mean_correct = mean(correct, na.rm = TRUE),
            sd_correct = sd(correct, na.rm = TRUE),
            se_correct = sd(correct, na.rm = TRUE)/sqrt(length(correct)))

#write.csv(dat_summary, "rulecheck_summary.csv", row.names = FALSE)

### RESULTS PLOT
# bar chart comparing llms on proportion correct by model by rule
ggplot(dat_summary, aes(fill=rule, y=mean_correct, x=alphabet)) +
  geom_bar(position="dodge", stat="identity") +
  geom_errorbar(aes(ymin = mean_correct - se_correct,
                    ymax = mean_correct + se_correct),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  facet_wrap(~model_short) +
  ggtitle("Rule Check Task") + xlab("Alphabet") + ylab("Mean Correct (SE)")
