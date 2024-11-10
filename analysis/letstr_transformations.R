## functions to perform rules on a given string

# first import helper functions
source("data_llms/letstr_helper_dataprep.R")

# function string part grabs the first or last part of the string 
# and returns num_letters of that part
string_part <- function(string, part, num_letters) {
  # Split the string by spaces
  letters <- unlist(strsplit(string, " "))
  
  # Extract based on 'part' and 'num_letters'
  if (part == "first") {
    result <- paste(letters[1:num_letters], collapse = " ")
  } else if (part == "last") {
    result <- paste(tail(letters, num_letters), collapse = " ")
  } else {
    stop("The 'part' argument must be either 'first' or 'last'.")
  }
  
  return(result)
}

# test string_part function
#string_part("j k", "last", 1)       # Should return "k"
#string_part("n n o o", "first", 2)  # Should return "n n"
#string_part("i j j", "last", 2)     # Should return "j j"
# test string_part function GREEK
#string_part("kappa lambda", "last", 1)       # Should return "lambda"
#string_part("xi xi omicron omicron", "first", 2)  # Should return "xi xi"
#string_part("iota kappa kappa", "last", 2)     # Should return "kappa kappa"

literal_rule <- function(itemid, B, C) {
  alt_D = 'other'
  # Extract based on 'part' and 'num_letters'
  if (itemid == 101) { 
    # successor(all, 1) # a	b, j	k => b
    part_B = string_part(B, "last", 1)
    alt_D = part_B
  } else if (itemid == 102) { 
    # repetition(second, 2) # c d	c d d, j k	j k k => j d d
    part_B = string_part(B, "last", 2)
    part_C = string_part(C, "first", 1)
    alt_D = paste(part_C, part_B)
  } else if (itemid == 1001) { 
    # successor(second, 1) # a b	a c, g h	g i => g c
    part_B = string_part(B, "last", 1)
    part_C = string_part(C, "first", 1)
    alt_D = paste(part_C, part_B)
  } else if (itemid == 1002) {
    # successor(second, 1), repetition(all, 2) # c d	c c e e, m n	m m o o => m m e e
    part_B = string_part(B, "last", 2)
    part_C = repetition(string_part(C, "first", 1), "first", 2)
    alt_D = paste(part_C, part_B)
  } else if (itemid == 1003) { 
    # successor(second, 2) # e f	e h k l	k n => k h
    part_B = string_part(B, "last", 1)
    part_C = string_part(C, "first", 1)
    alt_D = paste(part_C, part_B)
  } else if (itemid == 1004) { 
    # successor(second, 1), repetition(second, 2) # d e	d f f, g h	g i i => g f f
    part_B = string_part(B, "last", 2)
    part_C = string_part(C, "first", 1)
    alt_D = paste(part_C, part_B)
  } else if (itemid == 1005) { 
    # predecessor(first, 1) # c d	b d 
    # repetition(all, 2) m m n n	l l n n => b b n n
    part_B = repetition(string_part(B, "first", 1), "first", 2)
    part_C = string_part(C, "last", 2)
    alt_D = paste(part_B, part_C)
  } else {
    stop("The 'part' argument must be either 'first' or 'last'.")
  }
  return(alt_D)
}
# tests literal_rule function
# 101 a	b, j	k => b
#literal_rule(101, 'b', 'j')
# 102 c d	c d d, j k	j k k => j d d
#literal_rule(102, 'c d d', 'j k')
# 1001 a b	a c, g h	g i => g c
#literal_rule(1001, "a c", "g h")
# 1002 # c d	c c e e, m n	m m o o => m m e e
#literal_rule(1002, "c c e e", "m n")
# 1003 # e f	e h k l	k n => k h
#literal_rule(1003, "e h", "k l")
# 1004 # d e	d f f, g h	g i i => g f f
#literal_rule(1004, "d f f", "g h")
# 1005 # c d	b d, m m n n	l l n n => b b n n
#literal_rule(1005, "b d", "m m n n")
# tests literal_rule function in GREEK
# 101 alpha	beta, kappa	lambda => beta
#literal_rule(101, 'beta', 'kappa')
# 102 gamma d	gamma delta delta, kappa lambda	kappa lambda lambda => kappa delta delta
#literal_rule(102, 'gamma delta delta', 'kappa lambda')
# 1001 alpha beta	alpha gamma, eta theta	eta iota => eta gamma
#literal_rule(1001, "alpha gamma", "eta theta")
# 1002 # gamma delta	gamma gamma epsilon epsilon, nu xi	nu nu omicron omicron => nu nu epsilon epsilon
#literal_rule(1002, "gamma gamma epsilon epsilon", "nu xi")
# 1003 # epsilon zeta	epsilon theta lambda mu	lambda xi => lambda theta
#literal_rule(1003, "epsilon theta", "lambda mu")
# 1004 # delta epsilon	delta zeta zeta, eta theta	eta iota iota => eta zeta zeta
#literal_rule(1004, "delta zeta zeta", "eta theta")
# 1005 # gamma delta	beta delta, nu nu xi xi	mu mu xi xi => beta beta xi xi
#literal_rule(1005, "beta delta", "nu nu xi xi")

