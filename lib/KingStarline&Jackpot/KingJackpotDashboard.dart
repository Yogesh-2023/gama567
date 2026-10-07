// import 'dart:convert';
// import 'dart:developer' as dev;
//
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:new_sara/Bids/KingJackpotResultHis/KingJackpotResultScreen.dart';
// import 'package:new_sara/KingStarline&Jackpot/JackpotJodiOptionsScreen.dart';
// import 'package:new_sara/components/KingJackpotBiddingClosedDialog.dart';
// import 'package:new_sara/ulits/curved_appbar.dart';
// import 'package:new_sara/ulits/curved_appbar2.dart';
//
// import '../Helper/TranslationHelper.dart';
// import '../ulits/Constents.dart';
//
// // New data model for game rates
// class GameRates {
//   final String singleDigit;
//   final String singlePanna;
//
//   GameRates({
//     required this.singleDigit,
//     required this.singlePanna,
//   });
//
//   factory GameRates.fromJson(Map<String, dynamic> json) {
//     return GameRates(
//       singleDigit: json['singleDigit'] ?? '10/0',
//       singlePanna: json['singlePanna'] ?? '10/0',
//     );
//   }
// }
//
// class KingJackpotDashboard extends StatefulWidget {
//   const KingJackpotDashboard({super.key});
//
//   @override
//   State<KingJackpotDashboard> createState() => _KingJackpotDashboardState();
// }
//
// class _KingJackpotDashboardState extends State<KingJackpotDashboard> {
//   late Future<JackpotGameData> futureGameData;
//   final String toLang = GetStorage().read('language') ?? 'en';
//   Map<String, String> _i18n = {};
//   int _totalJodiElements = 0;
//
//   // Game rates data
//   GameRates? _gameRates;
//   final GetStorage _storage = GetStorage();
//
//   Map<String, String> _buildHeaders(
//     String accessToken, {
//     String? deviceId,
//     String? deviceName,
//     bool accountStatus = true,
//   }) {
//     final now = DateTime.now();
//     return {
//       'deviceId':
//           deviceId ??
//           (_storage.read('deviceId')?.toString() ?? 'unknown_device'),
//       'deviceName':
//           deviceName ??
//           (_storage.read('deviceName')?.toString() ?? 'unknown_model'),
//       'accessStatus': accountStatus ? '1' : '0',
//       'Content-Type': 'application/json; charset=utf-8',
//       'Accept': 'application/json',
//       'Authorization': 'Bearer $accessToken',
//       // helpful for backend time reconciliation
//       'x-client-time': now.toIso8601String(),
//       'x-tz-offset-mins': now.timeZoneOffset.inMinutes.toString(),
//       'x-tz-name': now.timeZoneName,
//     };
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     futureGameData = fetchGameData();
//     _loadTranslations();
//     _fetchGameRates(); // Fetch game rates when initializing
//   }
//
//   String tr(String key) => _i18n[key] ?? key;
//
//   Future<void> _loadTranslations() async {
//     final keys = [
//       'King Jackpot',
//       'History',
//       'Jodi',
//       'Play Game',
//       'No data available.',
//       'Error:',
//       'Retry',
//       'View History',
//       'Jackpot Dashboard',
//     ];
//
//     try {
//       final results = await Future.wait(
//         keys.map((k) => TranslationHelper.translate(k, toLang)),
//       );
//       if (!mounted) return;
//       setState(() {
//         for (int i = 0; i < keys.length; i++) {
//           _i18n[keys[i]] = results[i];
//         }
//       });
//     } catch (_) {}
//   }
//
//   Future<JackpotGameData> fetchGameData() async {
//     final storage = GetStorage();
//     final String accessToken = storage.read('accessToken') ?? '';
//     final String registerId = storage.read('registerId') ?? '';
//     final String deviceId =
//         storage.read('deviceId')?.toString() ?? 'unknown_device';
//     final String deviceName =
//         storage.read('deviceName')?.toString() ?? 'unknown_model';
//     final bool accountStatus = (storage.read('accountStatus') ?? true) == true;
//
//     try {
//       final now = DateTime.now();
//       final uri = Uri.parse('${Constant.apiEndpoint}jackpot-game-list');
//       final res = await http
//           .post(
//             uri,
//             headers: {
//               'Content-Type': 'application/json; charset=utf-8',
//               'Accept': 'application/json',
//               'deviceId': deviceId,
//               'deviceName': deviceName,
//               'accessStatus': accountStatus ? '1' : '0',
//               'Authorization': 'Bearer $accessToken',
//               'x-client-time': now.toIso8601String(),
//               'x-tz-offset-mins': now.timeZoneOffset.inMinutes.toString(),
//               'x-tz-name': now.timeZoneName,
//             },
//             body: json.encode({'registerId': registerId}),
//           )
//           .timeout(const Duration(seconds: 20));
//
//       if (res.statusCode == 200) {
//         final data = jackpotGameDataFromJson(res.body);
//         if (data.info != null) {
//           _totalJodiElements = data.info!.length;
//           if (mounted) setState(() {});
//         }
//         return data;
//       }
//       throw Exception('Failed: ${res.statusCode}');
//     } catch (e) {
//       dev.log('[Jackpot] Error: $e', name: 'KingJackpot');
//       rethrow;
//     }
//   }
//
//   // New method to fetch game rates
//   Future<void> _fetchGameRates() async {
//     final String? accessToken = _storage.read('accessToken');
//     final String? registerId = _storage.read('registerId');
//     final bool accountStatus = (_storage.read('accountStatus') ?? true) == true;
//
//     if (accessToken == null || accessToken.isEmpty) {
//       dev.log('Error: Access token not found. Cannot fetch game rates.');
//       return;
//     }
//
//     final url = Uri.parse('${Constant.apiEndpoint}game-rate');
//     final headers = _buildHeaders(accessToken, accountStatus: accountStatus);
//
//     try {
//       final response = await http.get(url, headers: headers);
//
//       dev.log('Game Rates API Status: ${response.statusCode}');
//       dev.log('Game Rates API Body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData =
//             json.decode(response.body) as Map<String, dynamic>;
//
//         if (responseData['status'] == true && responseData['info'] != null) {
//           final info = responseData['info'] as Map<String, dynamic>;
//
//           // Extract jackpot game rates
//           if (info['jackpotGameRate'] != null) {
//             final jackpotRates =
//                 info['jackpotGameRate'] as Map<String, dynamic>;
//
//             if (!mounted) return;
//             setState(() {
//               _gameRates = GameRates.fromJson(jackpotRates);
//             });
//           }
//         }
//       }
//     } catch (e) {
//       dev.log('Exception during Game Rates API call: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CurvedAppBar2(title: 'Jackpot Dashboard'),
//
//       body: Column(
//         children: [
//           // Add the game rates section here
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
//             child: Column(
//               children: [
//                 SizedBox(height: 5),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         const Text(
//                           "Single Digit : ",
//                           style: TextStyle(color: Colors.black, fontSize: 14),
//                         ),
//                         Text(
//                           _gameRates?.singleDigit ?? "10/0",
//                           style: const TextStyle(
//                             color: Color(0xffFF2600),
//                             fontSize: 14,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         const Text(
//                           "Single Pana : ",
//                           style: TextStyle(color: Colors.black, fontSize: 14),
//                         ),
//                         Text(
//                           _gameRates?.singlePanna ?? "10/0",
//                           style: const TextStyle(
//                             color: Color(0xffFF2600),
//                             fontSize: 14,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           //  _buildRedHeader(),
//           _buildJodiChip(),
//           Padding(
//             padding: const EdgeInsets.only(left: 16.0),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Kalyan Jackpot',
//                 textAlign: TextAlign.left,
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600, // थोड़ा bold
//                 ),
//               ),
//             ),
//           ),
//
//           Expanded(
//             child: RefreshIndicator(
//               color: const Color(0xFFFF2600),
//               onRefresh: () async {
//                 setState(() => futureGameData = fetchGameData());
//                 await futureGameData;
//               },
//               child: FutureBuilder<JackpotGameData>(
//                 future: futureGameData,
//                 builder: (context, snap) {
//                   if (snap.connectionState == ConnectionState.waiting) {
//                     return const Center(
//                       child: CircularProgressIndicator(
//                         color: Color(0xFFFF2600),
//                       ),
//                     );
//                   }
//                   if (snap.hasError) {
//                     return _errorView(message: '${tr("Error:")} ${snap.error}');
//                   }
//                   final info = snap.data?.info;
//                   if (info == null || info.isEmpty) {
//                     return Center(child: Text(tr('No data available.')));
//                   }
//
//                   return GridView.builder(
//                     padding: const EdgeInsets.all(12),
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     itemCount: info.length,
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           childAspectRatio: 0.85,
//                           crossAxisSpacing: 14,
//                           mainAxisSpacing: 14,
//                         ),
//                     itemBuilder: (context, i) => _buildGameCard(info[i]),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRedHeader() {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.only(
//         top: MediaQuery.of(context).padding.top + 10,
//         bottom: 20,
//       ),
//       decoration: const BoxDecoration(
//         color: Color(0xFFFF2600),
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
//       ),
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(
//                     Icons.arrow_back_ios_new,
//                     color: Colors.white,
//                   ),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 Text(
//                   tr('Jackpot Dashboard'),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 21,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 TextButton(
//                   onPressed: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => KingJackpotResultScreen(),
//                     ),
//                   ),
//                   child: Text(
//                     tr('View History'),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 "Single Digit : ",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                 ),
//               ),
//               Text(
//                 _gameRates?.singleDigit ?? "10/0",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(width: 20),
//               const Text(
//                 "Single Pana : ",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                 ),
//               ),
//               Text(
//                 _gameRates?.singlePanna ?? "10/0",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildJodiChip() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           const Text(
//             "Total Games : ",
//             style: TextStyle(
//               color: Color(0xFFFF2600),
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//           Text(
//             "$_totalJodiElements",
//             style: const TextStyle(
//               color: Color(0xFFFF2600),
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGameCard(JackpotGameInfo g) {
//     final bool isClosed = g.statusText.toLowerCase().contains('closed');
//     final bool canPlay = g.playStatus && !isClosed;
//
//     final Color cardBg = isClosed
//         ? const Color(0xFFF6CFD0)
//         : const Color(0xFFDEEAD2);
//     final Color statusColor = isClosed
//         ? const Color(0xFFE91E1E)
//         : const Color(0xFF2E7D32);
//
//     return Container(
//       decoration: BoxDecoration(
//         color: cardBg,
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Stack(
//         children: [
//           // यही है आपकी "छोटी ऊपरी पतली लाइन" – बिल्कुल ओरिजिनल इमेज जैसी
//           Positioned(
//             left: 0,
//             top: 24,
//             child: Container(
//               width: 7, // बहुत पतली लाइन
//               height: 25, // सिर्फ ऊपर की तरफ (लगभग 52-58px काफी है)
//               decoration: BoxDecoration(
//                 color: isClosed
//                     ? const Color(0xFFE91E1E)
//                     : const Color(0xFF4CAF50),
//                 // borderRadius: const BorderRadius.only(
//                 //   topLeft: Radius.circular(18),
//                 //   bottomRight: Radius.circular(12),
//                 // ),
//               ),
//             ),
//           ),
//
//           // बाकी कार्ड कंटेंट
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               borderRadius: BorderRadius.circular(18),
//               onTap: canPlay
//                   ? () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => JackpotJodiOptionsScreen(
//                           title: 'Kalyan Jackpot, ${g.gameName}',
//                           gameTime: g.gameName,
//                           gameId: g.gameId,
//                           digitJodiStatus: false,
//                           sessionSelection: true,
//                         ),
//                       ),
//                     )
//                   : null,
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         const SizedBox(width: 20), // लाइन के नीचे थोड़ा स्पेस
//                         Image.asset(
//                           isClosed
//                               ? "assets/icons/stopwatch.png" // Closed icon
//                               : "assets/icons/chronometer.png", // Open icon
//                           width: 26,
//                           height: 26,
//                           //  color: isClosed ? const Color(0xFFE91E1E) : const Color(0xFFFF8C00),
//                         ),
//
//                         const SizedBox(width: 8),
//                         Text(
//                           g.gameName,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 4),
//                     Padding(
//                       padding: const EdgeInsets.only(left: 55.0),
//                       child: Text(
//                         "**",
//                         style: TextStyle(fontSize: 22, color: Colors.black87),
//                       ),
//                     ),
//
//                     const Spacer(),
//
//                     Center(
//                       child: Column(
//                         children: [
//                           Text(
//                             isClosed
//                                 ? "Betting is Closed"
//                                 : "Betting is Running",
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: statusColor,
//                               fontSize: 13.5,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           Text(
//                             isClosed ? "for Today" : "now",
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: statusColor,
//                               fontSize: 13.5,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     if (canPlay)
//                       Center(
//                         child: SizedBox(
//                           width: 130,
//                           child: ElevatedButton(
//                             onPressed: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => JackpotJodiOptionsScreen(
//                                   title: 'Kalyan Jackpot, ${g.gameName}',
//                                   gameTime: g.gameName,
//                                   gameId: g.gameId,
//                                   digitJodiStatus: false,
//                                   sessionSelection: true,
//                                 ),
//                               ),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF28A745),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                               padding: const EdgeInsets.symmetric(vertical: 14),
//                             ),
//                             child: const Text(
//                               "PLAY NOW",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                     else
//                       const SizedBox(height: 48),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _errorView({required String message}) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.error_outline, size: 50, color: Color(0xFFFF2600)),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => setState(() => futureGameData = fetchGameData()),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFFF2600),
//               ),
//               child: Text(
//                 tr('Retry'),
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ======================= MODELS (Same as before) =======================
//
// JackpotGameData jackpotGameDataFromJson(String str) =>
//     JackpotGameData.fromJson(json.decode(str));
//
// class JackpotGameData {
//   final bool status;
//   final String msg;
//   final List<JackpotGameInfo>? info;
//
//   JackpotGameData({required this.status, required this.msg, this.info});
//
//   factory JackpotGameData.fromJson(Map<String, dynamic> json) {
//     final rawInfo = json['info'];
//     List<JackpotGameInfo>? parsedInfo;
//     if (rawInfo is List) {
//       parsedInfo = rawInfo.map((x) => JackpotGameInfo.fromJson(x)).toList();
//     }
//     return JackpotGameData(
//       status: json['status'] == true || json['status'] == '1',
//       msg: json['msg']?.toString() ?? '',
//       info: parsedInfo,
//     );
//   }
// }
//
// class JackpotGameInfo {
//   final int gameId;
//   final String gameName;
//   final String openTime;
//   final String closeTime;
//   final String result;
//   final String statusText;
//   final bool playStatus;
//
//   JackpotGameInfo({
//     required this.gameId,
//     required this.gameName,
//     required this.openTime,
//     required this.closeTime,
//     required this.result,
//     required this.statusText,
//     required this.playStatus,
//   });
//
//   factory JackpotGameInfo.fromJson(Map<String, dynamic> json) {
//     bool parseBool(dynamic v) {
//       if (v is bool) return v;
//       final s = v?.toString().toLowerCase();
//       return s == '1' || s == 'true' || s == 'running' || s == 'open';
//     }
//
//     return JackpotGameInfo(
//       gameId: int.tryParse(json['gameId']?.toString() ?? '') ?? 0,
//       gameName: json['gameName']?.toString() ?? '',
//       openTime: json['openTime']?.toString() ?? '',
//       closeTime: json['closeTime']?.toString() ?? '',
//       result: json['result']?.toString() ?? '',
//       statusText: json['statusText']?.toString() ?? '',
//       playStatus: parseBool(json['playStatus']),
//     );
//   }
// }
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:new_sara/Bids/KingJackpotResultHis/KingJackpotResultScreen.dart';
import 'package:new_sara/KingStarline&Jackpot/JackpotJodiOptionsScreen.dart';
import 'package:new_sara/components/KingJackpotBiddingClosedDialog.dart';
import 'package:new_sara/ulits/curved_appbar.dart';
import 'package:new_sara/ulits/curved_appbar2.dart';

import '../Helper/TranslationHelper.dart';
import '../ulits/Constents.dart';

// New data model for game rates
class GameRates {
  final String singleDigit;
  final String singlePanna;

  GameRates({required this.singleDigit, required this.singlePanna});

  factory GameRates.fromJson(Map<String, dynamic> json) {
    return GameRates(
      singleDigit: json['singleDigit'] ?? '10/0',
      singlePanna: json['singlePanna'] ?? '10/0',
    );
  }
}

class KingJackpotDashboard extends StatefulWidget {
  const KingJackpotDashboard({super.key});

  @override
  State<KingJackpotDashboard> createState() => _KingJackpotDashboardState();
}

class _KingJackpotDashboardState extends State<KingJackpotDashboard> {
  late Future<JackpotGameData> futureGameData;
  final String toLang = GetStorage().read('language') ?? 'en';
  Map<String, String> _i18n = {};
  int _totalJodiElements = 0;
  bool _isGameLoading = true;
  bool _isRateLoading = true;

  // Game rates data
  GameRates? _gameRates;
  final GetStorage _storage = GetStorage();

  Map<String, String> _buildHeaders(
    String accessToken, {
    String? deviceId,
    String? deviceName,
    bool accountStatus = true,
  }) {
    final now = DateTime.now();
    return {
      'deviceId':
          deviceId ??
          (_storage.read('deviceId')?.toString() ?? 'unknown_device'),
      'deviceName':
          deviceName ??
          (_storage.read('deviceName')?.toString() ?? 'unknown_model'),
      'accessStatus': accountStatus ? '1' : '0',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      // helpful for backend time reconciliation
      'x-client-time': now.toIso8601String(),
      'x-tz-offset-mins': now.timeZoneOffset.inMinutes.toString(),
      'x-tz-name': now.timeZoneName,
    };
  }

  @override
  void initState() {
    super.initState();
    futureGameData = fetchGameData();
    _loadTranslations();
    _fetchGameRates(); // Fetch game rates when initializing
  }

  String tr(String key) => _i18n[key] ?? key;

  Future<void> _loadTranslations() async {
    final keys = [
      'King Jackpot',
      'History',
      'Jodi',
      'Play Game',
      'No data available.',
      'Error:',
      'Retry',
      'View History',
      'Jackpot Dashboard',
    ];

    try {
      final results = await Future.wait(
        keys.map((k) => TranslationHelper.translate(k, toLang)),
      );
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < keys.length; i++) {
          _i18n[keys[i]] = results[i];
        }
      });
    } catch (_) {}
  }

  Future<JackpotGameData> fetchGameData() async {
    final storage = GetStorage();
    final String accessToken = storage.read('accessToken') ?? '';
    final String registerId = storage.read('registerId') ?? '';
    final String deviceId =
        storage.read('deviceId')?.toString() ?? 'unknown_device';
    final String deviceName =
        storage.read('deviceName')?.toString() ?? 'unknown_model';
    final bool accountStatus = (storage.read('accountStatus') ?? true) == true;

    try {
      final now = DateTime.now();
      final uri = Uri.parse('${Constant.apiEndpoint}jackpot-game-list');

      /// 🔍 REQUEST DEBUG
      dev.log('==== JACKPOT GAME LIST REQUEST ====', name: 'JackpotAPI');
      dev.log('URL: $uri', name: 'JackpotAPI');
      dev.log(
        'Headers: ${{'deviceId': deviceId, 'deviceName': deviceName, 'accessStatus': accountStatus ? '1' : '0', 'Authorization': 'Bearer $accessToken'}}',
        name: 'JackpotAPI',
      );
      dev.log(
        'Body: ${json.encode({'registerId': registerId})}',
        name: 'JackpotAPI',
      );

      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
              'deviceId': deviceId,
              'deviceName': deviceName,
              'accessStatus': accountStatus ? '1' : '0',
              'Authorization': 'Bearer $accessToken',
              'x-client-time': now.toIso8601String(),
              'x-tz-offset-mins': now.timeZoneOffset.inMinutes.toString(),
              'x-tz-name': now.timeZoneName,
            },
            body: json.encode({'registerId': registerId}),
          )
          .timeout(const Duration(seconds: 20));

      /// 🔍 RESPONSE DEBUG
      dev.log('==== JACKPOT GAME LIST RESPONSE ====', name: 'JackpotAPI');
      dev.log('Status Code: ${res.statusCode}', name: 'JackpotAPI');
      dev.log('Raw Body: ${res.body}', name: 'JackpotAPI');

      if (res.statusCode == 200) {
        final data = jackpotGameDataFromJson(res.body);

        /// 🔍 PARSED DATA DEBUG
        dev.log('Parsed Status: ${data.status}', name: 'JackpotAPI');
        dev.log('Message: ${data.msg}', name: 'JackpotAPI');

        if (data.info != null) {
          dev.log('Total Games: ${data.info!.length}', name: 'JackpotAPI');

          for (var g in data.info!) {
            dev.log(
              'GameId: ${g.gameId} | '
              'Name: ${g.gameName} | '
              'Result: ${g.result} | '
              'StatusText: ${g.statusText} | '
              'PlayStatus: ${g.playStatus}',
              name: 'JackpotAPI',
            );
          }

          _totalJodiElements = data.info!.length;
          if (mounted) setState(() {});
        }

        return data;
      }

      throw Exception('Failed with status: ${res.statusCode}');
    } catch (e, s) {
      dev.log('[Jackpot] Exception: $e', name: 'KingJackpot', stackTrace: s);
      rethrow;
    }
  }

  // New method to fetch game rates
  Future<void> _fetchGameRates() async {
    final String? accessToken = _storage.read('accessToken');
    final bool accountStatus = (_storage.read('accountStatus') ?? true) == true;

    if (accessToken == null || accessToken.isEmpty) return;

    final url = Uri.parse('${Constant.apiEndpoint}game-rate');
    final headers = _buildHeaders(accessToken, accountStatus: accountStatus);

    try {
      final response = await http.get(url, headers: headers);

      dev.log('GameRate RAW BODY: ${response.body}', name: 'GameRateAPI');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;

        final info = jsonData['info'];
        final gameRate = info['gameRate']; // 👈 ONLY THIS

        dev.log('Using gameRate only: $gameRate', name: 'GameRateAPI');

        if (!mounted) return;
        setState(() {
          _gameRates = GameRates(
            singleDigit: gameRate['singleDigit'] ?? '10/95',
            singlePanna: gameRate['singlePanna'] ?? '10/95',
          );
        });

        dev.log(
          'FINAL UI RATE → SD: ${_gameRates!.singleDigit}, '
          'SP: ${_gameRates!.singlePanna}',
          name: 'GameRateAPI',
        );
      }
    } catch (e, s) {
      dev.log('GameRate API Exception: $e', name: 'GameRateAPI', stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CurvedAppBar2(title: 'Jackpot Dashboard'),

      body: Column(
        children: [
          // Add the game rates section here
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
            child: Column(
              children: [
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Single Digit : ",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        Text(
                          _gameRates?.singleDigit ?? "10/0",
                          style: const TextStyle(
                            color: Color(0xffFF2600),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          "Single Pana : ",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        Text(
                          _gameRates?.singlePanna ?? "10/0",
                          style: const TextStyle(
                            color: Color(0xffFF2600),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          //  _buildRedHeader(),
          _buildJodiChip(),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kalyan Jackpot',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // थोड़ा bold
                ),
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFF2600),
              onRefresh: () async {
                setState(() => futureGameData = fetchGameData());
                await futureGameData;
              },
              child: FutureBuilder<JackpotGameData>(
                future: futureGameData,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF2600),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return _errorView(message: '${tr("Error:")} ${snap.error}');
                  }
                  final info = snap.data?.info;
                  if (info == null || info.isEmpty) {
                    return Center(child: Text(tr('No data available.')));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: info.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemBuilder: (context, i) => _buildGameCard(info[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFF2600),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  tr('Jackpot Dashboard'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KingJackpotResultScreen(),
                    ),
                  ),
                  child: Text(
                    tr('View History'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Single Digit : ",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                _gameRates?.singleDigit ?? "10/0",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                "Single Pana : ",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                _gameRates?.singlePanna ?? "10/0",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJodiChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            "Total Games : ",
            style: TextStyle(
              color: Color(0xFFFF2600),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            "$_totalJodiElements",
            style: const TextStyle(
              color: Color(0xFFFF2600),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(JackpotGameInfo g) {
    final String status = g.statusText.toLowerCase();

    final bool isClosed =
        !g.playStatus || status == 'declared' || status == 'closed';

    final bool canPlay = g.playStatus && !isClosed;

    final Color cardBg = isClosed
        ? const Color(0xFFF6CFD0)
        : const Color(0xFFDEEAD2);
    final Color statusColor = isClosed
        ? const Color(0xFFE91E1E)
        : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // यही है आपकी "छोटी ऊपरी पतली लाइन" – बिल्कुल ओरिजिनल इमेज जैसी
          Positioned(
            left: 0,
            top: 24,
            child: Container(
              width: 7, // बहुत पतली लाइन
              height: 25, // सिर्फ ऊपर की तरफ (लगभग 52-58px काफी है)
              decoration: BoxDecoration(
                color: isClosed
                    ? const Color(0xFFE91E1E)
                    : const Color(0xFF4CAF50),
                // borderRadius: const BorderRadius.only(
                //   topLeft: Radius.circular(18),
                //   bottomRight: Radius.circular(12),
                // ),
              ),
            ),
          ),

          // बाकी कार्ड कंटेंट
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: canPlay
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JackpotJodiOptionsScreen(
                          title: 'Kalyan Jackpot, ${g.gameName}',
                          gameTime: g.gameName,
                          gameId: g.gameId,
                          digitJodiStatus: false,
                          sessionSelection: true,
                        ),
                      ),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 20), // लाइन के नीचे थोड़ा स्पेस
                        Image.asset(
                          isClosed
                              ? "assets/icons/stopwatch.png" // Closed icon
                              : "assets/icons/chronometer.png", // Open icon
                          width: 26,
                          height: 26,
                          //  color: isClosed ? const Color(0xFFE91E1E) : const Color(0xFFFF8C00),
                        ),

                        const SizedBox(width: 8),
                        Text(
                          g.gameName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 55.0),
                      child: Text(
                        g.result.isNotEmpty ? g.result : "**",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            isClosed
                                ? "Betting is Closed"
                                : "Betting is Running",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            isClosed ? "for Today" : "now",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (canPlay)
                      Center(
                        child: SizedBox(
                          width: 130,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JackpotJodiOptionsScreen(
                                  title: 'Kalyan Jackpot, ${g.gameName}',
                                  gameTime: g.gameName,
                                  gameId: g.gameId,
                                  digitJodiStatus: false,
                                  sessionSelection: true,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28A745),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "PLAY NOW",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView({required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Color(0xFFFF2600)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => futureGameData = fetchGameData()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2600),
              ),
              child: Text(
                tr('Retry'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= MODELS (Same as before) =======================

JackpotGameData jackpotGameDataFromJson(String str) =>
    JackpotGameData.fromJson(json.decode(str));

class JackpotGameData {
  final bool status;
  final String msg;
  final List<JackpotGameInfo>? info;

  JackpotGameData({required this.status, required this.msg, this.info});

  factory JackpotGameData.fromJson(Map<String, dynamic> json) {
    final rawInfo = json['info'];
    List<JackpotGameInfo>? parsedInfo;
    if (rawInfo is List) {
      parsedInfo = rawInfo.map((x) => JackpotGameInfo.fromJson(x)).toList();
    }
    return JackpotGameData(
      status: json['status'] == true || json['status'] == '1',
      msg: json['msg']?.toString() ?? '',
      info: parsedInfo,
    );
  }
}

class JackpotGameInfo {
  final int gameId;
  final String gameName;
  final String openTime;
  final String closeTime;
  final String result;
  final String statusText;
  final bool playStatus;

  JackpotGameInfo({
    required this.gameId,
    required this.gameName,
    required this.openTime,
    required this.closeTime,
    required this.result,
    required this.statusText,
    required this.playStatus,
  });

  factory JackpotGameInfo.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'running' || s == 'open';
    }

    return JackpotGameInfo(
      gameId: int.tryParse(json['gameId']?.toString() ?? '') ?? 0,
      gameName: json['gameName']?.toString() ?? '',
      openTime: json['openTime']?.toString() ?? '',
      closeTime: json['closeTime']?.toString() ?? '',
      result: json['result']?.toString() ?? '',
      statusText: json['statusText']?.toString() ?? '',
      playStatus: parseBool(json['playStatus']),
    );
  }
}
