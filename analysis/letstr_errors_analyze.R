### letterstring experiment study 1 error analysis

# load libraries
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)
library(rstatix)
library(ggpubr)

# setwd
setwd("~/Research/letterstringExperiment/study_1/")

# import functions that perform transformations
# and create common error types
source("analysis/letstr_transformations.R")

dat_analyze <- read.csv("letstr_data_all.csv") %>%
  select(-c(X))

# add example responses and scores for different error categories
dat_errors <- dat_analyze %>%
  # copy of A B or C
  # empty
  mutate(
    copy_A = ifelse(cleaned_response == A, 1, 0),
    copy_B = ifelse(cleaned_response == B, 1, 0),  
    copy_C = ifelse(cleaned_response == C, 1, 0),
    empty = ifelse(response == '' | is.na(response), 1, 0)
    ) %>%
  mutate(copy_rule = ifelse((copy_A | copy_B | copy_C), 1, 0)) %>%
  rowwise() %>%
  mutate(literal_rule_response = literal_rule(itemid, B, C),
         one_rule_rep_response = one_rule_repetition(itemid, C),
         one_rule_predsuc_response = one_rule_predsuc(itemid, C, alphabet),
         incorrect_rule_repetition_1_response = repetition(C, "last", 2),
         incorrect_rule_repetition_2_response = repetition(C, "all", 2),
         incorrect_rule_successor_1_response = successor(alphabet, C, "last", 1),
         incorrect_rule_successor_2_response = successor(alphabet, C, "last", 2),
         incorrect_rule_predecessor_1_response = predecessor(alphabet, C, "first", 1),
         incorrect_rule_predecessor_2_response = predecessor(alphabet, C, "first", 2)
         ) %>%
  ungroup() %>%
  mutate(literal_rule = ifelse(literal_rule_response == cleaned_response, 1, 0)) %>%
  mutate(one_rep_rule = ifelse((one_rule_rep_response == cleaned_response) & correct == 0 & literal_rule == 0, 1, 0),
         one_predsuc_rule = ifelse((one_rule_predsuc_response == cleaned_response) & correct == 0 & literal_rule == 0, 1, 0)) %>%
  mutate(one_rule = ifelse((one_rep_rule | one_predsuc_rule), 1, 0)) %>%
  mutate(incorrect_rule_repetition_1 = ifelse((incorrect_rule_repetition_1_response == cleaned_response) & correct == 0 & one_rule == 0, 1, 0),
         incorrect_rule_repetition_2 = ifelse((incorrect_rule_repetition_2_response == cleaned_response) & correct == 0 & one_rule == 0, 1, 0),
         incorrect_rule_successor_1 = ifelse((incorrect_rule_successor_1_response == cleaned_response) & correct == 0 & one_rule == 0, 1, 0),
         incorrect_rule_successor_2 = ifelse((incorrect_rule_successor_2_response == cleaned_response) & correct == 0 & one_rule == 0, 1, 0),
         incorrect_rule_predecessor_1 = ifelse((incorrect_rule_predecessor_1_response == cleaned_response) & correct == 0 & one_rule == 0, 1, 0),
         incorrect_rule_predecessor_2 = ifelse((incorrect_rule_predecessor_2_response == cleaned_response) & correct == 0 & one_rule == 0, 1, 0)
         ) %>%
  mutate(incorrect_rule_rep = ifelse((incorrect_rule_repetition_1 | incorrect_rule_repetition_2), 1, 0),
         incorrect_rule_suc = ifelse((incorrect_rule_successor_1 | incorrect_rule_successor_2), 1, 0),
         incorrect_rule_pre = ifelse((incorrect_rule_predecessor_1 | incorrect_rule_predecessor_2), 1, 0)
         ) %>%
  mutate(incorrect_rule = ifelse((incorrect_rule_rep | incorrect_rule_suc | incorrect_rule_pre) &
                                   correct == 0 & literal_rule == 0 & 
                                   one_rule == 0 & copy_rule == 0, 1, 0)) %>%
  mutate(other_rule = ifelse((correct == 0 & literal_rule == 0 & one_rule == 0 & 
                          incorrect_rule == 0 & copy_rule == 0 & empty == 0), 
                          1, 0))