one_rule_repetition <- function(itemid, C) {
  if (itemid == 1002) {
    # successor(second, 1), repetition(all, 2) # c d	c c e e, m n	m m o o => m m n n
    return(repetition(C, "all", 2))
  } else if (itemid == 1004) { 
    # successor(second, 1), repetition(second, 2) # d e	d f f, g h	g i i => g h h
    return(repetition(C, "last", 2))
  } else {
    return('')
  }
}
# test one_rule_repetition
#one_rule_repetition(1002, 'alpha beta') # should return alpha alpha beta beta
#one_rule_repetition(1004, 'alpha beta') # should return alpha beta beta
#one_rule_repetition(1005, 'alpha beta') # should return ''

one_rule_predsuc <- function(itemid, C, alphabet) {
  if (itemid == 1002) {
      # successor(second, 1), repetition(all, 2) # c d	c c e e, m n	m m o o => m o
      return(successor(alphabet, C, "last", 1))
  } else if (itemid == 1003) { 
    # successor(second, 2) # e f	e h k l	k n => k m
    return(successor(alphabet, C, "last", 1))
  } else if (itemid == 1004) { 
    # successor(second, 1), repetition(second, 2) # d e	d f f, g h	g i i => g i
    return(successor(alphabet, C, "last", 1))
  } else if (itemid == 1005) { 
    # predecessor(first, 1) # c d	b d 
    # repetition(all, 2) m m n n	l l n n => l l m m
    first_part <- predecessor(alphabet, string_part(C, "first", 1), "first", 1)
    second_part <- predecessor(alphabet, string_part(C, "last", 1), "first", 1)
    both_parts <- paste(first_part, second_part)
    return(repetition(both_parts, "all", 2))
  } else {
    return('')
  }
}
# test one rule predsuc
#one_rule_predsuc(1001, 'beta gamma', 'Greek') # should return NA
#one_rule_predsuc(1002, 'beta gamma', 'Greek') # should return beta delta
#one_rule_predsuc(1003, 'beta gamma', 'Greek') # should return beta delta
#one_rule_predsuc(1004, 'beta gamma', 'Greek') # should return beta delta
#one_rule_predsuc(1005, 'beta beta gamma gamma', 'Greek') # should return alpha alpha beta beta

