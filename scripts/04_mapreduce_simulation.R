# MapReduce Simulation in R
library(dplyr)
library(parallel)
library(foreach)
library(doParallel)

# ============================================
# LOAD CLEANED DATA
# ============================================

tweets <- read.csv("tweets_cleaned.csv", stringsAsFactors = FALSE)
cat("📊 Loaded", nrow(tweets), "cleaned tweets\n")

# ============================================
# SETUP PARALLEL PROCESSING
# ============================================

# Detect number of cores
n_cores <- detectCores() - 1  # Leave one core free
cat("💻 Using", n_cores, "CPU cores for parallel processing\n")

# Register parallel backend
cl <- makeCluster(n_cores)
registerDoParallel(cl)

cat("✅ Parallel processing setup complete\n\n")

# ============================================
# MAPREDUCE 1: WORD COUNT
# ============================================

cat("=" , rep("=", 50), "\n")
cat("MAPREDUCE 1: WORD COUNT\n")
cat("=", rep("=", 50), "\n\n")

# MAP PHASE: Split data and count words in each chunk
map_word_count <- function(text_chunk) {
  # Split text into words
  words <- unlist(strsplit(text_chunk, " "))
  
  # Count each word
  word_counts <- table(words)
  
  # Return as data frame
  data.frame(
    word = names(word_counts),
    count = as.numeric(word_counts),
    stringsAsFactors = FALSE
  )
}

cat("🗺️  MAP Phase: Processing tweets in parallel...\n")
start_time <- Sys.time()

# Split tweets into chunks for parallel processing
chunk_size <- ceiling(nrow(tweets) / n_cores)
tweet_chunks <- split(tweets$cleaned_text, 
                      ceiling(seq_along(tweets$cleaned_text) / chunk_size))

# Apply MAP function in parallel
map_results <- foreach(chunk = tweet_chunks, .combine = rbind, 
                       .packages = c("dplyr")) %dopar% {
                         # Process each chunk
                         all_words <- unlist(strsplit(chunk, " "))
                         word_table <- table(all_words)
                         data.frame(word = names(word_table), 
                                    count = as.numeric(word_table),
                                    stringsAsFactors = FALSE)
                       }

map_time <- Sys.time() - start_time
cat("✅ MAP Phase completed in", round(map_time, 2), "seconds\n")

# REDUCE PHASE: Aggregate counts across all chunks
cat("\n🔄 REDUCE Phase: Aggregating results...\n")
start_time <- Sys.time()

word_count_final <- map_results %>%
  group_by(word) %>%
  summarise(total_count = sum(count)) %>%
  arrange(desc(total_count))

reduce_time <- Sys.time() - start_time
cat("✅ REDUCE Phase completed in", round(reduce_time, 2), "seconds\n")

cat("\n🔝 Top 15 Words:\n")
print(head(word_count_final, 15))

# ============================================
# MAPREDUCE 2: SENTIMENT AGGREGATION BY DATE
# ============================================

cat("\n\n", "=", rep("=", 50), "\n")
cat("MAPREDUCE 2: SENTIMENT AGGREGATION BY DATE\n")
cat("=", rep("=", 50), "\n\n")

# Load sentiment lexicon (simple positive/negative words)
positive_words <- c("love", "amazing", "best", "great", "excellent", 
                    "fantastic", "recommend", "worth", "outstanding", "good",
                    "wonderful", "perfect", "happy", "awesome", "brilliant")

negative_words <- c("disappointed", "worst", "poor", "terrible", "bad",
                    "waste", "frustrating", "broke", "regret", "awful",
                    "horrible", "useless", "pathetic", "disappointed", "hate")

# MAP PHASE: Calculate sentiment for each tweet
map_sentiment <- function(text_chunk, dates_chunk) {
  sentiments <- sapply(text_chunk, function(text) {
    words <- unlist(strsplit(text, " "))
    pos_count <- sum(words %in% positive_words)
    neg_count <- sum(words %in% negative_words)
    pos_count - neg_count  # Simple sentiment score
  })
  
  data.frame(
    date = as.Date(dates_chunk),
    sentiment = sentiments,
    stringsAsFactors = FALSE
  )
}

cat("🗺️  MAP Phase: Calculating sentiment scores...\n")
start_time <- Sys.time()

# Convert timestamp to date
tweets$date <- as.Date(tweets$timestamp)

# Split data into chunks
date_chunks <- split(tweets$date, 
                     ceiling(seq_along(tweets$date) / chunk_size))
