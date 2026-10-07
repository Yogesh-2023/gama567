import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:new_sara/Bids/KingStarlineResultHis/KingStarlineResultHis.dart';
import 'package:new_sara/KingStarline&Jackpot/KingStarlineOptionScreen.dart';
import 'package:new_sara/ulits/curved_appbar.dart';
import 'package:new_sara/ulits/curver_appbar1.dart';

import '../components/KingJackpotBiddingClosedDialog.dart';
import '../ulits/Constents.dart';

/// ---- Data Model ----
class StarlineGame {
  final int id; // from gameId
  final String time; // from gameName (e.g., "09:30 PM")
  final String status; // from statusText
  final String result; // from result
  final bool isClosed; // !playStatus
  final String openTime; // from openTime
  final String closeTime; // from closeTime
  final String additionalInfo; // "Bid closed at <closeTime>" when closed

  StarlineGame({
    required this.id,
    required this.time,
    required this.status,
    required this.result,
    required this.isClosed,
    required this.openTime,
    required this.closeTime,
    this.additionalInfo = '',
  });

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' ||
          s == '1' ||
          s == 'open' ||
          s == 'active' ||
          s == 'running';
    }
    return false;
  }

  factory StarlineGame.fromJson(Map<String, dynamic> json) {
    log('--- STARLINE GAME DEBUG ---');
    log('gameId: ${json['gameId']}');
    log('statusText: ${json['statusText']}');
    log('playStatus RAW: ${json['playStatus']}');
    log('playStatus PARSED: ${_toBool(json['playStatus'])}');
    log('isClosed CALCULATED: ${!_toBool(json['playStatus'])}');
    log('result: ${json['result']}');
    log('---------------------------');
    final int gameId = () {
      final v = json['gameId'];
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }();

    final String gameName = (json['gameName'] ?? 'N/A').toString();
    final String result = (json['result'] ?? '****-*').toString();
    final String statusText = (json['statusText'] ?? 'Unknown').toString();
    final bool playStatus = _toBool(json['playStatus']); // true => open
    final String closeTime = (json['closeTime'] ?? '--:--').toString();
    final String openTime = (json['openTime'] ?? '--:--').toString();

    final bool closed = !playStatus;
    final String displayStatus = statusText.isEmpty
        ? (closed ? 'Closed' : 'Open')
        : statusText;
    final String displayAdditionalInfo = closed
        ? 'Bid closed at $closeTime'
        : '';

    return StarlineGame(
      id: gameId,
      time: gameName,
      status: displayStatus,
      result: result,
      isClosed: closed,
      openTime: openTime,
      closeTime: closeTime,
      additionalInfo: displayAdditionalInfo,
    );
  }
}

// New data model for game rates
class GameRates {
  final String singleDigit;
  final String singlePanna;
  final String doublePanna;
  final String triplePanna;

  GameRates({
    required this.singleDigit,
    required this.singlePanna,
    required this.doublePanna,
    required this.triplePanna,
  });

  factory GameRates.fromJson(Map<String, dynamic> json) {
    return GameRates(
      singleDigit: json['singleDigit'] ?? '10/10',
      singlePanna: json['singlePanna'] ?? '10/0',
      doublePanna: json['doublePanna'] ?? '10/0',
      triplePanna: json['triplePanna'] ?? '10/0',
    );
  }
}

/// ---- Screen ----
class KingStarlineDashboardScreen extends StatefulWidget {
  const KingStarlineDashboardScreen({super.key});

  @override
  State<KingStarlineDashboardScreen> createState() =>
      _KingStarlineDashboardScreenState();
}

