# Advanced Sentiment Analysis
library(dplyr)
library(syuzhet)
library(tidytext)
library(ggplot2)

# ============================================
# LOAD DATA
# ============================================

tweets <- read.csv("tweets_cleaned.csv", stringsAsFactors = FALSE)
cat("📊 Loaded", nrow(tweets), "tweets for sentiment analysis\n\n")

# ============================================
# METHOD 1: AFINN LEXICON (Score-based)
# ============================================

cat("=" , rep("=", 50), "\n")
cat("METHOD 1: AFINN SENTIMENT SCORING\n")
cat("=", rep("=", 50), "\n\n")

# Get AFINN sentiment scores (-5 to +5)
tweets$sentiment_afinn <- get_sentiment(tweets$cleaned_text, method = "afinn")

# Classify sentiment
tweets$sentiment_class_afinn <- ifelse(tweets$sentiment_afinn > 0, "Positive",
                                       ifelse(tweets$sentiment_afinn < 0, "Negative", 
                                              "Neutral"))

# Summary
cat("📊 AFINN Sentiment Distribution:\n")
table(tweets$sentiment_class_afinn) %>% print()

cat("\n📈 Average Sentiment Score:", 
    round(mean(tweets$sentiment_afinn), 3), "\n")

# ============================================
# METHOD 2: BING LEXICON (Binary)
# ============================================

cat("\n\n", "=", rep("=", 50), "\n")
cat("METHOD 2: BING SENTIMENT (Positive/Negative)\n")
cat("=", rep("=", 50), "\n\n")

# Get Bing sentiment
tweets$sentiment_bing <- get_sentiment(tweets$cleaned_text, method = "bing")

tweets$sentiment_class_bing <- ifelse(tweets$sentiment_bing > 0, "Positive",
                                      ifelse(tweets$sentiment_bing < 0, "Negative",
                                             "Neutral"))

cat("📊 BING Sentiment Distribution:\n")
table(tweets$sentiment_class_bing) %>% print()

# ============================================
# METHOD 3: NRC EMOTION LEXICON
# ============================================

cat("\n\n", "=", rep("=", 50), "\n")
cat("METHOD 3: NRC EMOTION ANALYSIS\n")
cat("=", rep("=", 50), "\n\n")

# Get NRC emotions for first 1000 tweets (faster processing)
sample_tweets <- tweets$cleaned_text[1:min(1000, nrow(tweets))]

cat("🔍 Analyzing emotions for", length(sample_tweets), "tweets...\n")
emotions <- get_nrc_sentiment(sample_tweets)

# Add emotions to tweets
tweets_with_emotions <- cbind(tweets[1:length(sample_tweets), ], emotions)

# Sum of each emotion
emotion_totals <- colSums(emotions)
cat("\n😊 Total Emotions Detected:\n")
print(emotion_totals)

# Most dominant emotion per tweet
tweets_with_emotions$dominant_emotion <- apply(emotions, 1, function(x) {
  if(sum(x) == 0) return("None")
  names(which.max(x))
})

cat("\n🎭 Most Common Emotions:\n")
table(tweets_with_emotions$dominant_emotion) %>% 
  sort(decreasing = TRUE) %>% 
  head(10) %>% 
  print()

# ============================================
# METHOD 4: SYUZHET METHOD
# ============================================

# ... (Continuing from where your provided file ended)

cat("4: SYUZHET SENTIMENT (Normalized Score)\n")
cat("=", rep("=", 50), "\n\n")

# Get Syuzhet sentiment (uses a normalized score between -1 and 1)
# We will use the full tweet set for this method.
sentiment_syuzhet <- get_sentiment(tweets$cleaned_text, method = "syuzhet")

# Add the new sentiment column to the tweets dataframe
tweets$sentiment_syuzhet <- sentiment_syuzhet

# Calculate the average sentiment score
avg_syuzhet_score <- round(mean(tweets$sentiment_syuzhet), 3)

cat("📈 Average Syuzhet Sentiment Score:", avg_syuzhet_score, "\n")

# Classify Syuzhet sentiment
tweets$sentiment_class_syuzhet <- ifelse(tweets$sentiment_syuzhet > 0.05, "Positive",
                                        ifelse(tweets$sentiment_syuzhet < -0.05, "Negative",
                                               "Neutral"))

cat("\n📊 Syuzhet Sentiment Distribution:\n")
table(tweets$sentiment_class_syuzhet) %>% print()

# ============================================
# METHOD 5: VISUALIZATION
# ============================================

cat("\n\n", "=", rep("=", 50), "\n")
cat("METHOD 5: VISUALIZING THE EMOTIONS\n")
cat("=", rep("=", 50), "\n\n")

# Re-run emotion totals from Method 3 (for clarity)
# Note: emotion_totals was based on a sample of 1000 tweets
emotion_totals <- colSums(emotions) 
emotion_df <- data.frame(
    emotion = names(emotion_totals),
    count = emotion_totals
)

cat("🖼️  Generating Emotion Bar Chart...\n")

# Create a bar chart of the emotion counts
emotion_plot <- ggplot(emotion_df, aes(x = reorder(emotion, count), y = count, fill = emotion)) +
    geom_bar(stat = "identity", show.legend = FALSE) +
    coord_flip() + # Flip coordinates for readability
    labs(
        title = "NRC Emotion Analysis (Based on Sample)",
        x = "Emotion",
        y = "Total Count"
    ) +
    theme_minimal() +
    scale_fill_brewer(palette = "Set3")

# Print the plot
print(emotion_plot)

# ============================================
# SAVE FINAL DATA
# ============================================

cat("\n\n", "=", rep("=", 50), "\n")
cat("SAVING FINAL DATA\n")
cat("=", rep("=", 50), "\n\n")

# Select key sentiment results to append to the main cleaned data
sentiment_results_final <- tweets %>%
  select(tweet_id, sentiment_afinn, sentiment_class_afinn, 
         sentiment_class_bing, sentiment_syuzhet, sentiment_class_syuzhet)

# Save the combined data for potential future use or reporting
write.csv(sentiment_results_final, "sentiment_results.csv", row.names = FALSE)

cat("💾 Saved detailed sentiment results to 'sentiment_results.csv'\n")
cat("\n✅ Advanced Sentiment Analysis completed successfully!\n")