# check that rules are mutually exclusive, should sum to 1
dat_errors$sum_rules <- rowSums(dat_errors[, c("correct", "literal_rule", "one_rule", "other_rule",
                                               "incorrect_rule", "copy_rule", "empty")], na.rm = TRUE)

# write coded errors to file for manual check
write.csv(dat_errors, "letstr_data_errorcoded.csv")

# put alphabet factor levels in order
dat_errors$alphabet <- factor(dat_errors$alphabet, levels = c("Latin", "Greek", "Symbol"))

# print summary of errors across alphabets
dat_summary <- dat_errors %>%
  filter(itemid > 1000) %>%  
  group_by(participant_group) %>%
  summarize(N = length(participant_id),
            mean_correct = mean(correct, na.rm = TRUE),
            #sd_correct = sd(correct, na.rm = TRUE),
            mean_empty = mean(empty, na.rm = TRUE),
            #sd_empty = sd(empty, na.rm = TRUE),
            mean_literal_rule = mean(literal_rule, na.rm = TRUE),
            #sd_literal_rule = sd(literal_rule, na.rm = TRUE),
            mean_one_rule = mean(one_rule, na.rm = TRUE),
            #sd_one_rule = sd(one_rule, na.rm = TRUE),
            mean_incorrect_rule = mean(incorrect_rule, na.rm = TRUE),
            #sd_incorrect_rule = sd(incorrect_rule, na.rm = TRUE),
            mean_copy_rule = mean(copy_rule, na.rm = TRUE),
            #sd_copy_rule = sd(copy_rule, na.rm = TRUE),
            mean_other_rule = mean(other_rule, na.rm = TRUE)#,
            #sd_other_rule = sd(other_rule, na.rm = TRUE)
            )
 
# print summary of errors across alphabets
dat_summary_incorrect_rules <- dat_errors %>%
  filter(itemid > 1000, participant_group != 'adult', 
         participant_group != 'child', incorrect_rule == 1) %>%
  group_by(model) %>%
  summarise(mean_pred_rule = mean(incorrect_rule_pre),
            mean_suc_rule = mean(incorrect_rule_suc),
            mean_rep_rule = mean(incorrect_rule_rep))
  
  
### RESULTS PLOT Literal RULE ERROR
# bar chart comparing kids, adults and llms on literal_rule
dat_errors %>% 
  filter(itemid > 1000) %>%  # filter out practice items
  filter(correct == 0) %>%
  group_by(participant_group, alphabet) %>%
  summarise(N = length(participant_id),
            mean_literal_rule = mean(literal_rule, na.rm = TRUE),
            sd_literal_rule = sd(literal_rule, na.rm = TRUE),
            se_literal_rule = sd(literal_rule, na.rm = TRUE)/sqrt(length(literal_rule))) %>%
  ggplot(aes(x = alphabet, y = mean_literal_rule, color = participant_group, fill=participant_group)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_literal_rule - se_literal_rule, 
                    ymax = mean_literal_rule + se_literal_rule),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  labs(x="Alphabet", y = "Literal Rule Use", color="Participant Group", fill="Participant Group") 
### RESULTS PLOT ONE_RULE ERROR
# bar chart comparing kids, adults and llms on one_rule
dat_errors %>% 
  filter(itemid > 1000) %>%  # filter out practice items
  filter(correct == 0) %>%
  group_by(participant_group, alphabet) %>%
  summarise(N = length(participant_id),
            mean_one_rule = mean(one_rule, na.rm = TRUE),
            sd_one_rule = sd(one_rule, na.rm = TRUE),
            se_one_rule = sd(one_rule, na.rm = TRUE)/sqrt(length(one_rule))) %>%
  ggplot(aes(x = alphabet, y = mean_one_rule, color = participant_group, fill=participant_group)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_one_rule - se_one_rule, 
                    ymax = mean_one_rule + se_one_rule),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  labs(x="Alphabet", y = "One Rule Use", color="Participant Group", fill="Participant Group") 
