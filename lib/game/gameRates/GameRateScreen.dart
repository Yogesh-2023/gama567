import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class GameRateScreen extends StatefulWidget {
  const GameRateScreen({super.key});

  @override
  State<GameRateScreen> createState() => _GameRateScreenState();
}

class _GameRateScreenState extends State<GameRateScreen> {
  Map<String, dynamic>? gameRates;

  @override
  void initState() {
    super.initState();
    fetchGameRates();
  }

  Future<void> fetchGameRates() async {
    String token = GetStorage().read("accessToken");
    final url = Uri.parse('https://admin.gama567s.com/api/v1/game-rate');

    final response = await http.get(
      url,
      headers: {
        'deviceId': 'qwert',
        'deviceName': 'sm2233',
        'accessStatus': '1',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 🔥 RAW RESPONSE PRINT
    print("📌 Game Rate API Raw Response: ${response.body}");

    // 🔥 PRETTY JSON PRINT
    try {
      final pretty = const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(response.body));
      print("📌 Game Rate API Pretty JSON:\n$pretty");
    } catch (e) {
      print("❌ JSON Decode Error: $e");
    }

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      setState(() {
        gameRates = jsonData['info'];
      });
    } else {
      debugPrint('Failed to load game rates: ${response.statusCode}');
    }
  }


  Widget sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xffFE6335),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget rateCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(
          '$label - $value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget buildRates(String title, Map<String, dynamic> rates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(title),
        const SizedBox(height: 8),
        ...rates.entries.map((entry) {
          final label = formatLabel(entry.key);
          return rateCard(label, entry.value);
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  String formatLabel(String key) {
    switch (key) {
      case 'singleDigit':
        return 'Single';
      case 'jodi':
        return 'Jodi';
      case 'singlePanna':
        return 'Single Panna';
      case 'doublePanna':
        return 'Double Panna';
      case 'triplePanna':
        return 'Triple Panna';
      case 'halfSangam':
        return 'Half Sangam';
      case 'fullSangam':
        return 'Full Sangam';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: gameRates == null
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF2600)),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        buildRates(
                          'Game Win Ratio for All Bids',
                          gameRates!['gameRate'],
                        ),
                        buildRates(
                          'King Starline Game Win Ratio',
                          gameRates!['starlineGameRate'],
                        ),
                        buildRates(
                          'King Jackpot Win Ratio',
                          gameRates!['jackpotGameRate'],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
