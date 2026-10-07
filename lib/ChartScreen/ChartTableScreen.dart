import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../ulits/Constents.dart';

class ChartTableScreen extends StatefulWidget {
  final int gameId;
  final String gameType;
  final String gameName;

  const ChartTableScreen({
    super.key,
    required this.gameId,
    required this.gameType,
    required this.gameName,
  });

  @override
  State<ChartTableScreen> createState() => _ChartTableScreenState();
}

class _ChartTableScreenState extends State<ChartTableScreen> {
  List<dynamic> chartData = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchChartData();
  }

  Future<String?> _fetchGameTypeFromChartGameList() async {
    final box = GetStorage();
    final String? accessToken = box.read("accessToken");
    final String? deviceId = box.read("deviceId");
    final String? deviceName = box.read("deviceName");

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('${Constant.apiEndpoint}chart-game-list'),
        headers: {
          'deviceId': deviceId ?? '',
          'deviceName': deviceName ?? '',
          'accessStatus': '1',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['info'] != null) {
          final List gamesJson = jsonData['info'];
          for (var gameJson in gamesJson) {
            final gameId = gameJson['gameId'];
            if (gameId == widget.gameId) {
              return gameJson['gameType']?.toString() ?? '';
            }
          }
        }
      }
    } catch (e) {
      print("❌ Error fetching gameType from chart-game-list: $e");
    }
    return null;
  }

  Future<void> fetchChartData() async {
    final box = GetStorage();

    final String? token = box.read("accessToken");
    final String? registerId = box.read("registerId");
    final String? deviceId = box.read("deviceId");
    final String? deviceName = box.read("deviceName");

    // 🔥 Print EVERYTHING for Debugging
    print("\n=============== CHART TABLE DEBUG START ===============");
    print("API URL               : ${Constant.apiEndpoint}table-chart");
    print("Token                 : $token");
    print("Register ID           : $registerId");
    print("Device ID             : $deviceId");
    print("Device Name           : $deviceName");
    print("Sending Game ID       : ${widget.gameId}");
    print("Received Game Type    : ${widget.gameType}");

    // If gameType is empty, fetch it from chart-game-list API
    String gameTypeToUse = widget.gameType;
    if (gameTypeToUse.isEmpty) {
      print("⚠️ GameType is empty, fetching from chart-game-list API...");
      final fetchedGameType = await _fetchGameTypeFromChartGameList();
      if (fetchedGameType != null && fetchedGameType.isNotEmpty) {
        gameTypeToUse = fetchedGameType;
        print("✅ Fetched GameType: $gameTypeToUse");
      } else {
        print("❌ Could not fetch gameType from chart-game-list");
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = "Unable to fetch game type. Please try again.";
        });
        return;
      }
    }

    print("Using Game Type       : $gameTypeToUse");
    print("=======================================================\n");

    if (token == null || token.isEmpty) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = "Missing token. Please login again.";
      });
      print("❌ ERROR: ACCESS TOKEN MISSING");
      return;
    }

    try {
      print("📡 Sending POST Request...");

      final response = await http.post(
        Uri.parse('${Constant.apiEndpoint}table-chart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accessStatus': '1',
          'deviceId': deviceId ?? "",
          'deviceName': deviceName ?? "",
          'registerId': registerId ?? "",
        },
        body: jsonEncode({
          'gameId': widget.gameId,
          'gameType': gameTypeToUse,
        }),
      );

      print("📥 Response Received!");
      print("STATUS CODE : ${response.statusCode}");
      print("RAW BODY    : ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // Validate JSON
        if (json['status'] == true && json['info'] is List) {
          setState(() {
            chartData = json['info'];
            isLoading = false;
            hasError = false;
          });

          print("✔ SUCCESS: Loaded ${chartData.length} chart rows.");
        } else {
          print("❌ ERROR FROM SERVER: ${json['msg']}");
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = json['msg'] ?? "Invalid response from server.";
          });
        }
      } else {
        print("❌ SERVER STATUS FAILURE = ${response.statusCode}");
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = "Server Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = "Network error. Please try again.";
      });
    }

    print("=============== CHART TABLE DEBUG END =================\n");
  }

  Widget buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: Colors.black),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Open',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: Colors.black),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Jodi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: Colors.black),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDataRow(Map<String, dynamic> row) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                row['date'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                row['open'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                row['digit'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                row['close'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.gameName.isEmpty ? 'Charts' : widget.gameName,style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.red),
            )
                : hasError
                ? Center(
              child: Text(
                errorMessage,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
                : chartData.isEmpty
                ? const Center(
              child: Text(
                'No chart data found.',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
                : Column(
              children: [
                buildHeaderRow(),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: chartData.length,
                    itemBuilder: (context, index) {
                      return buildDataRow(chartData[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
