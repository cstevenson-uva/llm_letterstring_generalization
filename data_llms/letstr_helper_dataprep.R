### DATA PREP HELPER FUNCTIONS

greek_letters <- c(
  "α" = "alpha", "β" = "beta", "γ" = "gamma", "δ" = "delta", "ε" = "epsilon", 
  "ζ" = "zeta", "η" = "eta", "θ" = "theta", "ι" = "iota", "κ" = "kappa", 
  "λ" = "lambda", "μ" = "mu", "ν" = "nu", "ξ" = "xi", "ο" = "omicron", 
  "π" = "pi", "ρ" = "rho", "σ" = "sigma", "τ" = "tau", "υ" = "upsilon", 
  "φ" = "phi", "χ" = "chi", "ψ" = "psi", "ω" = "omega"
)
# Load dplyr library
library(dplyr)

clean_llm_responses <- function(dat) {
  dat <- dat %>%
    # cleaned response is lowercase
    mutate(cleaned_response = str_trim(tolower(response))) %>%
    # replace greek symbols with written greek words
    mutate(cleaned_response = str_replace_all(response, greek_letters)) %>%
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
    mutate(cleaned_response = ifelse(alphabet == 'Symbol', gsub("[^@%!^#~${=:)*(-+_;<>& ]}|/", "", cleaned_response), cleaned_response)) %>%
    # remove all words longer than 1 character
    mutate(cleaned_response = gsub("\\b\\w{2,}\\b", "", cleaned_response))%>%
    # remove remaining white space at beginning and end of str, internal whitespace single
    mutate(cleaned_response = str_squish(cleaned_response)) %>%
    # now replace the shortend greek letters with the greek words
    mutate(cleaned_response = ifelse(alphabet == 'Greek', recode_latin_to_greek(cleaned_response), cleaned_response))
  
  return(dat)
}

# function to read all csv files in folder
lapply_read_csv_bind_rows <- function(csv_path, pattern) {
  print(pattern)
  files = list.files(csv_path, pattern = pattern, full.names = TRUE)
  print(files)
  lapply(files, read.csv) %>% bind_rows()
}

# functions to recode Greek letters to Latin and back to make cleaning more efficient
recode_greek_to_latin <- function(text) {
  greek_to_latin <- list(alpha = "a", beta = "b", gamma = "c", delta = "d", epsilon = "e", 
                         zeta = "f", eta = "g", theta = "h", iota = "i", kappa = "j", 
                         lambda = "k", mu = "l", nu = "m", xi = "n", omicron = "o", 
                         pi = "p", rho = "q", sigma = "r", tau = "s", upsilon = "t", 
                         phi = "u", chi = "v", psi = "w", omega = "x")
  # iterate over the greek_to_latin list and replace occurrences of 
  # Greek letters with their Latin counterparts
  for (greek_letter in names(greek_to_latin)) {
    # Using regex to match only standalone Greek words
    text <- gsub(paste0("\\b", greek_letter, "\\b"), greek_to_latin[[greek_letter]], text, ignore.case = TRUE)
  }
  return(text)
}

recode_latin_to_greek <- function(text) {
  latin_to_greek <- list(a = "alpha", b = "beta", c = "gamma", d = "delta", e = "epsilon", 
                         f = "zeta", g = "eta", h = "theta", i = "iota", j = "kappa", 
                         k = "lambda", l = "mu", m = "nu", n = "xi", o = "omicron", 
                         p = "pi", q = "rho", r = "sigma", s = "tau", t = "upsilon", 
                         u = "phi", v = "chi", w = "psi", x = "omega")
  # iterate over the latin_to_greek list and replace singular Latin characters with their Greek counterparts
  for (latin_letter in names(latin_to_greek)) {
    # Using regex to match only standalone Latin characters
    text <- gsub(paste0("\\b", latin_letter, "\\b"), latin_to_greek[[latin_letter]], text)
  }
  return(text)
}

# function: is cleaned response the same as the correct response?
score_response_correct <- function(cleaned_response, correct_response) {
  # first escape (i.e. add backslash in front of) all special characters responses
  cleaned_response <- str_escape(cleaned_response)
  correct_response <- str_escape(correct_response)
  # return whether the response and correct response are the same
  return(cleaned_response == correct_response)
}