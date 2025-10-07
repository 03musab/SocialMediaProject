import dash
from dash import dcc
from dash import html
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

# --- 1. CONFIGURATION AND DATA LOADING ---
print("Loading data from R analysis outputs...")

try:
    # MapReduce Outputs (from 04_mapreduce_simulation.R)
    word_count_df = pd.read_csv("mapreduce_word_count.csv")
    daily_sentiment_df = pd.read_csv("mapreduce_daily_sentiment.csv")
    user_stats_df = pd.read_csv("mapreduce_user_stats.csv")
    
    # Preprocessing Output (for total stats)
    cleaned_tweets_df = pd.read_csv("tweets_cleaned.csv")
    
    # Sentiment & Emotion Output (from 05_sentiment_analysis.R)
    # We will use the 'emotion_totals' concept based on the data shape.
    # Note: Since the R script saved 'emotion_totals' to the console, 
    #       we'll simulate it by creating a simple table for display.
    #       If you want a dynamic chart, you'd need to save emotion_df 
    #       as a CSV in your R script. For this demo, we'll use a sample 
    #       of the data structure for NRC visualization.
    
    # Assume the first 1000 tweets for emotion analysis
    emotions_sample_df = pd.read_csv("tweets_cleaned.csv").head(1000)
    
    # Data Cleaning and Preparation
    daily_sentiment_df['date'] = pd.to_datetime(daily_sentiment_df['date'])
    
except FileNotFoundError as e:
    print(f"ERROR: A required CSV file was not found: {e}")
    print("Please ensure you have run 01, 03, 04, and 05 R scripts and the output files are in this directory.")
    exit()

# 2. Initialize the Dash app
app = dash.Dash(__name__, external_stylesheets=['https://codepen.io/chriddyp/pen/bWLwgP.css'])

# --- 3. VISUALIZATION FUNCTIONS ---

def create_word_count_chart(df):
    """Bar chart for top words."""
    top_words = df.head(20).sort_values(by='total_count', ascending=True)
    fig = px.bar(top_words, x='total_count', y='word', orientation='h', 
                 title='Top 20 Most Frequent Words (MapReduce 1)',
                 labels={'word': 'Word', 'total_count': 'Total Count'},
                 color_discrete_sequence=px.colors.sequential.Teal_r)
    return fig

def create_sentiment_line_chart(df):
    """Line chart for daily average sentiment."""
    fig = px.line(df, x='date', y='avg_sentiment', 
                  title='Daily Average Sentiment Trend (MapReduce 2)',
                  labels={'date': 'Date', 'avg_sentiment': 'Average Sentiment Score'},
                  line_shape='spline')
    fig.update_traces(line_color='#006699', marker=dict(size=5, color='#006699'))
    return fig

def create_user_engagement_chart(df):
    """Bar chart for top engaged users."""
    top_users = df.head(10).sort_values(by='total_engagement', ascending=True)
    fig = px.bar(top_users, x='total_engagement', y='user', orientation='h', 
                 title='Top 10 Most Engaged Users (MapReduce 3)',
                 labels={'user': 'User ID', 'total_engagement': 'Total Engagement (Likes + Retweets)'},
                 color_discrete_sequence=px.colors.sequential.Plasma_r)
    return fig

def create_summary_card():
    """Card with key summary statistics."""
    total_tweets = len(cleaned_tweets_df)
    unique_users = user_stats_df.shape[0]
    avg_likes = round(user_stats_df['total_likes'].sum() / total_tweets, 2)
    
    style = {'border': '1px solid #ddd', 'borderRadius': '5px', 'padding': '10px', 'margin': '10px', 'textAlign': 'center', 'backgroundColor': '#fff'}
    
    return html.Div(className='row', children=[
        html.Div(className='four columns', style=style, children=[
            html.H3(f"{total_tweets:,}", style={'color': '#003366'}),
            html.P("Total Tweets Processed")
        ]),
        html.Div(className='four columns', style=style, children=[
            html.H3(f"{unique_users:,}", style={'color': '#003366'}),
            html.P("Unique Users Analyzed")
        ]),
        html.Div(className='four columns', style=style, children=[
            html.H3(f"{avg_likes}", style={'color': '#003366'}),
            html.P("Avg. Likes per Tweet")
        ]),
    ])


# --- 4. DASHBOARD LAYOUT ---

app.layout = html.Div(style={'backgroundColor': '#f8f9fa', 'padding': '20px'}, children=[
    
    # Header
    html.H1("Social Media Analysis Dashboard", 
            style={'textAlign': 'center', 'color': '#003366', 'margin-bottom': '30px'}),
    
    html.H2("Key Metrics Summary", style={'color': '#333333', 'textAlign': 'center'}),
    create_summary_card(),

    html.Hr(), # Separator

    # First Row: MapReduce Results
    html.Div(className='row', children=[
        # Word Count (MapReduce 1)
        html.Div(className='six columns', children=[
            html.H3("Text Analysis", style={'color': '#333333'}),
            dcc.Graph(figure=create_word_count_chart(word_count_df))
        ]),
        
        # User Engagement (MapReduce 3)
        html.Div(className='six columns', children=[
            html.H3("User Performance", style={'color': '#333333'}),
            dcc.Graph(figure=create_user_engagement_chart(user_stats_df))
        ]),
    ]),
    
    html.Hr(), # Separator

    # Second Row: Sentiment & Time Series
    html.Div(className='row', children=[
        # Daily Sentiment (MapReduce 2) - Full width
        html.Div(className='twelve columns', children=[
            html.H3("Time-Series Analysis", style={'color': '#333333'}),
            dcc.Graph(figure=create_sentiment_line_chart(daily_sentiment_df))
        ])
    ]),
])

# --- 5. RUN THE APP ---
if __name__ == '__main__':
    print("\n🚀 Starting Dash app. Open http://127.0.0.1:8050/ in your browser.\n")
    app.run(debug=True)