# repetition function
repetition <- function(string, which_word, num_repeats) {
  # Split the input string into individual words
  words <- unlist(strsplit(string, " "))
  
  # Define the repetition based on 'which_word'
  if (which_word == "first") {
    # Repeat the first word
    repeated_part <- rep(words[1], num_repeats)
    result <- c(repeated_part, words[-1])
  } else if (which_word == "last") {
    # Repeat the last word
    repeated_part <- rep(words[length(words)], num_repeats)
    result <- c(words[-length(words)], repeated_part)
  } else if (which_word == "all") {
    # Repeat all words
    result <- paste(rep(strsplit(string, " ")[[1]], each = num_repeats), collapse = " ")
  } else {
    stop("Parameter 'which_word' should be 'first', 'last', or 'all'")
  }
  
  # Combine the result into a single string
  new_string <- paste(result, collapse = " ")
  
  return(new_string)
}
# Test repetition 
#repetition('j k', 'last', 2)  # Should print "j k k"
#repetition('j k', 'first', 3) # Should print "j j j k"
#repetition('j k', 'all', 2)   # Should print "j j k k"
#repetition('theta iota', 'all', 2)   # Should print "theta theta iota iota"

# successor function
successor <- function(domain, string, which_char, shift_dist) {
  # Define the alphabet based on the domain
  if (domain == "Latin") {
    alphabet <- letters
  } else if (domain == "Greek") {
    alphabet <- c(
      "alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", 
      "iota", "kappa", "lambda", "mu", "nu", "xi", "omicron", "pi", 
      "rho", "sigma", "tau", "upsilon", "phi", "chi", "psi", "omega"
    )
    string <- recode_greek_to_latin(string)
    alphabet <- recode_greek_to_latin(alphabet)
  } else if (domain == "Symbol") {
    alphabet <- c("*", "@", "%", "!", "^", "#", "~", "$", "{", "=", ":", ")")
  } else {
    stop("Only 'Latin', 'Greek', and 'Symbol' domains are supported.")
  }
  
  # Split the string into individual words
  letters <- unlist(strsplit(string, " "))
  
  # Identify which word and character to modify
  if (which_char == "last") {
    letter_to_modify <- length(letters)  # the last word
  } else if (which_char == "first") {
    letter_to_modify <- 1  # the first word
  } else {
    stop("Parameter 'which_char' should be either 'last' or 'first'")
  }
  
  # Identify the letter to shift
  char <- if (which_char == "first") {
    substr(letters[letter_to_modify], 1, 1)
  } else {
    substr(letters[letter_to_modify], nchar(letters[letter_to_modify]), nchar(letters[letter_to_modify]))
  }
  
  # Find the position of the character in the alphabet
  char_pos <- match(char, alphabet)
  
  # Check if the character is in the alphabet
  if (is.na(char_pos)) {
    stop("Character not in the selected alphabet.")
  }
  
  # Calculate new position with wrap-around for forward shift
  new_pos <- (char_pos + shift_dist - 1) %% length(alphabet) + 1
  new_char <- alphabet[new_pos]
  
  # Replace the specified character of the identified word
  if (which_char == "first") {
    letters[letter_to_modify] <- paste0(new_char, substr(letters[letter_to_modify], 2, nchar(letters[letter_to_modify])))
  } else {
    letters[letter_to_modify] <- paste0(substr(letters[letter_to_modify], 1, nchar(letters[letter_to_modify]) - 1), new_char)
  }
  
  # Combine words back into a single string
  new_string <- paste(letters, collapse = " ")
  
  # Recode Greek strings back to Greek letters
  if (domain == "Greek") {
    new_string <- recode_latin_to_greek(new_string)
  } 
  
  return(new_string)
}

# Test successor with Latin alphabet
#cat(successor(domain = 'Latin', string = 'g h', which_char = "last", shift_dist = 1), "\n") # Should print "g i"
#cat(successor(domain = 'Latin', string = 'g h', which_char = "last", shift_dist = 2), "\n") # Should print "g j"
# Test successor with Greek alphabet
#cat(successor(domain = 'Greek', string = 'alpha beta', which_char = "first", shift_dist = 1), "\n") # Should print "beta beta"
#cat(successor(domain = 'Greek', string = 'gamma delta', which_char = "first", shift_dist = 2), "\n") # Should print "epsilon delta"
# Test successor with Symbol domain
#cat(successor(domain = 'Symbol', string = '* @', which_char = "first", shift_dist = 1), "\n") # Should print "@ @"
#cat(successor(domain = 'Symbol', string = '@ %', which_char = "first", shift_dist = 2), "\n") # Should print "! %"

