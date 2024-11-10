### data cleaning and analysis prep script for letter string analogy experiment human data

# load libraries
library(dplyr)
library(stringr)
source("data_llms/letstr_helper_dataprep.R")

# read data 
raw_dat <- read.csv("data_humans/raw_private/230726_letterstring_response_correctunicode.csv")

## clean data
clean_dat <- raw_dat %>%
  # drop unnecessary columns
  select(-c(password, email, exp_condition, exp_itemorder, study, edu_level, 
            originality, utility, innovative, appropriate, aut_experience, 
            aut_instr_check, participant_fk)) %>%
  # convert columns to correct types
  mutate(dob = as.numeric(dob),
         edu_year = as.numeric(edu_year),
         age = as.numeric(age)) %>%
  # drop test data prepping for children's data collection where age = 10 and edu_year = 0
  filter(!(age == 10 & edu_year == 0 & research_study == 'letterstring_schools_202306')) %>%
  # drop data from first graders and other test children on 12/06/23)
  filter(!((edu_year == 3 | user_id == 3721 | user_id == 3729 | user_id == 3739)
           & research_study == 'letterstring_schools_202306')) %>%
  # compute age for adults
  mutate(age_yrs = ifelse(is.na(age), (2023-dob), age)) %>%
  # drop test data for prep and bugfix of uva lab data collection
  filter(!(((user_id >= 3853 & user_id <= 3860) |
            (user_id >= 3875 & user_id <= 3890) | 
            (user_id >= 3902 & user_id <= 3910)))) %>%
  # drop test data for prep and bugfix of prolific data collection
  filter(!((username == 'prolific_participant_sessionid_999') | 
             (username == 'prolific_studyid_999') |
             (user_id >= 3927 & user_id <= 3930))) %>%
  # drop variables that could possibly contain sensitive private info
  select(-c(created_timestamp, username, participantnr, dob, age, saveitem_timestamp))

# write cleaned data to file
write.csv(clean_dat, "data_humans/01_letterstring_response_humans_cleaned.csv", row.names = FALSE)

## prep human data for analysis
prepped_dat <- clean_dat %>%
  # create new participant_group column (adult, child)
  mutate(participant_group = ifelse(research_study == 'letterstring_schools_202306', "child", "adult")) %>%
  # drop unnecessary columns
  select(-c(research_study, consent)) %>%
  # rename columns
  rename(participant_id = user_id) %>%
  # reorder columns
  relocate(c(participant_group, age_yrs), .after = participant_id) 

# introduce whitespace between characters from !Greek alphabets to aid scoring
# (e.g., jjkk becomes j j k k)
prepped_dat$response <- ifelse(
  prepped_dat$alphabet != "Greek",
  sapply(prepped_dat$response, function(x) paste(strsplit(x, NULL)[[1]], collapse = " ")),
  prepped_dat$response
)

scored_dat <- prepped_dat %>%
  # cleaned response is lowercase
  mutate(cleaned_response = str_trim(tolower(response))) %>%
  # remove & and ; from Greek alphabet responses in html
  mutate(cleaned_response = ifelse(alphabet == 'Greek', gsub("[&;]", " ", cleaned_response), cleaned_response),
         correct_response = ifelse(alphabet == 'Greek', gsub("[&;]", " ", D), D),
         A = ifelse(alphabet == 'Greek', gsub("[&;]", " ", A), A),
         B = ifelse(alphabet == 'Greek', gsub("[&;]", " ", B), B),
         C = ifelse(alphabet == 'Greek', gsub("[&;]", " ", C), C),
         D = ifelse(alphabet == 'Greek', gsub("[&;]", " ", D), D),
         ) %>%
  # recode greek letters to single letters
  mutate(cleaned_response = recode_greek_to_latin(cleaned_response),
         correct_response = recode_greek_to_latin(correct_response)) %>%
  # remove remaining white space at beginning and end of str, internal whitespace single
  mutate(cleaned_response = str_squish(cleaned_response),
         correct_response = str_squish(correct_response)) %>%
  # is cleaned response correct?
  mutate(correct = score_response_correct(cleaned_response, correct_response)) %>%
  # change true/false to 1/0 for easier comparison of sums/means
  mutate(correct = as.integer(correct)) %>%
  # recode empty responses as NA
  mutate(cleaned_response = na_if(cleaned_response, "")) %>%
  mutate(cleaned_response = na_if(cleaned_response, " ")) %>%
  # now calculate string distance between response and correct string 
  # using optimal string alignment with Greek converted to Latin
  mutate(stringdist = stringdist(correct_response, cleaned_response, method = "osa")) %>%
  # now replace the shortend greek letters with the greek words
  mutate(cleaned_response = ifelse(alphabet == 'Greek', recode_latin_to_greek(cleaned_response), cleaned_response),
         correct_response = ifelse(alphabet == 'Greek', recode_latin_to_greek(correct_response), correct_response)) 

flagged_excluded <- read.csv("data_humans/03_letterstring_response_humans_flag_exclude.csv")
analyze_dat <- scored_dat %>% 
  left_join(flagged_excluded %>% 
              select(participant_id, letterstring_response_id, exclude, exclude_comment), 
            by = c("participant_id", "letterstring_response_id"))

write.csv(analyze_dat, 'data_humans/04_letterstring_response_humans_scored.csv', row.names = FALSE)
