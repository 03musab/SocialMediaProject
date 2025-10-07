# Data Preprocessing & Cleaning
library(dplyr)
library(stringr)
library(tm)
library(tidytext)
library(SnowballC)

# ============================================
# LOAD DATA
# ============================================

tweets <- read.csv("raw_tweets.csv", stringsAsFactors = FALSE)
cat("📊 Loaded", nrow(tweets), "tweets\n")

# ============================================
# TEXT CLEANING FUNCTIONS
# ============================================

clean_text <- function(text) {
  # Convert to lowercase
  text <- tolower(text)
  
  # Remove URLs
  text <- str_remove_all(text, "http\\S+|www\\S+")
  
  # Remove mentions (@username)
  text <- str_remove_all(text, "@\\w+")
  
  # Remove hashtags (but keep the word)
  text <- str_remove_all(text, "#")
  
  # Remove numbers
  text <- str_remove_all(text, "\\d+")
  
  # Remove punctuation
  text <- str_remove_all(text, "[[:punct:]]")
  
  # Remove extra whitespaces
  text <- str_squish(text)
  
  return(text)
}

# ============================================
# APPLY CLEANING
# ============================================

cat("\n🧹 Cleaning tweets...\n")

# Store original text
tweets$original_text <- tweets$text

# Clean text
tweets$cleaned_text <- sapply(tweets$text, clean_text)

# Show before/after examples
cat("\n📝 Before and After Cleaning:\n")
cat("\nOriginal 1:", tweets$original_text[1], "\n")
cat("Cleaned 1:", tweets$cleaned_text[1], "\n")
cat("\nOriginal 2:", tweets$original_text[5], "\n")
cat("Cleaned 2:", tweets$cleaned_text[5], "\n")

# ============================================
# TOKENIZATION & STOP WORDS REMOVAL
# ============================================

cat("\n🔤 Tokenizing and removing stop words...\n")

# Get stop words
data("stop_words")

# Tokenize tweets
tweets_tokens <- tweets %>%
  select(tweet_id, cleaned_text) %>%
  unnest_tokens(word, cleaned_text)

# Remove stop words
tweets_tokens <- tweets_tokens %>%
  anti_join(stop_words, by = "word")

cat("✅ Tokenization complete\n")
cat("Total words after cleaning:", nrow(tweets_tokens), "\n")

# ============================================
# WORD FREQUENCY ANALYSIS
# ============================================

cat("\n📊 Analyzing word frequencies...\n")

word_freq <- tweets_tokens %>%
  count(word, sort = TRUE)

cat("\n🔝 Top 20 Most Frequent Words:\n")
print(head(word_freq, 20))

# ============================================
# STEMMING (Optional but recommended)
# ============================================

cat("\n🌿 Applying stemming...\n")

tweets_tokens$stemmed_word <- wordStem(tweets_tokens$word, language = "english")

# Word frequency after stemming
word_freq_stemmed <- tweets_tokens %>%
  count(stemmed_word, sort = TRUE)

cat("\n🔝 Top 20 Words After Stemming:\n")
print(head(word_freq_stemmed, 20))

# ============================================
# CREATE DOCUMENT-TERM MATRIX (for advanced analysis)
# ============================================

cat("\n📋 Creating Document-Term Matrix...\n")

# Create corpus
corpus <- Corpus(VectorSource(tweets$cleaned_text))

# Create DTM
dtm <- DocumentTermMatrix(corpus)
cat("DTM dimensions:", dim(dtm)[1], "documents x", dim(dtm)[2], "terms\n")

# Remove sparse terms (appear in < 1% of documents)
dtm_reduced <- removeSparseTerms(dtm, 0.99)
cat("Reduced DTM:", dim(dtm_reduced)[1], "documents x", dim(dtm_reduced)[2], "terms\n")

# ============================================
# SAVE CLEANED DATA
# ============================================

# Save cleaned tweets
write.csv(tweets, "tweets_cleaned.csv", row.names = FALSE)
cat("\n💾 Saved cleaned tweets to 'tweets_cleaned.csv'\n")

# Save word frequencies
write.csv(word_freq, "word_frequencies.csv", row.names = FALSE)
cat("💾 Saved word frequencies to 'word_frequencies.csv'\n")

# ============================================
# DATA QUALITY REPORT
# ============================================

cat("\n", paste(rep("=", 50), collapse = ""), "\n")
cat("📊 DATA QUALITY REPORT\n")
cat("\n", paste(rep("=", 50), collapse = ""), "\n")

cat("\n✅ Original tweets:", nrow(tweets), "\n")
cat("✅ Tweets after cleaning:", nrow(tweets), "\n")
cat("✅ Unique words:", nrow(word_freq), "\n")
cat("✅ Average words per tweet:", 
    round(nrow(tweets_tokens) / nrow(tweets), 2), "\n")

# Check for empty tweets after cleaning
empty_tweets <- sum(tweets$cleaned_text == "")
cat("⚠️  Empty tweets after cleaning:", empty_tweets, "\n")

# Remove empty tweets if any
if(empty_tweets > 0) {
  tweets <- tweets %>% filter(cleaned_text != "")
  cat("🧹 Removed", empty_tweets, "empty tweets\n")
  write.csv(tweets, "tweets_cleaned.csv", row.names = FALSE)
}

cat("\n✅ Preprocessing completed successfully!\n")