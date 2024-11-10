### letterstring experiment study 1 analysis

# load libraries
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)
library(rstatix)
library(ggpubr)
library(afex)

# read long data, drop unneeded cols, add needed ones
human_long <- read.csv('data_humans/04_letterstring_response_humans_scored.csv') %>%
  # remove excluded participants
  filter(exclude != 'exclude') %>%
  # get rid of unneeded cols
  select(-c(age_yrs, edu_year, letterstring_response_id, rt)) %>%
  mutate(participant_id = as.factor(participant_id),
         participant_group = case_when(
           participant_group == "adult" ~ "Adults",
           participant_group == "child" ~ "Children"))
llm_long <- read.csv('data_llms/letstr_llm_all_data.csv') %>%
  select(-c(timestamp, rowid, template_nr)) %>%  
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
  )) %>%
  mutate(participant_id = paste(model_short, testletid, sep = "_"), 
         participant_group = model_short)

### COMBINE LONG DATA HUMAN AND LLMS
dat_long_compare <- llm_long %>%
  bind_rows(human_long)

### SET UP DATA FOR ANALYSIS
# model short names we'd like to plot
selected_groups <- c("Adults", "Children",
                     "Claude-3.5", "Gemma-2 27B", "GPT-4o", "Llama-3.1 405B")
# put alphabet factor in order of degree of transfer instead of alphabetical
dat_long_compare$alphabet <- factor(dat_long_compare$alphabet, levels = c("Latin", "Greek", "Symbol"))
# select data for analysis
dat_analyze <- dat_long_compare %>% 
  filter(participant_group %in% selected_groups) 

### WRITE TO FILE 
write.csv(dat_analyze, "letstr_data_all.csv")

### RESULTS PLOT CORRECT
# bar chart comparing kids, adults and llms on proportion correct by alphabet
dat_analyze %>% 
  filter(itemid > 1000) %>% # filter out practice items
  group_by(participant_group, alphabet) %>%
  summarise(N = length(participant_id),
            mean_correct = mean(correct, na.rm = TRUE),
            sd_correct = sd(correct, na.rm = TRUE),
            se_correct = sd(correct, na.rm = TRUE)/sqrt(length(correct))) %>%
  ggplot(aes(x = alphabet, y = mean_correct, color = participant_group, fill=participant_group)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                color = 'black',
                position = position_dodge(.9)) +
  labs(x="Alphabet", y = "Mean Correct", color="Participant Group", fill="Participant Group") 

# table of accs comparing kids, adults and llms on proportion correct by itemid
tbl_summary_itemid <- dat_analyze %>% 
  filter(itemid > 1000) %>% # filter out practice items
  group_by(participant_group, itemid) %>%
  summarise(N = length(participant_id),
            mean_correct = mean(correct, na.rm = TRUE),
            sd_correct = sd(correct, na.rm = TRUE),
            se_correct = sd(correct, na.rm = TRUE)/sqrt(length(correct))) #%>%
print(tbl_summary_itemid, n=40)
## plot to visualize comparison of participant groups on prop correct by itemid
# ggplot(aes(x = itemid, y = mean_correct, color = participant_group, fill=participant_group)) + 
# geom_bar(stat = "identity", position = position_dodge()) +
# geom_errorbar(aes(ymin = mean_correct - se_correct, 
#                    ymax = mean_correct + se_correct),
#                width = .2,
#                color = 'black',
#                position = position_dodge(.9)) +
#  labs(x="Item", y = "Mean Correct", color="Participant Group", fill="Participant Group") 

#### ANALYSIS
### RM mixed ANOVA:
### https://www.datanovia.com/en/lessons/mixed-anova-in-r/#two-way-mixed
# prep data for analysis 
dat_anova <- dat_analyze %>%
  filter(itemid > 1000) %>%
  select(c(participant_id, participant_group, 
           alphabet, correct)) %>%
  group_by(participant_group, participant_id, alphabet) %>%
  summarise(N = length(correct),
            sum_correct = sum(correct, na.rm = TRUE),
            mean_correct = mean(correct, na.rm = TRUE),
            sd_correct = sd(correct, na.rm = TRUE),
            se_correct = sd(correct, na.rm = TRUE)/sqrt(length(correct))) %>%
  convert_as_factor(participant_id, participant_group, 
                    alphabet) 

# get summary stats
dat_summary <- dat_anova %>%
  group_by(participant_group, alphabet) %>%
  get_summary_stats(mean_correct, type = "mean_sd")
print(dat_summary, n=20)

## assumption checks
# check for normality w/ qqplots
ggqqplot(dat_anova, "mean_correct", ggtheme = theme_bw()) +
  facet_grid(alphabet ~ participant_group)
# looks good, except for adults = ceiling effect, 
# but all cells contain > 30 observations so we can continue

# homogeneity of variance assumption
dat_anova %>%
  group_by(alphabet) %>%
  levene_test(mean_correct ~ participant_group)
# assumption violated for Latin alphabet (ceiling effects)
# and Symbol alphabet (floor effects)
# conclusion: check results with robust test 

# homogeneity of covariances assumption
box_m(dat_anova[, "mean_correct", drop = FALSE], dat_anova$participant_group)
# assumption violated for both

# assumption of sphericity is automatically checked

## mixed anova analysis
#data = dat_anova, dv = sum_correct, wid = participant_id,
res_anova <-aov_car(mean_correct ~ participant_group*alphabet 
                    + Error(participant_id/alphabet), data=dat_anova)
res_anova

# effect of group for each alphabet
res_oneway <- dat_anova %>%
  group_by(alphabet) %>%
  anova_test(dv = mean_correct, wid = participant_id, between = participant_group) %>%
  get_anova_table() %>%
  adjust_pvalue(method = "bonferroni")
res_oneway
# conclusion: participant group sig for each alphabet

# RQ2: effect of alphabet for each participant group
res_oneway2 <- dat_anova %>%
  group_by(participant_group) %>%
  anova_test(dv = mean_correct, wid = participant_id, within = alphabet) %>%
  get_anova_table() %>%
  adjust_pvalue(method = "bonferroni")
res_oneway2
# conclusion: 

# RQ1: pairwise comparisons between participant groups within alphabet, ref group=child
res_pwc <- dat_anova %>%
  group_by(alphabet) %>%
  #pairwise_t_test(mean_correct ~ participant_group, p.adjust.method = "bonferroni")
  #pool.sd required to get T statistic, p values remain unchanged with correct t-test
  pairwise_t_test(mean_correct ~ participant_group, ref.group = "child",
                  p.adjust.method = "bonferroni", pool.sd=FALSE) 
print(res_pwc, n=45)


# pairwise comparisons between alphabets within participant groups
res_pwc2 <- dat_anova %>%
  group_by(participant_group) %>%
  pairwise_t_test(mean_correct ~ alphabet, p.adjust.method = "bonferroni")
print(res_pwc2, n=20)
# conclusion: adults: no comparisons sig
# conclusion: children: no comparisons sig
# conclusion: for all models sig differences for each alphabet pairwise comparison
