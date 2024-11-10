### human letterstring responses: descriptive statistics

# load libraries
library(dplyr)
library(stringr)
library(tidyr)

# read cleaned data
dat <- read.csv("data_humans/03_letterstring_response_humans_flag_exclude.csv")

## TRANSFORM AND CREATE REQUIRED VARS
dat_vars <- dat %>%
  # change example items alphabet to example (itemid is 101 or 102)
  mutate(alphabet = ifelse(itemid == 101 | itemid == 102, 'Example', alphabet)) %>%
  # make each var the right type
  mutate(participant_id = as.factor(participant_id),
         participant_group = as.factor(participant_group),
         letterstring_response_id = as.factor(letterstring_response_id),
         itemid = as.factor(itemid),
         alphabet = as.factor(alphabet),
         exclude = as.factor(exclude)) %>%
  # create response_empty var
  mutate(response_empty = ifelse(response == '', TRUE, FALSE)) %>%
  # create correct_with_NA var
  mutate(correct_with_NA = ifelse(response_empty == TRUE, NA, correct))

### DF WITH PARTICIPANT LEVEL VARS
dat_participant <- dat %>%
  group_by(participant_id) %>%
  summarize(age_yrs = first(age_yrs),
            edu_year = first(edu_year),
            participant_group = first(participant_group),
            exclude = first(exclude),
            exclude_comment = first(exclude_comment)) %>%
  mutate(participant_id = as.factor(participant_id))

### PRINT HUMAN DEMOGRAPHIC DESCRIPTIVE STATISTICS
dat_participant %>%
  # remove excluded participants
  filter(exclude != "exclude") %>%
  group_by(participant_group) %>%
  summarize(N = n(),
            M_age = mean(age_yrs),
            SD_age = sd(age_yrs))
 
### COMPUTE MAIN VARS FOR ANALYSIS
## total correct per participant per alphabet
## total proportion correct (not counted skipped items) per participant per alphabet
dat_correct <- dat_vars %>%
  # step 1: group by participant_id and alphabet
  group_by(participant_id, alphabet) %>%
  # step 2: create counts of how many responses are empty, correct, and incorrect
  summarize(sum_correct = sum(correct),
            sum_empty = sum(response_empty == TRUE),
            prop_correct = mean(correct_with_NA, na.rm = TRUE)) %>%
  # step 3: from long to wide dataframe
  pivot_wider(names_from = alphabet, 
              values_from = c(sum_correct, sum_empty, prop_correct))
  
### CREATE DATAFRAME FOR ANALYSIS
dat_analyze <- dat_correct %>%
  left_join(dat_participant)