text_chunks <- split(tweets$cleaned_text,
                     ceiling(seq_along(tweets$cleaned_text) / chunk_size))

# Apply MAP in parallel
sentiment_map_results <- foreach(i = 1:length(text_chunks), 
                                 .combine = rbind,
                                 .packages = c("dplyr")) %dopar% {
                                   map_sentiment(text_chunks[[i]], date_chunks[[i]])
                                 }

map_time <- Sys.time() - start_time
cat("✅ MAP Phase completed in", round(map_time, 2), "seconds\n")

# REDUCE PHASE: Aggregate sentiment by date
cat("\n🔄 REDUCE Phase: Aggregating sentiment by date...\n")
start_time <- Sys.time()

daily_sentiment <- sentiment_map_results %>%
  group_by(date) %>%
  summarise(
    avg_sentiment = mean(sentiment),
    total_tweets = n(),
    positive_tweets = sum(sentiment > 0),
    negative_tweets = sum(sentiment < 0),
    neutral_tweets = sum(sentiment == 0)
  ) %>%
  arrange(date)

reduce_time <- Sys.time() - start_time
cat("✅ REDUCE Phase completed in", round(reduce_time, 2), "seconds\n")

cat("\n📊 Daily Sentiment Summary (First 10 days):\n")
print(head(daily_sentiment, 10))

# ============================================
# MAPREDUCE 3: ENGAGEMENT ANALYSIS BY USER
# ============================================

cat("\n\n", "=", rep("=", 50), "\n")
cat("MAPREDUCE 3: USER ENGAGEMENT ANALYSIS\n")
cat("=", rep("=", 50), "\n\n")

# MAP PHASE: Calculate engagement per user
map_user_engagement <- function(user_chunk, likes_chunk, retweets_chunk) {
  data.frame(
    user = user_chunk,
    likes = likes_chunk,
    retweets = retweets_chunk,
    engagement = likes_chunk + retweets_chunk,
    stringsAsFactors = FALSE
  )
}

cat("🗺️  MAP Phase: Calculating user engagement...\n")

user_chunks <- split(tweets$user_id, 
                     ceiling(seq_along(tweets$user_id) / chunk_size))
likes_chunks <- split(tweets$likes,
                      ceiling(seq_along(tweets$likes) / chunk_size))
retweets_chunks <- split(tweets$retweets,
                         ceiling(seq_along(tweets$retweets) / chunk_size))

engagement_map <- foreach(i = 1:length(user_chunks),
                          .combine = rbind) %dopar% {
                            map_user_engagement(user_chunks[[i]], likes_chunks[[i]], retweets_chunks[[i]])
                          }

# REDUCE PHASE: Aggregate by user
cat("🔄 REDUCE Phase: Aggregating user stats...\n")

user_stats <- engagement_map %>%
  group_by(user) %>%
  summarise(
    total_tweets = n(),
    total_likes = sum(likes),
    total_retweets = sum(retweets),
    total_engagement = sum(engagement),
    avg_engagement = mean(engagement)
  ) %>%
  arrange(desc(total_engagement))

cat("\n🏆 Top 10 Most Engaged Users:\n")
print(head(user_stats, 10))

# ============================================
# SAVE RESULTS
# ============================================

cat("\n💾 Saving MapReduce results...\n")

write.csv(word_count_final, "mapreduce_word_count.csv", row.names = FALSE)
write.csv(daily_sentiment, "mapreduce_daily_sentiment.csv", row.names = FALSE)
write.csv(user_stats, "mapreduce_user_stats.csv", row.names = FALSE)

cat("✅ Saved word counts to 'mapreduce_word_count.csv'\n")
cat("✅ Saved daily sentiment to 'mapreduce_daily_sentiment.csv'\n")
cat("✅ Saved user stats to 'mapreduce_user_stats.csv'\n")

# ============================================
# PERFORMANCE SUMMARY
# ============================================

cat("\n", "=", rep("=", 50), "\n")
cat("⚡ PERFORMANCE SUMMARY\n")
cat("=", rep("=", 50), "\n\n")

cat("CPU Cores Used:", n_cores, "\n")
cat("Total Tweets Processed:", nrow(tweets), "\n")
cat("Unique Words Found:", nrow(word_count_final), "\n")
cat("Date Range:", nrow(daily_sentiment), "days\n")
cat("Unique Users:", nrow(user_stats), "\n")

# Stop parallel cluster
stopCluster(cl)

cat("\n✅ MapReduce simulation completed successfully!\n")