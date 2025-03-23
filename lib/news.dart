import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_analyser.dart';
import 'news.dart';
import 'chatbot.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List articles = [];
  bool isLoading = true;
  String errorMessage = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  bool isValidUrl(String? url) {
    return url != null &&
        url.isNotEmpty &&
        Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  Future<void> fetchNews() async {
    try {
      final url = 'http://localhost:8000/news';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() {
          articles = decodedData;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to fetch news. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Something went wrong. Check your connection.';
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Container(
                padding: const EdgeInsets.only(top: 60, left: 20),
                alignment: Alignment.centerLeft,
                child: Text(
                  'News',
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                        ? Center(
                            child: Text(errorMessage,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18)))
                        : articles.isEmpty
                            ? const Center(
                                child: Text("No articles found",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)))
                            : ListView.builder(
                                itemCount: articles.length,
                                itemBuilder: (context, index) {
                                  final article =
                                      articles[index] as Map<String, dynamic>;
                                  final title =
                                      article['title'] ?? 'No Title';
                                  final content = article['content'] ??
                                      'No Content Available';
                                  final imageUrl = article['urlToImage'];
                                  final articleUrl = article['url'];

                                  return Container(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      elevation: 5,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (isValidUrl(imageUrl))
                                            GestureDetector(
                                              onTap: () => isValidUrl(articleUrl)
                                                  ? _launchURL(articleUrl!)
                                                  : null,
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            15.0)),
                                                child: Image.network(
                                                  imageUrl!,
                                                  height: 200,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (context, error,
                                                          stackTrace) {
                                                    return Container();
                                                  },
                                                ),
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  content,
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton(
                                                    onPressed: () {
                                                      if (isValidUrl(
                                                          articleUrl)) {
                                                        _launchURL(
                                                            articleUrl!);
                                                      }
                                                    },
                                                    child: const Text(
                                                      "Go To News",
                                                      style: TextStyle(
                                                          color: Colors.blue),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => StockAnalyzerPage()));
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => NewsPage()));
          } else if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen()));
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
