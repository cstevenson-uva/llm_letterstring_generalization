### llm letterstring responses: descriptive statistics

# load libraries
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)

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
    model == "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo" ~ "llama-3.1-8B",
    model == "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo" ~ "llama-3.1-70B",
    model == "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo" ~ "llama-3.1-405B",
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
#write.csv(dat_analyze, 'letstr_llm_analyze.csv', row.names = FALSE)

## PLOTS SHOWING EFFECT OF SCALE
# put alphabet factor in order of degree of transfer instead of alphabetical
dat_vars$alphabet <- factor(dat_vars$alphabet, levels = c("Latin", "Greek", "Symbol"))
# put models in order of size
dat_vars$model_short <- factor(dat_vars$model_short, levels = c("claude-3","claude-3.5", 
                               "gpt-3", "gpt-3.5", "gpt-4", "gpt-4o",
                               "llama-3.1-8B","llama-3.1-70B","llama-3.1-405B",
                               "gemma-2-9B","gemma-2-27B"))
# model groups to plot separately
claudes <- c("claude-3.5","claude-3")
gemmas <- c("gemma-2-9B","gemma-2-27B")
gpts <-  c("gpt-3","gpt-3.5","gpt-4","gpt-4o")
llamas <- c("llama-3.1-8B","llama-3.1-70B","llama-3.1-405B")
# color groups per model
claude_colors <- c("#FFA07A", "#C15F3C") # Orange scale
gemma_colors <- c("#efa0a0", "#ea8080") # Pink scale
gpt_colors <- c("#A8D5BA", "#74AA9C", "#4A8B78", "#1F6B58") # Green scale
llama_colors <- c("#66B2FF", "#0082FB", "#0064E0") # Blueish scale

# PLOT CORRECT
dat_vars %>% 
  filter(itemid != '101', itemid != '102') %>%
  filter(model_short %in% claudes) %>%
  #filter(model_short %in% gemmas) %>%
  #filter(model_short %in% gpts) %>%
  #filter(model_short %in% llamas) %>%
  group_by(model_short, alphabet) %>%
  summarise(N = length(correct),
            mean_correct = mean(correct),
            sd_correct = sd(correct),
            se_correct = sd(correct)/sqrt(length(correct))) %>%
  ggplot(aes(x = alphabet, y = mean_correct, color = model_short, fill=model_short)) + 
  geom_bar(stat = "identity", position = position_dodge(), width = .9) +
  geom_errorbar(aes(ymin = mean_correct - se_correct, 
                    ymax = mean_correct + se_correct),
                width = .2,
                position = position_dodge(.9),
                color = "black") +
  labs(x="Alphabet", y = "Mean Correct", color="Model", fill="Model") +
  scale_y_continuous(limits = c(0, 1)) +
  scale_color_manual(values = claude_colors) + scale_fill_manual(values = claude_colors)
  #scale_color_manual(values = gemma_colors) + scale_fill_manual(values = gemma_colors)
  #scale_color_manual(values = gpt_colors) + scale_fill_manual(values = gpt_colors)
  #scale_color_manual(values = llama_colors) + scale_fill_manual(values = llama_colors)

# PLOT STR_DIST
dat_vars %>% 
  filter(itemid != '101', itemid != '102') %>%
  filter(correct == 0) %>%
  #filter(model_short %in% claudes) %>%
  #filter(model_short %in% gemmas) %>%
  filter(model_short %in% gpts) %>%
  #filter(model_short %in% llamas) %>%
  group_by(model_short, alphabet) %>%
  summarise(N = length(stringdist),
            mean_stringdist = mean(stringdist),
            sd_stringdist = sd(stringdist),
            se_stringdist = sd(stringdist)/sqrt(length(stringdist))) %>%
  ggplot(aes(x = alphabet, y = mean_stringdist, color = model_short, fill=model_short)) + 
  geom_bar(stat = "identity", position = position_dodge(), width = .9) +
  geom_errorbar(aes(ymin = mean_stringdist - se_stringdist, 
                    ymax = mean_stringdist + se_stringdist),
                width = .2,
                position = position_dodge(.9),
                color = "black") +
  scale_y_continuous(limits = c(0, 3)) +
  labs(x="Alphabet", y = "Mean String Distance", color="Model", fill="Model") +
  #scale_color_manual(values = claude_colors) + scale_fill_manual(values = claude_colors)
  #scale_color_manual(values = gemma_colors) + scale_fill_manual(values = gemma_colors)
  scale_color_manual(values = gpt_colors) + scale_fill_manual(values = gpt_colors)
  #scale_color_manual(values = llama_colors) + scale_fill_manual(values = llama_colors)
