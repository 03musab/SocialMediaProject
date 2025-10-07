# Generate Sample Social Media Data
# This creates a CSV file with 10,000 sample tweets

library(dplyr)
library(lubridate)

set.seed(123)  # For reproducibility

# Sample data parameters
n_tweets <- 10000

# Sample usernames
users <- paste0("user_", 1:500)

# Sample products/brands
brands <- c("iPhone", "Samsung", "Google", "Tesla", "Amazon", 
            "Netflix", "Spotify", "Nike", "Adidas", "Starbucks")

# Sample positive phrases
positive_phrases <- c(
  "I love this product!",
  "Amazing experience with",
  "Best purchase ever!",
  "Highly recommend",
  "Fantastic quality",
  "Exceeded my expectations",
  "Worth every penny",
  "Simply the best",
  "Can't stop using",
  "Outstanding service"
)

# Sample negative phrases
negative_phrases <- c(
  "Disappointed with",
  "Worst experience ever",
  "Not worth the money",
  "Poor quality",
  "Terrible customer service",
  "Would not recommend",
  "Complete waste of money",
  "Very frustrating",
  "Broke after one day",
  "Regret buying"
)

# Sample neutral phrases
neutral_phrases <- c(
  "Just bought",
  "Trying out",
  "Has anyone used",
  "What do you think about",
  "Considering buying",
  "Looking at",
  "Checking out",
  "Comparing",
  "Reading reviews about",
  "Anyone have experience with"
)

# Generate tweets
generate_tweet <- function() {
  sentiment_type <- sample(c("positive", "negative", "neutral"), 1, 
                           prob = c(0.5, 0.3, 0.2))
  brand <- sample(brands, 1)
  
  if (sentiment_type == "positive") {
    phrase <- sample(positive_phrases, 1)
    text <- paste(phrase, brand)
  } else if (sentiment_type == "negative") {
    phrase <- sample(negative_phrases, 1)
    text <- paste(phrase, brand)
  } else {
    phrase <- sample(neutral_phrases, 1)
    text <- paste(phrase, brand, "?")
  }
  
  # Add hashtags sometimes
  if (runif(1) > 0.5) {
    text <- paste(text, paste0("#", gsub(" ", "", brand)))
  }
  
  return(text)
}

# Create dataset
tweets_df <- data.frame(
  tweet_id = 1:n_tweets,
  user_id = sample(users, n_tweets, replace = TRUE),
  text = sapply(1:n_tweets, function(x) generate_tweet()),
  timestamp = seq(from = as.POSIXct("2024-01-01 00:00:00"),
                  to = as.POSIXct("2025-01-31 23:59:59"),
                  length.out = n_tweets),
  likes = rpois(n_tweets, lambda = 50),
  retweets = rpois(n_tweets, lambda = 20),
  location = sample(c("New York", "Los Angeles", "London", "Mumbai", 
                      "Tokyo", "Paris", "Sydney", "Toronto"), 
                    n_tweets, replace = TRUE),
  stringsAsFactors = FALSE
)

# Add some realistic variations
tweets_df$likes <- pmax(0, tweets_df$likes)
tweets_df$retweets <- pmax(0, tweets_df$retweets)

# Save to CSV
write.csv(tweets_df, "raw_tweets.csv", row.names = FALSE)

cat("✅ Generated", n_tweets, "sample tweets\n")
cat("📁 Saved to: raw_tweets.csv\n")
cat("\nFirst 5 tweets:\n")
print(head(tweets_df, 5))

# Summary statistics
cat("\n📊 Dataset Summary:\n")
cat("Total tweets:", nrow(tweets_df), "\n")
cat("Unique users:", length(unique(tweets_df$user_id)), "\n")
cat("Date range:", min(tweets_df$timestamp), "to", max(tweets_df$timestamp), "\n")
cat("Average likes per tweet:", round(mean(tweets_df$likes), 2), "\n")
cat("Average retweets:", round(mean(tweets_df$retweets), 2), "\n")