### RESULTS PLOT INCORRECT_RULE ERROR
# bar chart comparing kids, adults and llms on incorrect_rule
dat_errors %>% 
  filter(itemid > 1000) %>%  # filter out practice items
  filter(correct == 0) %>%
  group_by(participant_group, alphabet) %>%
  summarise(N = length(participant_id),
            mean_incorrect_rule = mean(incorrect_rule, na.rm = TRUE),
            sd_incorrect_rule = sd(incorrect_rule, na.rm = TRUE),
            se_incorrect_rule = sd(incorrect_rule, na.rm = TRUE)/sqrt(length(incorrect_rule))) %>%
  ggplot(aes(x = alphabet, y = mean_incorrect_rule, color = participant_group, fill=participant_group)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_incorrect_rule - se_incorrect_rule, 
                    ymax = mean_incorrect_rule + se_incorrect_rule),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  labs(x="Alphabet", y = "Incorrect Rule Use", color="Participant Group", fill="Participant Group") 
### RESULTS PLOT OTHER RULE ERROR
# bar chart comparing kids, adults and llms on copy_rule
dat_errors %>% 
  filter(itemid > 1000) %>%  # filter out practice items
  filter(correct == 0) %>%
  group_by(participant_group, alphabet) %>%
  summarise(N = length(participant_id),
            mean_copy_rule = mean(copy_rule, na.rm = TRUE),
            sd_copy_rule = sd(copy_rule, na.rm = TRUE),
            se_copy_rule = sd(copy_rule, na.rm = TRUE)/sqrt(length(copy_rule))) %>%
  ggplot(aes(x = alphabet, y = mean_copy_rule, color = participant_group, fill=participant_group)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_copy_rule - se_copy_rule, 
                    ymax = mean_copy_rule + se_copy_rule),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  labs(x="Alphabet", y = "Copy Rule Use", color="Participant Group", fill="Participant Group") 
### RESULTS PLOT OTHER RULE ERROR
# bar chart comparing kids, adults and llms on other_rule
dat_errors %>% 
  filter(itemid > 1000) %>%  # filter out practice items
  filter(correct == 0) %>%
  group_by(participant_group, alphabet) %>%
  summarise(N = length(participant_id),
            mean_other_rule = mean(other_rule, na.rm = TRUE),
            sd_other_rule = sd(other_rule, na.rm = TRUE),
            se_other_rule = sd(other_rule, na.rm = TRUE)/sqrt(length(other_rule))) %>%
  ggplot(aes(x = alphabet, y = mean_other_rule, color = participant_group, fill=participant_group)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_other_rule - se_other_rule, 
                    ymax = mean_other_rule + se_other_rule),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  labs(x="Alphabet", y = "Other Rule Use", color="Participant Group", fill="Participant Group") 


### RESULTS PLOT STRING DIST ERROR
# bar chart comparing kids, adults and llms on string_dist
dat_errors %>% 
  filter(itemid > 1000) %>%  # filter out practice items
  filter(correct == 0) %>%
  group_by(participant_group, alphabet) %>%
  summarise(N = length(participant_id),
            mean_stringdist = mean(stringdist, na.rm = TRUE),
            sd_stringdist = sd(stringdist, na.rm = TRUE),
            se_stringdist = sd(stringdist, na.rm = TRUE)/sqrt(length(stringdist))) %>%
  ggplot(aes(x = alphabet, y = mean_stringdist, color = participant_group, fill=participant_group)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_stringdist - se_stringdist, 
                    ymax = mean_stringdist + se_stringdist),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  labs(x="Alphabet", y = "Mean String Distance", color="Participant Group", fill="Participant Group") 

