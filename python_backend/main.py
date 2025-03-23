from flask import Flask, request, jsonify
import warnings
import os
import yfinance as yf
import numpy as np
from dotenv import load_dotenv
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, LSTM, Dropout
from newsapi import NewsApiClient
from langchain_community.document_loaders import UnstructuredURLLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_google_genai import GoogleGenerativeAIEmbeddings, ChatGoogleGenerativeAI
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate

warnings.filterwarnings("ignore")
app = Flask(__name__)

load_dotenv()
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

NEWS_API_KEY = os.getenv("NEWS_API")

retrievers = {}

def name(symbol):
    symbol = symbol.lower()
    stocks_dict = {
        "nifty 50": "^NSEI",
        "sensex": "^BSEI",
        "adani enterprises": "ADANIENT.NS",
        "adani ports": "ADANIPORTS.NS",
        "apollo hospitals": "APOLLOHOSP.NS",
        "asian paints": "ASIANPAINT.NS",
        "axis bank": "AXISBANK.NS",
        "bajaj auto": "BAJAJ-AUTO.NS",
        "bajaj finance": "BAJFINANCE.NS",
        "bajaj finserv": "BAJAJFINSV.NS",
        "bharat petroleum": "BPCL.NS",
        "bharti airtel": "BHARTIARTL.NS",
        "britannia": "BRITANNIA.NS",
        "cipla": "CIPLA.NS",
        "coal india": "COALINDIA.NS",
        "divi's laboratories": "DIVISLAB.NS",
        "dr reddy's": "DRREDDY.NS",
        "eicher motors": "EICHERMOT.NS",
        "grasim": "GRASIM.NS",
        "hcl technologies": "HCLTECH.NS",
        "hdfc bank": "HDFCBANK.NS",
        "hdfc life": "HDFCLIFE.NS",
        "hero motocorp": "HEROMOTOCO.NS",
        "hindalco": "HINDALCO.NS",
        "hindustan unilever": "HINDUNILVR.NS",
        "icici bank": "ICICIBANK.NS",
        "itc": "ITC.NS",
        "indusind bank": "INDUSINDBK.NS",
        "infosys": "INFY.NS",
        "jsw steel": "JSWSTEEL.NS",
        "kotak mahindra bank": "KOTAKBANK.NS",
        "ltimindtree": "LTIM.NS",
        "larsen & toubro": "LT.NS",
        "mahindra & mahindra": "M&M.NS",
        "maruti suzuki": "MARUTI.NS",
        "ntpc": "NTPC.NS",
        "nestle india": "NESTLEIND.NS",
        "ongc": "ONGC.NS",
        "power grid": "POWERGRID.NS",
        "reliance industries": "RELIANCE.NS",
        "sbi life": "SBILIFE.NS",
        "state bank of india": "SBIN.NS",
        "sun pharma": "SUNPHARMA.NS",
        "tcs": "TCS.NS",
        "tata consumer": "TATACONSUM.NS",
        "tata motors": "TATAMOTORS.NS",
        "tata steel": "TATASTEEL.NS",
        "tech mahindra": "TECHM.NS",
        "titan": "TITAN.NS",
        "upl": "UPL.NS",
        "ultratech cement": "ULTRACEMCO.NS",
        "wipro": "WIPRO.NS"
    }
    try:
        return stocks_dict[symbol] 
    except KeyError:
        return "^NSEI"


def create_dataset(dataset, time_step=60):
    """Prepare dataset for LSTM model."""
    dataX, dataY = [], []
    for i in range(len(dataset) - time_step):
        a = dataset[i:(i + time_step), 0]
        dataX.append(a)
        dataY.append(dataset[i + time_step, 0])
    return np.array(dataX), np.array(dataY)

@app.route('/ask', methods=['GET'])
def ask_question():
    """Answer stock-related questions using RAG approach."""
    ticker = request.args.get('symbol')
    question = request.args.get('question', '')
    
    if not ticker or not question:
        return jsonify({"error": "Symbol and question are required."}), 400
    
    retriever = retrievers.get(ticker)
    if not retriever:
        return jsonify({"error": f"No active chat session for {ticker}. Start with /start-chat?symbol={ticker}"}), 400

    context = retriever.get_relevant_documents(question)
    context_text = "\n".join([doc.page_content for doc in context])

    system_prompt = (
        "You are an AI stock assistant. Use the retrieved context to answer concisely.\n"
        "If you don't know the answer, say 'I don't know'.\n\n"
        f"Context:\n{context_text}"
    )

    chat_prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("human", question),
    ])

    model = ChatGoogleGenerativeAI(model="gemini-1.0-pro", convert_system_message_to_human=True)
    response = model.invoke(chat_prompt.format())

    return jsonify({"answer": response.content})

