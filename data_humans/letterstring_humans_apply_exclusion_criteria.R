### script to remove data from excluded participants for letter string analogy experiment human data

# load libraries
library(dplyr)
library(stringr)

# read cleaned data
dat <- read.csv("data/human/02_letterstring_response_humans_prepped.csv")

### APPLY EXCLUSION CRITERIA FROM PREREGISTRATION

## For group 1 (adults):
## We will exclude response sets from people that completed less than 80% of task, 
## indicating a lack of concentration or task focus.

# get adult data 
dat_adult <- dat %>%
  # filter to get adult data
  filter(participant_group == 'adult')

# count number of participants (unique participant_id)
length(unique(dat_adult$participant_id))
# NOTE: 68 unique adult participants

# apply exclusion criteria
dat_adult_exclude <- dat_adult %>%
  # exclude participants that answered <80% of items (i.e. < 14 items of the 17, incl 2 example items)
  # step 1: create boolean var of whether response is empty
  mutate(response_empty = ifelse(response == '', TRUE, FALSE)) %>%
  # step 2: group by participant id 
  group_by(participant_id) %>%
  # step 3: count how many responses are empty
  count(response_empty) %>%
  # step 4: filter to get only counts for when response_empty is TRUE and count n < 14
  filter(response_empty == TRUE & n < 14)

# count number of participants (unique participant_id)
length(dat_adult_exclude$participant_id)
# NOTE: this excludes 6 adult participants
# 68 - 6 = 62 adult participants remain

## For group 2 (children): 
## Given that this task is difficult for children who have just learned to read and do not regularly
## work on cognitive tasks on tablets, we plan to exclude children who (1) answer the two example 
## items incorrectly or (2) answer less than 40% of the items for the Latin alphabet correctly or 
## (3) skip more than 40% of questions for one or more of the alphabets. We do this because these 
## children either did not understand the task and/or the user interface (clicking on alphabet 
## symbols and no opportunity to return to previous questions) or in the case of (3) did not have
## the attention span to complete the task. 

# get child data 
dat_child <- dat %>%
  # filter to get child data
  filter(participant_group == 'child')

# count number of participants (unique participant_id)
length(unique(dat_child$participant_id))
# NOTE: 44 unique child participants

# criteria 1: answered 2 example items incorrectly
dat_child_exclude_1 <- dat_child %>%
  filter((itemid == 101 & correct == 0) & itemid == 102 & correct == 0)
# NOTE: 0 children excluded

# criteria 2: answered < 40% of Latin alphabet items correctly 
dat_child_exclude_2 <- dat_child %>%
  # step 1: get Latin alphabet items (excluding examples with itemids 101 and 102) 
  filter(alphabet == 'Latin' & itemid > 102) %>%
  # step 2: group by participant_id
  group_by(participant_id) %>%
  # step 3: count # correct
  count(correct) %>%
  # step 4: filter to get only counts for when correct is 1 and count n < 2 (of 5 items)
  filter(correct == 1 & n < 2)
# NOTE: 2 children excluded, 3771 and 3845, 
# but when looking at their response patterns the exclusion is not warranted as they have fewer 
# problems with other alphabets, so it looks like a user interface problem only for Latin alphabet

# criteria 3: skip more than 40% of questions for one or more of the alphabets
dat_child_exclude_3 <- dat_child %>%
  # step 1: create boolean var of whether response is empty
  mutate(response_empty = ifelse(response == '', TRUE, FALSE)) %>%
  # step 2: group by participant_id and alphabet
  group_by(participant_id, alphabet) %>%
  # step 3: count how many responses are empty
  count(response_empty) %>%
  # step 4: filter to get only counts for when response_empty is TRUE and count n > 2 (>40%)
  filter(response_empty == TRUE & n > 2) 
# NOTE: 2 children excluded, 3866 and 3845
# after response pattern we see this is correct as both children stopped during testing
# 3866 logged out after 3 items, 3845 responded empty for all items halfway through the test 
  
## If we end up excluding more than 20% of children this 
## way and therefore introduce a strong selection bias then we will examine how to relax 
## the criteria to discard as little data as possible.
# NOTE: this did not happen. We only need to exclude 2 (or 4 if using second criterion) participants

### FLAG PARTICIPANTS TO BE EXCLUDED
dat_flag_exclude_adult <- dat_adult %>%
  mutate(exclude = ifelse((participant_id %in% dat_adult_exclude$participant_id),
                           'exclude', 'include'),
         exclude_comment = ifelse((participant_id %in% dat_adult_exclude$participant_id),
                           'adult criterion 1: <80% items answered', 'include'))


dat_flag_exclude_child <- dat_child %>%
  mutate(exclude = ifelse(participant_id %in% dat_child_exclude_3$participant_id,
                          'exclude', 
                          ifelse(participant_id %in% dat_child_exclude_2$participant_id, 
                                 'maybe', 'include')),
         exclude_comment = ifelse(participant_id %in% dat_child_exclude_3$participant_id,
                                  'child criteria 3: skipped >40% items for 1 or more alphabets', 
                                  ifelse(participant_id %in% dat_child_exclude_2$participant_id, 
                                         'answered < 40% of Latin alphabet items correctly', 
                                         '')))

# add rows from child exclude flags to adult exclude flags
dat_flag_exclude <- dat_flag_exclude_adult %>%
  bind_rows(dat_flag_exclude_child)

# write dataset including exclusion flags to csv
write.csv(dat_flag_exclude, 'data/human/03_letterstring_response_humans_flag_exclude.csv', row.names = FALSE)
