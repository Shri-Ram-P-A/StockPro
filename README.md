# STOCKPRO

## Development Dependencies  
- **Frontend**: Flutter  
- **Backend**: Python  
- **Server**: Local Server  

## Features in StockPro  

### 1. Login  
- Developed the login page with Flutter  
- Database storage using Firebase for high performance  

### 2. Data Analyzer  

#### Stock Prediction  
- Developed stock prediction using LSTM with TensorFlow  

#### Stock Data  
Fetching live stock market data, including:  
- **Current Price**  
- **Company Name**  
- **Sector**  
- **Industry**  
- **Market Cap**  
- **52-Week High**  
- **52-Week Low**  
- **P/E Ratio**  
- **Dividend Yield**  
- **EPS**  
- **ROE**  
- **Debt to Equity Ratio**  
- **Business Summary**  
- **Other relevant data**  

#### Company Summary  
- Summarizes information about the company  

### 3. Stock ChatBot  

- Developed the chatbot using the **Gemini Model**  
- Implemented a **RAG (Retrieval-Augmented Generation) model** for answering real-time stock market queries  

### 4. Stock News  

- Live updates from **News API**  
- Current stock market news updates  

---

## For Developers  

### Download the App  
You can download the StockPro app: **StockPro.apk**  

### Download the requirements

```sh
python -m venv venv
source venv/bin/activate  # On macOS/Linux
venv\Scripts\activate  # On Windows
pip install -r python-backend/requirements.txt

flutter pub get
```

### Running the Backend  
Use the following command to start the backend server with **Waitress**:  

```sh
waitress-serve --host 0.0.0.0 --port 8000 python_backend.main:app
```

## Contact

Linkedin: https://www.linkedin.com/in/shriram30704/


