import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'data_analyser.dart';
import 'news.dart';
import 'chatbot.dart';
import 'pages/login/login.dart';

class StockAnalyzerPage extends StatefulWidget {
  const StockAnalyzerPage({Key? key}) : super(key: key);

  @override
  _StockAnalyzerPageState createState() => _StockAnalyzerPageState();
}

class _StockAnalyzerPageState extends State<StockAnalyzerPage> {
  final TextEditingController _searchController = TextEditingController();
  String symbol = "Nifty 50";
  Map<String, dynamic>? stockData;
  List<FlSpot> stockChartData = [];
  List<FlSpot> predictedStockData = [];
  @override
  void initState() {
    super.initState();
    fetchStockData(symbol);
  }

  Future<void> fetchStockData(String newSymbol) async {
    setState(() {
      predictedStockData = [];
    });
      try {
      // Fetch actual stock data
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/stock-info?symbol=$newSymbol"), // For emulator
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          symbol = newSymbol;
          stockData = data;
          stockChartData = _parseChartData(data["data"]);
        });
      } else {
        throw Exception("Failed to load stock data");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        symbol = newSymbol;
        stockData = null;
        stockChartData = [];
      });
    }

    // Fetch predicted data
    try {
      final predictionResponse = await http.get(
        Uri.parse("http://10.0.2.2:5000/predict?symbol=$newSymbol"),
      );

      if (predictionResponse.statusCode == 200) {
        
        final predictionData = json.decode(predictionResponse.body);
        setState(() {
          predictedStockData = _parseChartData(predictionData["pred"]);
        });
      }
    } catch (e) {
      print("Error fetching predicted data: $e");
      setState(() {
        predictedStockData = [];
      });
    }
  }

  List<FlSpot> _parseChartData(List<dynamic> data) {
    return data
        .map((entry) => FlSpot(
              double.parse(entry[0].toString()),
              double.parse(entry[1].toString()),
            ))
        .toList();
  }

  void _showUserCard(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, size: 50, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(
              user?.email ?? "No User Signed In",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();  // Sign out user
                Navigator.pop(context);  // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),  // Navigate to Login Page
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Sign Out", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          /// **Main Content with Fixed Full-Screen Layout**
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.black.withOpacity(0.5), // Dark overlay
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// **Header**
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock Analyzer',
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showUserCard(context);
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Colors.black, size: 30),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// **Search Bar**
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                fetchStockData(value);
                              }
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Search stocks...',
                              prefix: SizedBox(width: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            if (_searchController.text.isNotEmpty) {
                              fetchStockData(_searchController.text);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Center(
                      child: Text(
                        "$symbol",
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// **Stock Chart**
                    Center(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white.withOpacity(0.1),
                        child: SizedBox(
                          width: 500,
                          height: 300,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: stockChartData.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white))
                                : LineChart(
                                    LineChartData(
                                      borderData: FlBorderData(show: false),
                                      gridData: FlGridData(show: true),
                                      titlesData: FlTitlesData(show: false),
                                      lineBarsData: [
                                        // Actual stock data (Green)
                                        LineChartBarData(
                                          spots: stockChartData,
                                          isCurved: true,
                                          color: const Color.fromARGB(
                                              255, 102, 255, 68),
                                          barWidth: 4,
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: const Color.fromARGB(
                                                    255, 146, 210, 225)
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        // Predicted stock data (Red)
                                        LineChartBarData(
                                          spots: predictedStockData,
                                          isCurved: true,
                                          color: Colors.red,
                                          barWidth: 4,
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Colors.red.withOpacity(0.3),
                                          ),
                                          dotData: FlDotData(
                                            show:
                                                true, // Shows dots for predicted points
                                            getDotPainter: (spot, percent,
                                                barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 4,
                                                color: Colors.red,
                                                strokeColor: Colors.white,
                                                strokeWidth: 2,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// **Stock Information**
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: stockData == null
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stock Information',
                                    style: GoogleFonts.nunito(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStockInfoRow("Company Name",
                                      stockData!["Company Name"]),
                                  _buildStockInfoRow(
                                      "Sector", stockData!["Sector"]),
                                  _buildStockInfoRow(
                                      "Industry", stockData!["Industry"]),
                                  _buildStockInfoRow(
                                      "Market Cap", stockData!["Market Cap"]),
                                  _buildStockInfoRow("52-Week High",
                                      stockData!["52-Week High"]),
                                  _buildStockInfoRow(
                                      "52-Week Low", stockData!["52-Week Low"]),
                                  _buildStockInfoRow(
                                      "P/E Ratio", stockData!["P/E Ratio"]),
                                  _buildStockInfoRow("Dividend Yield",
                                      stockData!["Dividend Yield"]),
                                  _buildStockInfoRow("EPS", stockData!["EPS"]),
                                  _buildStockInfoRow("ROE", stockData!["ROE"]),
                                  _buildStockInfoRow("Debt to Equity",
                                      stockData!["Debt to Equity Ratio"]),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Business Summary:",
                                    style: GoogleFonts.nunito(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    stockData!["Business Summary"] ?? "N/A",
                                    style: GoogleFonts.nunito(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        currentIndex: 0,
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

  Widget _buildStockInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        "$label: ${value ?? 'N/A'}",
        style: GoogleFonts.nunito(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