@app.route('/start',methods=['GET'])
def start():
    symbol = request.args.get('symbol', '^NSEI').strip()
    if not symbol:
        return jsonify({"error": "Stock symbol is required"}), 400
    
    stock = yf.Ticker(name(symbol))
    news = stock.news
    if not news:
        return jsonify({"error": "No news found for this stock."}), 400

    urls = [article['content']['canonicalUrl']['url'] for article in news]
    loader = UnstructuredURLLoader(urls=urls)
    data = loader.load()

    splitter = RecursiveCharacterTextSplitter(chunk_size=200, chunk_overlap=20)
    chunks = splitter.split_documents(data)

    embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
    vectors = FAISS.from_documents(chunks, embeddings)
    retriever = vectors.as_retriever()
    retrievers[symbol] = retriever

    return jsonify({"message": f"Chat session started for {symbol}. Use /ask?symbol={symbol}&question=your_question"})

@app.route('/stock-info', methods=['GET'])
def get_stock_info():
    symbol = request.args.get('symbol', '^NSEI').strip()
    if not symbol:
        return jsonify({"error": "Stock symbol is required"}), 400
    
    stock = yf.Ticker(name(symbol))
    info = stock.info
    df = stock.history(period="2mo")['Close'].values.tolist()

    month = [];t = 0
    for i in df[-30:]:
        month.append((t,i))
        t+=1

    stock_data = {
        "Current Price": info.get('currentPrice','N/A'),
        "Company Name": info.get('longName', 'N/A'),
        "Sector": info.get('sector', 'N/A'),
        "Industry": info.get('industry', 'N/A'),
        "Market Cap": info.get('marketCap', 'N/A'),
        "52-Week High": info.get('fiftyTwoWeekHigh', 'N/A'),
        "52-Week Low": info.get('fiftyTwoWeekLow', 'N/A'),
        "P/E Ratio": info.get('trailingPE', 'N/A'),
        "Dividend Yield": info.get('dividendYield', 'N/A'),
        "EPS": info.get('trailingEps', 'N/A'),
        "ROE": info.get('returnOnEquity', 'N/A'),
        "Debt to Equity Ratio": info.get('debtToEquity', 'N/A'),
        "Business Summary": info.get('longBusinessSummary', 'N/A'),
        "data": month,
    }
    
    return jsonify(stock_data)

@app.route("/predict", methods=['GET'])
def predict():
    symbol = request.args.get('symbol', '^NSEI').strip()
    if not symbol:
        return jsonify({"error": "Stock symbol is required"}), 400
    
    stock = yf.Ticker(name(symbol))
    df = stock.history(period="1y")['Close'].values

    scaler = MinMaxScaler(feature_range=(0, 1))
    train = scaler.fit_transform(df.reshape(-1, 1))
    x_train, y_train = create_dataset(train, 60)  # 60-day lookback
    X_train = x_train.reshape(x_train.shape[0], x_train.shape[1], 1)

    model = Sequential([
        LSTM(100, return_sequences=True, input_shape=(60, 1)),
        Dropout(0.2),
        LSTM(100, return_sequences=True),
        Dropout(0.2),
        LSTM(100),
        Dropout(0.2),
        Dense(50, activation='relu'),
        Dense(1)
    ])
    model.compile(loss='mae', optimizer='adam', metrics=['mse'])
    model.fit(X_train, y_train, epochs=100, batch_size=32, verbose=1)
    
    predictions = []
    t = train[-60:].copy()
    for _ in range(7):
        x_input = t.reshape(1, 60, 1)
        yhat = model.predict(x_input)
        predictions.append(yhat[0][0])
        t = np.append(t[1:], yhat[0][0])
    
    month1 = df[-30:].tolist()
    predict = scaler.inverse_transform(np.array(predictions).reshape(-1, 1)).flatten().tolist()

    pred = []
    month = []

    for i in range(30):
        month.append((i, month1[i])) 

    for i in range(7):
        pred.append((30 + i, predict[i])) 

    stock_data = {
        "Data": month,
        "pred": pred
    }
    return jsonify(stock_data)

@app.route('/news', methods=['GET', 'POST'])
def get_news():
    newsapi = NewsApiClient(api_key=NEWS_API_KEY)
    data = newsapi.get_everything(q="India Stock Market News", language="en", page_size=40)
    articles = data.get('articles', [])

    processed_articles = [
        {
            'title': article['title'],
            'urlToImage': article.get('urlToImage', ''),
            'content': article.get('content', '').replace("<ul><li>", "").replace("</li></ul>", "").replace("<li>", "").replace("</li>", "").replace("</ul>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", "").replace("<p>", "").replace("</p>", ""),
            'url': article['url']
        }
        for article in articles if article.get('urlToImage')
    ]
    return jsonify(processed_articles)

if __name__ == '__main__':
    app.run(debug=True)
