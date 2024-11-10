### letter-string experiment study 1
### test whether ordering symbols improves LLM performance

# load libraries
library(dplyr)
library(stringr)
library(tidyr)
library(tibble)
library(ggplot2)
library(stringdist)

### LOAD HELPER SCRIPTS
source("../letstr_helper_dataprep.R")

### GET DATA
#setwd("YOUR_DIR_HERE/llm_letterstring_generalization/data_llms/test_letstr_orderedsymbols")
# get dir where all csv's are
dir_results <-getwd()
## get data 
dat <- lapply_read_csv_bind_rows(dir_results, "results_.*.csv")
## cleanup workspace
rm(dir_results, lapply_read_csv_bind_rows)

### CLEAN AND SCORE DATA
dat <- 
  # clean responses
  clean_llm_responses(dat) %>%
  # add correct response col next to scores for easy checks
  mutate(correct_response = D) %>%
  # is cleaned response correct?
  mutate(correct = score_response_correct(cleaned_response, D)) %>%
  # change true/false to 1/0 for easier comparison of sums/means
  mutate(correct = as.integer(correct)) %>%
  # now calculate string distance between response and correct string 
  # using optimal string alignment with Greek converted to Latin
  mutate(stringdist = stringdist(str_replace_all(recode_greek_to_latin(D)," ", ""), 
                                 str_replace_all(recode_greek_to_latin(cleaned_response)," ", ""), 
                                 method = "osa"))

## EXPLORATORY PLOTS
# put alphabet factor in order of degree of transfer instead of alphabetical
dat$alphabet <- factor(dat$alphabet, levels = c("Latin", "Greek", "Symbol"))
dat$itemid <- as.factor(dat$itemid)
dat$template_nr <- as.factor(dat$template_nr)
selected_groups <- c("claude-3-5-sonnet-20241022", "google/gemma-2-27b-it", 
                     "gpt-4o-2024-08-06", "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo")

# PLOT PER ALPHABET
dat %>% 
  filter(itemid != '101', itemid != '102') %>%
  filter(model %in% selected_groups) %>%
  group_by(alphabet) %>%
  summarise(N = length(correct),
            mean_correct = mean(correct),
            sd_correct = sd(correct),
            se_correct = sd(correct)/sqrt(length(correct))) #%>%

ggplot(dat, aes(x = alphabet, y = mean_correct)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                position = position_dodge(.9),
                color = "black") +
  labs(x="Alphabet", y = "Mean Correct")

# with ordered symbols
#alphabet     N mean_correct sd_correct se_correct
#1 Latin      100         0.74      0.441     0.0441
#2 Greek      100         0.62      0.488     0.0488
#3 Symbol     100         0.49      0.502     0.0502

# without ordered symbols
# i.e. ordering made no difference
#alphabet     N mean_correct sd_correct se_correct
#1 Latin      100         0.78      0.416     0.0416
#2 Greek      100         0.62      0.488     0.0488
#3 Symbol     100         0.31      0.465     0.0465

# ADVANTAGE USING ORDERED SYMBOLS, BUT MAIN CONCLUSIONS REMAIN SAME
