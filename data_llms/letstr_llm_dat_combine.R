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

### LOAD HELPER SCRIPTS
source("letstr_helper_dataprep.R")

### GET DATA
# get dir where all csv's are
dir_results <-paste0(getwd(),"/results_letstr/")
## get data 
dat <- lapply_read_csv_bind_rows(dir_results, "results_.*.csv")
## get gpt-3 data
gpt3 <- lapply_read_csv_bind_rows(dir_results, "gpt3_.*.csv") %>%
  mutate(model = 'gpt-3_text-davinci-003')
## cleanup workspace
#rm(dir_results, lapply_read_csv_bind_rows)

### CLEAN AND SCORE DATA
dat <- dat %>%
  # add gpt3 responses
  bind_rows(gpt3) %>%
  # clean responses
  clean_llm_responses() %>%
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

write.csv(dat, "letstr_llm_all_data.csv", row.names = FALSE)

## EXPLORATORY PLOTS
# put alphabet factor in order of degree of transfer instead of alphabetical
dat$alphabet <- factor(dat$alphabet, levels = c("Latin", "Greek", "Symbol"))
dat$itemid <- as.factor(dat$itemid)

# PLOT CORRECT
dat %>% 
  filter(itemid != '101', itemid != '102') %>%
  group_by(model, alphabet) %>%
  summarise(N = length(correct),
            mean_correct = mean(correct),
            sd_correct = sd(correct),
            se_correct = sd(correct)/sqrt(length(correct))) %>%
  ggplot(aes(x = alphabet, y = mean_correct, color = model, fill=model)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                position = position_dodge(.9),
                color = "black") +
  labs(x="Alphabet", y = "Mean Correct", color="Model", fill="Model")

## PLOT CORRECT BY ITEM
dat %>%
  group_by(model, itemid) %>%
  summarise(N = length(correct),
            mean_correct = mean(correct),
            sd_correct = sd(correct),
            se_correct = sd(correct)/sqrt(length(correct))) %>%
  ggplot(aes(x = itemid, y = mean_correct, color = model, fill=model)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                position = position_dodge(.9),
                color = "black") +
  labs(x="Itemid", y = "Mean Correct", color="Model", fill="Model")

