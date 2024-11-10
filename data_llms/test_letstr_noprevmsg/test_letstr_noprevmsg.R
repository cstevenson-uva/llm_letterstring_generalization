### letter-string experiment study 1
### test which template to use for LLMs

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
# get dir where all csv's are
dir_results <-getwd()
## get data 
dat <- lapply_read_csv_bind_rows(dir_results, "results_.*.csv")
## get gpt-3 data
gpt3 <- read.csv("../gpt3_results.csv")
gpt3$model <- 'gpt-3_text-davinci-003'
## cleanup workspace
rm(dir_results, lapply_read_csv_bind_rows)

### CLEAN DATA
clean_llm_responses <- function(dat) {
  dat <- dat %>%
  # cleaned response is lowercase
  mutate(cleaned_response = str_trim(tolower(response))) %>%
  # remove everything after sentence ending '.'
  mutate(cleaned_response = gsub("\\.*", "", cleaned_response)) %>%  
  # remove everything from <</SYS>> onwards
  mutate(cleaned_response = gsub("<</SYS>>.*", "", cleaned_response)) %>%
  # remove everything before and including changes to as (template 1)
  mutate(cleaned_response = gsub(".*changes to", "", cleaned_response)) %>%
  # remove everything from → onwards (template 2)
  mutate(cleaned_response = gsub("→.*", "", cleaned_response)) %>%
  # (template 3) no systematic cleaning needed
  # remove all text from first ] onwards (templates 4 and 5)
  mutate(cleaned_response = gsub("].*", "", cleaned_response)) %>%
  # recode greek letters to single letters
  mutate(cleaned_response = recode_greek_to_latin(cleaned_response)) %>%
  # remove all nonletters from greek and latin items 
  mutate(cleaned_response = ifelse(alphabet != 'Symbol', gsub("[^a-z ]", "", cleaned_response), cleaned_response)) %>%
  # remove all nonsymbols from symbol items
  mutate(cleaned_response = ifelse(alphabet == 'Symbol', gsub("[^@%!^#~${=:)*(-+_;<>& ]", "", cleaned_response), cleaned_response)) %>%
  # remove all words longer than 1 character
  mutate(cleaned_response = gsub("\\b\\w{2,}\\b", "", cleaned_response))%>%
  # remove remaining white space at beginning and end of str, internal whitespace single
  mutate(cleaned_response = str_squish(cleaned_response)) %>%
  # now replace the shortend greek letters with the greek words
  mutate(cleaned_response = ifelse(alphabet == 'Greek', recode_latin_to_greek(cleaned_response), cleaned_response))
 
  return(dat)
}

### SCORE DATA
dat <- 
  # clean responses
  clean_llm_responses(dat) %>%
  # add correct response col next to scores for easy checks
  mutate(correct_response = D) %>%
  # is cleaned response correct?
  mutate(correct = score_response_correct(cleaned_response, D)) %>%
  # change true/false to 1/0 for easier comparison of sums/means
  mutate(correct = as.integer(correct)) %>%
  ## ADD SCORE GPT3 DATA HERE
  bind_rows(gpt3) %>%
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

# check if Symbol alphabet is being solved as expected
dat_symbol <- dat %>%
  filter(alphabet == "Symbol") 

# PLOT CORRECT ACROSS TEMPLATES
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

## PLOT CORRECT BY TEMPLATE (no examples)
dat %>%
  filter(itemid != '101', itemid != '102') %>%
  group_by(model, template_nr) %>%
  summarise(N = length(correct),
            mean_correct = mean(correct),
            sd_correct = sd(correct),
            se_correct = sd(correct)/sqrt(length(correct))) %>%
  ggplot(aes(x = template_nr, y = mean_correct, color = model, fill=model)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                position = position_dodge(.9),
                color = "black") +
  labs(x="Template Nr", y = "Mean Correct", color="Model", fill="Model")

## PLOT CORRECT BY TEMPLATE (no examples), avg over models
dat %>%
  filter(itemid != '101', itemid != '102') %>%
  group_by(template_nr) %>%
  summarise(N = length(correct),
            mean_correct = mean(correct),
            sd_correct = sd(correct),
            se_correct = sd(correct)/sqrt(length(correct))) %>%
  ggplot(aes(x = template_nr, y = mean_correct)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                color = "black",
                position = position_dodge(.9)) +
  labs(x="Template Nr", y = "Mean Correct")


## PLOT CORRECT BY TEMPLATE (with examples)
dat %>%
  group_by(model, template_nr) %>%
  summarise(N = length(correct),
            mean_correct = mean(correct),
            sd_correct = sd(correct),
            se_correct = sd(correct)/sqrt(length(correct))) %>%
  ggplot(aes(x = template_nr, y = mean_correct, color = model, fill=model)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                color = "black",
                position = position_dodge(.9)) +
  labs(x="Template Nr", y = "Mean Correct", color="Model", fill="Model")

## PLOT CORRECT BY TEMPLATE (with examples), avg over models
dat %>%
  group_by(template_nr) %>%
  summarise(N = length(correct),
            mean_correct = mean(correct),
            sd_correct = sd(correct),
            se_correct = sd(correct)/sqrt(length(correct))) %>%
  ggplot(aes(x = template_nr, y = mean_correct)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                color = "black",
                position = position_dodge(.9)) +
  labs(x="Template Nr", y = "Mean Correct")

