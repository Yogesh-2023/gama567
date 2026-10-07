import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:new_sara/ChartScreen/ChartTableScreen.dart';
import 'package:new_sara/ulits/Constents.dart';

class Game {
  final int gameId;
  final String gameName;
  final String gameType;

  Game({required this.gameId, required this.gameName, required this.gameType});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      gameId: json['gameId'] ?? 0,
      gameName: json['gameName'] ?? 'Unknown Game',
      gameType: json['gameType'] ?? 'Unknown Type',
    );
  }
}

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<Game> allGames = [];
  List<Game> filteredGames = [];
  final TextEditingController searchController = TextEditingController();

  // Error handling
  String errorMessage = '';
  bool hasError = false;
  bool isLoading = true; // <-- Fix for Loader Issue

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    final url = '${Constant.apiEndpoint}chart-game-list';

    // Handle null values properly
    final String? accessToken = GetStorage().read('accessToken');
    final String? deviceId = GetStorage().read('deviceId');
    final String? deviceName = GetStorage().read('deviceName');

    // Check if user is authenticated
    if (accessToken == null || accessToken.isEmpty) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage =
            "User not authenticated. Please login first and try again.";
      });
      return;
    }

    print("================ FETCH GAMES DEBUG ================");
    print("API URL          : $url");
    print("deviceId         : $deviceId");
    print("deviceName       : $deviceName");
    print("accessToken      : $accessToken");
    print("===================================================");

    try {
      print("📡 API Request Sending...");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'deviceId': deviceId ?? '',
          'deviceName': deviceName ?? '',
          'accessStatus': '1',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print("📡 API HIT SUCCESSFULLY!");
      print("STATUS CODE  : ${response.statusCode}");
      print("RAW RESPONSE : ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['info'] == null) {
          print("❌ ERROR: 'info' key missing!!!");
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = "No data found";
          });
          return;
        }

        final List gamesJson = jsonData['info'];

        print("INFO LENGTH: ${gamesJson.length}");

        final games = gamesJson
            .map((e) => Game.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          allGames = List<Game>.from(games);
          filteredGames = allGames;
          isLoading = false;
          hasError = false;
        });

        print("✔ UI Updated. Games Loaded: ${allGames.length}");
      } else {
        print("❌ SERVER ERROR: ${response.statusCode}");
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      print("❌ EXCEPTION OCCURRED: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage =
            "Network error. Please check your internet connection and try again.";
      });
    }

    print("=============== END DEBUG =====================");
  }

  void filterSearch(String query) {
    final filtered = allGames
        .where(
          (game) => game.gameName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    setState(() {
      filteredGames = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Charts", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 44, // 👈 Smaller height
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSearch,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search chart',
                      prefixIcon: const Icon(Icons.search, size: 24),

                      // 👇 BLACK BORDER ADDED
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black, // BLACK BORDER
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black, // BLACK BORDER ON FOCUS
                          width: 2,
                        ),
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),

              // Body Content
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredGames.isEmpty
                    ? const Center(
                        child: Text(
                          "No Games Found",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredGames.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.4,
                            ),
                        itemBuilder: (context, index) {
                          final game = filteredGames[index];
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xffF95C33),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChartTableScreen(
                                    gameId: game.gameId,
                                    gameType: game.gameType,
                                    gameName: game.gameName,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              game.gameName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
