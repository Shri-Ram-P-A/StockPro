import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'data_analyser.dart';
import 'news.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  String selectedStockSymbol = "^NSEI";

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        messages.add({'text': _controller.text, 'isUser': 'true'});
      });

      String response = await _getChatbotResponse(_controller.text,
          symbol: selectedStockSymbol);

      setState(() {
        messages
            .add({'text': response.replaceAll("**", ""), 'isUser': 'false'});
      });

      _controller.clear();
    }
  }

  // 🔹 Checks Flask RAG API first, falls back to Gemini if needed
  Future<String> _getChatbotResponse(String query, {String? symbol}) async {
    String ans = "";
    if (symbol != null && symbol.isNotEmpty) {
      final uri = Uri.parse(
          'http://10.11.9.122:8000/ask?symbol=$symbol&question=${Uri.encodeComponent(query)}'
          // 'http://10.0.2.2:5000/ask?symbol=$symbol&question=${Uri.encodeComponent(query)}'
          );
      
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse.containsKey("answer") &&
              jsonResponse["answer"] != "I don't know") {
            ans = jsonResponse["answer"];
          }
        }
      } catch (e) {
        print("Error fetching RAG response: $e");
      }
    }

    // 🔹 Gemini fallback if no valid RAG response
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'ENTER YOUR GEMINI API KEY',
    );

    String prompt = """
      You are a knowledgeable stock market, economics, and financial assistant with expertise in providing clear, factual, and helpful responses to stock market, economics, and financial inquiries. 
      Please answer the following question comprehensively but concisely, using evidence-based information and avoiding any personal opinions.
      Answer: $ans
      if the ans gives the proper output then expand the content and give answer. else answer for the question in your knownledge about the stock market, economics, or finance and so on.
      Question: $query

      If the question is unrelated to stock market, economics, or finance, respond with:
      "This AI model is designed to provide stock market, economics, and financial information only."
    """;

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "No reply";
    } catch (e) {
      print('Error fetching chatbot response: $e');
      return 'An error occurred while fetching the response.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Stock Chatbot',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/background.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                      top: 100, left: 16, right: 16, bottom: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    bool isUser = messages[index]['isUser'] == 'true';
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.blueAccent.withOpacity(0.8)
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          messages[index]['text'] ?? '',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.4),
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Data Analyser"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "News"),
        ],
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => StockAnalyzerPage()));
          } else if (index == 2) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => NewsPage()));
          } else if (index == 1) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => ChatScreen()));
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
