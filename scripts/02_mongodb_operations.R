# MongoDB Operations - Store and Retrieve Tweets
library(mongolite)
library(dplyr)

# ============================================
# PART 1: CONNECT TO MONGODB
# ============================================

# Connect to MongoDB (make sure MongoDB is running)
mongo_tweets <- mongo(
  collection = "tweets",
  db = "social_media_db",
  url = "mongodb://localhost:27017"
)

# Check connection
cat("✅ Connected to MongoDB\n")

# ============================================
# PART 2: LOAD DATA FROM CSV
# ============================================

# Read the CSV file we created
tweets_data <- read.csv("raw_tweets.csv", stringsAsFactors = FALSE)

# Convert timestamp to proper date format
tweets_data$timestamp <- as.POSIXct(tweets_data$timestamp)

cat("📊 Loaded", nrow(tweets_data), "tweets from CSV\n")

# ============================================
# PART 3: INSERT DATA INTO MONGODB
# ============================================

# Clear existing data (optional - for fresh start)
mongo_tweets$drop()
cat("🗑️  Cleared existing collection\n")

# Insert all tweets
mongo_tweets$insert(tweets_data)
cat("✅ Inserted", nrow(tweets_data), "tweets into MongoDB\n")

# ============================================
# PART 4: QUERY OPERATIONS
# ============================================

# Count total documents
total_count <- mongo_tweets$count()
cat("\n📈 Total tweets in database:", total_count, "\n")

# Example 1: Find tweets with high engagement (likes > 70)
high_engagement <- mongo_tweets$find(
  query = '{"likes": {"$gt": 70}}',
  fields = '{"text": true, "likes": true, "retweets": true}'
)
cat("\n🔥 Found", nrow(high_engagement), "high-engagement tweets\n")
print(head(high_engagement, 3))

# Example 2: Find tweets from specific location
location_tweets <- mongo_tweets$find(
  query = '{"location": "Mumbai"}',
  limit = 5
)
cat("\n📍 Sample tweets from Mumbai:\n")
print(location_tweets$text[1:3])

# Example 3: Count tweets by location (Aggregation)
location_counts <- mongo_tweets$aggregate('[
  {"$group": {
    "_id": "$location",
    "count": {"$sum": 1},
    "avg_likes": {"$avg": "$likes"}
  }},
  {"$sort": {"count": -1}}
]')
cat("\n🌍 Tweets by location:\n")
print(location_counts)

# Example 4: Find tweets in date range
date_range_tweets <- mongo_tweets$find(
  query = '{
    "timestamp": {
      "$gte": {"$date": "2024-06-01T00:00:00Z"},
      "$lt": {"$date": "2024-07-01T00:00:00Z"}
    }
  }'
)
cat("\n📅 Tweets in June 2024:", nrow(date_range_tweets), "\n")

# ============================================
# PART 5: UTILITY FUNCTIONS
# ============================================

# Function to retrieve all tweets
get_all_tweets <- function() {
  mongo_tweets$find()
}

# Function to add new tweet
add_tweet <- function(tweet_data) {
  mongo_tweets$insert(tweet_data)
  cat("✅ Tweet added successfully\n")
}

# Function to search tweets by keyword
search_tweets <- function(keyword) {
  query <- paste0('{"text": {"$regex": "', keyword, '", "$options": "i"}}')
  mongo_tweets$find(query = query)
}

# Test search function
iphone_tweets <- search_tweets("iPhone")
cat("\n🔍 Found", nrow(iphone_tweets), "tweets mentioning 'iPhone'\n")

# ============================================
# PART 6: EXPORT DATA FOR FURTHER PROCESSING
# ============================================

# Retrieve all tweets for analysis
all_tweets <- get_all_tweets()
write.csv(all_tweets, "tweets_from_mongodb.csv", row.names = FALSE)
cat("\n💾 Exported all tweets to 'tweets_from_mongodb.csv'\n")

cat("\n✅ MongoDB operations completed successfully!\n")
cat("\n📝 Available functions:\n")
cat("   - get_all_tweets(): Retrieve all tweets\n")
cat("   - add_tweet(data): Add new tweet\n")
cat("   - search_tweets(keyword): Search by keyword\n")