predecessor <- function(domain, string, which_char, shift_dist) {
  # Define the Latin alphabet
  if (domain == "Latin") {
    alphabet <- letters
  } else if (domain == "Greek") {
    alphabet <- c(
      "alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", 
      "iota", "kappa", "lambda", "mu", "nu", "xi", "omicron", "pi", 
      "rho", "sigma", "tau", "upsilon", "phi", "chi", "psi", "omega"
    )
    string <- recode_greek_to_latin(string)
    alphabet <- recode_greek_to_latin(alphabet)
  } else if (domain == "Symbol") {
    alphabet <- c("*", "@", "%", "!", "^", "#", "~", "$", "{", "=", ":", ")")
  } else {
    stop("Only 'Latin' and 'Greek' domains are supported.")
  }
  # Split the string into individual words
  letters <- unlist(strsplit(string, " "))
  
  # Identify which word and character to modify
  if (which_char == "last") {
    letter_to_modify <- length(letters)  # the last word
  } else if (which_char == "first") {
    letter_to_modify <- 1  # the first word
  } else {
    stop("Parameter 'which_char' should be either 'last' or 'first'")
  }
  
  # Identify the letter to shift
  char <- substr(letters[letter_to_modify], nchar(letters[letter_to_modify]), nchar(letters[letter_to_modify]))
  if (which_char == "first") {
    char <- substr(letters[letter_to_modify], 1, 1)
  } else {
    char <- substr(letters[letter_to_modify], nchar(letters[letter_to_modify]), nchar(letters[letter_to_modify]))
  }
  
  # Find the position of the character in the alphabet
  char_pos <- match(char, alphabet)
  
  # Check if the character is in the alphabet
  if (is.na(char_pos)) {
    return('')
  }
  
  # Calculate new position with wrap-around for backwards shift
  new_pos <- (char_pos - shift_dist - 1) %% length(alphabet) + 1
  new_char <- alphabet[new_pos]
  
  # Replace the specified character of the identified word
  if (which_char == "first") {
    letters[letter_to_modify] <- paste0(new_char, substr(letters[letter_to_modify], 2, nchar(letters[letter_to_modify])))
  } else {
    letters[letter_to_modify] <- paste0(substr(letters[letter_to_modify], 1, nchar(letters[letter_to_modify]) - 1), new_char)
  }
  
  # Combine words back into a single string
  new_string <- paste(letters, collapse = " ")
  
  # Recode Greek strings back to Greek letters
  if (domain == "Greek") {
    new_string <- recode_latin_to_greek(new_string)
  } 
  
  return(new_string)
}
# Test predecessor with Latin alphabet
#cat(predecessor(domain = 'Latin', string = 'g h', which_char = "first", shift_dist = 1), "\n") # Should print "f h"
#cat(predecessor(domain = 'Latin', string = 'g h', which_char = "first", shift_dist = 2), "\n") # Should print "e h"
# Test predecessor with Greek alphabet
#cat(predecessor(domain = 'Greek', string = 'alpha beta', which_char = "first", shift_dist = 1), "\n") # Should print "omega beta"
#cat(predecessor(domain = 'Greek', string = 'gamma delta', which_char = "first", shift_dist = 2), "\n") # Should print "epsilon delta"
# Test predecessor with Symbol domain
#cat(predecessor(domain = 'Symbol', string = '* @', which_char = "first", shift_dist = 1), "\n") # Should print ") @"
#cat(predecessor(domain = 'Symbol', string = '% !', which_char = "first", shift_dist = 2), "\n") # Should print "* !"