class _KingStarlineDashboardScreenState
    extends State<KingStarlineDashboardScreen> {
  bool _notificationsEnabled = true;
  List<StarlineGame> _gameTimes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isRateLoading = true;

  final GetStorage _storage = GetStorage();

  // Game rates data
  GameRates? _gameRates;

  // Non-nullable registeredId (loaded from local storage)
  String _registeredId = '';

  @override
  void initState() {
    super.initState();
    _loadAuthData();
    _fetchGameList();
    _fetchGameRates(); // Fetch game rates when initializing
  }

  void _loadAuthData() {
    // Signup/Login par jo save kiya tha, wahi se seedha utha rahe hain
    final rid = _storage.read('registerId')?.toString() ?? '';
    _registeredId = rid;
    log(
      'RegisteredId loaded: ${_registeredId.isEmpty ? "(empty)" : _registeredId}',
    );
  }

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

  Future<void> _fetchGameList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final String? accessToken = _storage.read('accessToken');
    final String? registerId = _storage.read('registerId');
    final bool accountStatus = (_storage.read('accountStatus') ?? true) == true;

    if (accessToken == null || accessToken.isEmpty) {
      log('Error: Access token not found. Cannot fetch Starline game list.');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Access token not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    if (registerId == null || registerId.isEmpty) {
      log('Error: Register ID not found. Cannot fetch Starline game list.');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Register ID not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('${Constant.apiEndpoint}starline-game-list');
    final headers = _buildHeaders(accessToken, accountStatus: accountStatus);
    final body = jsonEncode({'registerId': registerId});

    try {
      final response = await http.post(url, headers: headers, body: body);

      log('Starline Game List API Status: ${response.statusCode}');
      log('Starline Game List API Body: ${response.body}');
      log('================ STARLINE GAME LIST API =================');
      log('URL: $url');
      log('Request Headers: $headers');
      log('Request Body: $body');
      log('Status Code: ${response.statusCode}');
      log('RAW RESPONSE BODY: ${response.body}');
      log('=========================================================');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(response.body) as Map<String, dynamic>;

        if (responseData['status'] == true && responseData['info'] is List) {
          final List rawList = responseData['info'] as List;
          final games = rawList
              .map(
                (e) =>
                StarlineGame.fromJson((e as Map).cast<String, dynamic>()),
          )
              .toList();

          // Sort by time if parseable (hh:mm a)
          final fmt = DateFormat('hh:mm a');
          games.sort((a, b) {
            DateTime? ta, tb;
            try {
              final pa = fmt.parse(a.time);
              ta = DateTime(1970, 1, 1, pa.hour, pa.minute);
            } catch (_) {}
            try {
              final pb = fmt.parse(b.time);
              tb = DateTime(1970, 1, 1, pb.hour, pb.minute);
            } catch (_) {}
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return ta.compareTo(tb);
          });

          if (!mounted) return;
          setState(() {
            _gameTimes = games;
            _isLoading = false;
          });
        } else {
          final msg = (responseData['msg'] ?? 'Failed to load game data.')
              .toString();
          log('Starline Game List API Error: $msg');
          if (!mounted) return;
          setState(() {
            _errorMessage = msg;
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
          'Error ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Exception during Starline Game List API call: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  // New method to fetch game rates
  Future<void> _fetchGameRates() async {
    setState(() {
      _isRateLoading = true;
    });

    final String? accessToken = _storage.read('accessToken');
    final bool accountStatus = (_storage.read('accountStatus') ?? true) == true;

    if (accessToken == null || accessToken.isEmpty) {
      log('Access token missing');
      setState(() {
        _isRateLoading = false;
      });
      return;
    }

    final url = Uri.parse('${Constant.apiEndpoint}game-rate');
    final headers = _buildHeaders(accessToken, accountStatus: accountStatus);

    try {
      final response = await http.get(url, headers: headers);

      log('Game Rate RAW: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final info = data['info'];
        final starlineRates = info['starlineGameRate'];

        setState(() {
          _gameRates = GameRates.fromJson(starlineRates);
          _isRateLoading = false;
        });
      } else {
        _isRateLoading = false;
      }
    } catch (e) {
      log('GameRate error: $e');
      setState(() {
        _isRateLoading = false;
      });
    }
  }

  void _onPlayTap(StarlineGame game) {
    log(
      'Play Game tapped => id=${game.id}, time=${game.time}, status=${game.status}, isClosed=${game.isClosed}',
    );

    if (game.isClosed) {
      showDialog(
        context: context,
        builder: (_) => KingJackpotBiddingClosedDialog(
          time: game.time,
          resultTime: game.openTime,
          bidLastTime: game.closeTime,
        ),
      );
      return;
    }

    // BEST PRACTICE: registeredId must be non-empty, warna navigate mat karo
    if (_registeredId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register ID missing. Please log in again.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KingStarlineOptionScreen(
          title: 'King Starline',
          gameTime: game.time,
          starlineGameId: game.id, // session/game id
          paanaStatus: !game.isClosed, // open/close info
          registeredId: _registeredId, // non-null String
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isRateLoading) {
      // 👈 SAME loader jaisa game list me hai
      return Scaffold(
        backgroundColor: const Color(0xffF6F6F6),
        appBar: CurvedAppBar1(title: 'Main Starline'),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2600)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: CurvedAppBar1(title: 'Main Starline'),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 GAME RATES (ab direct API se hi aayega)
            _buildRateSection(),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kalyan Starline',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // थोड़ा bold
                  ),
                ),
              ),
            ),

            /// 🔥 GAME LIST
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _gameTimes.length,
                itemBuilder: (_, index) {
                  return _buildGameCard(_gameTimes[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      child: Column(
        children: [
          const SizedBox(height: 5),
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
                    _gameRates!.singleDigit,
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
                    "Double Pana : ",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  Text(
                    _gameRates!.doublePanna,
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
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    "Single Pana : ",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  Text(
                    _gameRates!.singlePanna,
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
                    "Triple Pana : ",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  Text(
                    _gameRates!.triplePanna,
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
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Expanded(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF2600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(StarlineGame game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          // BoxShadow(
          //   color: Colors.black.withOpacity(0.08),
          //   blurRadius: 6,
          //   offset: Offset(0, 3),
          // ),
        ],
      ),

      child: Row(
        children: [
          // Time + Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.time,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  game.isClosed ? "Closed for Today" : "Running now",
                  style: TextStyle(
                    color: game.isClosed ? Color(0xffFF2600) : Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),

          // Result
          Text(
            game.result,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xffFF2600),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 20),

          // Play Game Button
          GestureDetector(
            onTap: () => _onPlayTap(game),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF2600),
                    shape: BoxShape.circle,

                    // 🔥 HALKA RED SHADOW (outer glow)
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF2600).withOpacity(0.3), // Red glow
                        blurRadius: 12, // Softness
                        spreadRadius: 2, // Outer spread
                        offset: Offset(0, 0), // All directions
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 5),
                const Text(
                  "Play Game",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
