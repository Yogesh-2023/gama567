import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Helper/UserController.dart';
import '../KingStarline&Jackpot/KingJackpotDashboard.dart';
import '../KingStarline&Jackpot/KingStarlineDashboard.dart';
import '../components/closeBidDialogue.dart';
import '../components/closeBidDialogue1.dart';
import '../game/GameScreen.dart';
import '../ChartScreen/ChartScreen.dart';
import '../ChartScreen/ChartTableScreen.dart';
import '../ulits/Constents.dart';

// Placeholder for TranslationHelper
class TranslationHelper {
  static Future<String> translate(String text, String lang) async {
    await Future.delayed(const Duration(milliseconds: 5));
    return text;
  }
}

// ---------------- Data Models ----------------
class HomeData {
  final bool status;
  final String msg;
  final List<Info>? result;

  HomeData({required this.status, required this.msg, this.result});

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
    status: _b(json["status"]),
    msg: json["msg"]?.toString() ?? '',
    result: json["info"] == null
        ? null
        : List<Info>.from(
            (json["info"] as List).map(
              (x) => Info.fromJson(x as Map<String, dynamic>),
            ),
          ),
  );
}

class Info {
  final int gameId;
  final String gameName;
  final String gameType;
  final String openTime;
  final String closeTime;
  final String result;
  final String statusText;
  final bool playStatus;
  final bool openSessionStatus;
  final bool closeSessionStatus;

  Info({
    required this.gameId,
    required this.gameName,
    required this.gameType,
    required this.openTime,
    required this.closeTime,
    required this.result,
    required this.statusText,
    required this.playStatus,
    required this.openSessionStatus,
    required this.closeSessionStatus,
  });

  factory Info.fromJson(Map<String, dynamic> json) => Info(
    gameId: int.tryParse(json["gameId"].toString()) ?? 0,
    gameName: json["gameName"]?.toString() ?? '',
    gameType: json["gameType"]?.toString() ?? '',
    openTime: json["openTime"]?.toString() ?? '',
    closeTime: json["closeTime"]?.toString() ?? '',
    result: json["result"]?.toString() ?? '',
    statusText: json["statusText"]?.toString() ?? '',
    playStatus: _b(json["playStatus"]),
    openSessionStatus: _b(json["openSessionStatus"]),
    closeSessionStatus: _b(json["closeSessionStatus"]),
  );
}

// Robust bool parser
bool _b(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'y';
  }
  return false;
}

class ContactDetails {
  final String? mobileNo;
  final String? whatsappNo;
  final String? appLink;
  final String? homepageContent;
  final String? videoDescription;

  ContactDetails({
    this.mobileNo,
    this.whatsappNo,
    this.appLink,
    this.homepageContent,
    this.videoDescription,
  });
}

HomeData homeDataFromJson(String str) =>
    HomeData.fromJson(json.decode(str) as Map<String, dynamic>);

// ---------------- HomePage ----------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomeData> _futureHomeData;
  late Future<ContactDetails?> _futureContactDetails;
  late String _preferredLanguage;

  final Map<String, String> _translatedUiStrings = {};
  final GetStorage _storage = GetStorage();

  late final UserController userController = Get.isRegistered<UserController>()
      ? Get.find<UserController>()
      : Get.put(UserController(), permanent: true);

  static const List<String> _uiKeysToTranslate = [
    "KING STARLINE",
    "King Jackpot",
    "Play Game",
    "Open Bid",
    "Close Bid",
    "Game time",
    "Market Closed",
    "Closed for today",
  ];

  @override
  void initState() {
    super.initState();

    log('HomePage sees UserController hash: ${userController.hashCode}');

    _preferredLanguage = _storage.read('selectedLanguage') ?? 'en';

    _preTranslateUI();
    _futureHomeData = _fetchDashboardData();
    _futureContactDetails = fetchContactDetail();

    everAll([userController.accessToken, userController.registerId], (_) {
      setState(() {
        _futureHomeData = _fetchDashboardData();
        _futureContactDetails = fetchContactDetail();
      });
    });
  }

  Future<void> _preTranslateUI() async {
    for (final key in _uiKeysToTranslate) {
      if (!_translatedUiStrings.containsKey(key) ||
          _translatedUiStrings[key] == key) {
        _translatedUiStrings[key] = await TranslationHelper.translate(
          key,
          _preferredLanguage,
        );
      }
    }
    if (mounted) setState(() {});
  }

  String _t(String key) => _translatedUiStrings[key] ?? key;

  // Helper method to determine status color
  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains("open")) {
      return const Color(0xFF4CAF50); // Green color for open status
    } else {
      return const Color(0xFFD32F2F); // Red color for closed status
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await userController.refreshEverything();
      setState(() {
        _futureHomeData = _fetchDashboardData();
        _futureContactDetails = fetchContactDetail();
      });
    } catch (e) {
      log("Error during refresh: $e");
    }
  }

  Future<ContactDetails?> fetchContactDetail() async {
    final url = Uri.parse('${Constant.apiEndpoint}contact-detail');
    final headers = {
      'deviceId': 'qwert',
      'deviceName': 'sm2233',
      'accessStatus': '1',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${_storage.read('accessToken') ?? ''}',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Contact details fetched: $data');

        final contactInfo =
            (data['info'] as Map?)?['contactInfo'] as Map<String, dynamic>?;
        final videosInfo =
            (data['info'] as Map?)?['videosInfo'] as Map<String, dynamic>?;

        return ContactDetails(
          mobileNo: contactInfo?['mobileNo']?.toString(),
          whatsappNo: contactInfo?['whatsappNo']?.toString(),
          appLink: contactInfo?['appLink']?.toString(),
          homepageContent: contactInfo?['homepageContent']?.toString(),
          videoDescription: videosInfo?['description']?.toString(),
        );
      } else {
        log('❌ contact-detail ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      log('❗ Error fetching contact details: $e');
      return null;
    }
  }

  Future<HomeData> _fetchDashboardData() async {
    final String token = _storage.read('accessToken') ?? '';
    final String regId = _storage.read('registerId') ?? '';

    if (token.isEmpty || regId.isEmpty) {
      log("❌ Aborting game-list: Missing access token or register ID.");
      return HomeData(
        status: false,
        msg: "User not logged in",
        result: const [],
      );
    }

    final response = await http.post(
      Uri.parse("${Constant.apiEndpoint}game-list"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Accept": "application/json",
        "deviceId": "qwert",
        "deviceName": "sm2233",
        "accessStatus": "1",
        "Authorization": "Bearer $token",
      },
      body: json.encode({"registerId": regId}),
    );

    // 👇👇 ADD THIS
    log("📥 GAME-LIST RAW RESPONSE:");
    log(response.body);
    if (response.statusCode == 200) {
      return homeDataFromJson(response.body);
    } else {
      log(
        "Failed to load dashboard data: ${response.statusCode} - ${response.body}",
      );
      throw Exception(
        "Failed to load dashboard data: ${response.statusCode} - ${response.body}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: RefreshIndicator(
          color: Color(0xFFFF2600),
          backgroundColor: Colors.white,
          onRefresh: _handleRefresh,
          child: FutureBuilder<HomeData>(
            future: _futureHomeData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFFF2600),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                log("FutureBuilder Error: ${snapshot.error}");
                return const Center(
                  child: Text(
                    "Error loading data. Please try again.",
                    style: TextStyle(color: Color(0xFFFF2600)),
                  ),
                );
              } else if (!snapshot.hasData ||
                  snapshot.data!.result == null ||
                  snapshot.data!.result!.isEmpty) {
                return const Center(child: Text("No game data available."));
              }

              final results = snapshot.data!.result!;

              return Obx(() {
                final acc = userController.accountStatus.value;

                return Container(
                  color: Colors.white,
                  child: ListView(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 6,
                      bottom: 12,
                    ),
                    children: [
                      // const SizedBox(height: 5),

                      // Marquee (conditionally shown)
                      if (acc)
                        FutureBuilder<ContactDetails?>(
                          future: _futureContactDetails,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final homepageContent =
                                  snapshot.data!.homepageContent ?? '';
                              if (homepageContent.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return SizedBox(
                                height: 30,
                                child: Marquee(
                                  text:
                                      homepageContent +
                                      List.filled(10, '\t').join(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                  ),
                                  scrollAxis: Axis.horizontal,
                                  blankSpace: 50.0,
                                  velocity: 30.0,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      //   if (acc) const SizedBox(height: 12),
                      // Category Buttons with Offset Shadow Effect
                      // REPLACE your entire "Category Buttons with Offset Shadow Effect" block with this:

                      // ← YE PURA BLOCK REPLACE KAR DO (Category Buttons wala section)
                      if (acc)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                          ), // ListView ka original padding yahan se cancel karenge
                          child: Container(
                            height: 120,

                            //  margin: const EdgeInsets.symmetric(horizontal: -12), // ← Ab yeh bhi allowed hai kyunki Container ke bahar Padding hai
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xffFF2600,
                                  ).withOpacity(0.5),
                                  offset: const Offset(0, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Card(
                              elevation: 0,
                              color: Colors.white,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    // LEFT CARD - KALYAN STARLINE
                                    Expanded(
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const KingStarlineDashboardScreen(),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 75,
                                              margin: const EdgeInsets.only(
                                                left: 12,
                                                right: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xffFF2600),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Kalyan Starline",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -18,
                                            left: 20,
                                            right: 20,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const KingStarlineDashboardScreen(),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                height: 35,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xffFF2600,
                                                    ),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Play Now",
                                                    style: GoogleFonts.poppins(
                                                      color: const Color(
                                                        0xffFF2600,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // RIGHT CARD - KALYAN JACKPOT
                                    Expanded(
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      KingJackpotDashboard(),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 75,
                                              margin: const EdgeInsets.only(
                                                left: 6,
                                                right: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xffFF2600,
                                                  ),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Kalyan Jackpot",
                                                  style: GoogleFonts.poppins(
                                                    color: const Color(
                                                      0xffFF2600,
                                                    ),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -18,
                                            left: 20,
                                            right: 20,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        KingJackpotDashboard(),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                height: 35,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xffFF2600,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Play Now",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (acc) const SizedBox(height: 24),
                      // Contact row
                      if (acc)
                        FutureBuilder<ContactDetails?>(
                          future: _futureContactDetails,
                          builder: (context, contactSnapshot) {
                            if (contactSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF2600),
                                ),
                              );
                            }
                            if (contactSnapshot.hasData &&
                                contactSnapshot.data != null) {
                              final contactData = contactSnapshot.data!;
                              if ((contactData.whatsappNo ?? '').isNotEmpty) {
                                _storage.write(
                                  'whatsappNo',
                                  contactData.whatsappNo,
                                );
                              }
                              return Row(
                                children: [
                                  _ContactItem(contactData.whatsappNo ?? 'N/A'),
                                  const Spacer(),
                                  _ContactItem(contactData.mobileNo ?? 'N/A'),
                                ],
                              );
                            }
                            return const Center(
                              child: Text("Contact info unavailable."),
                            );
                          },
                        ),

                      if (acc) const SizedBox(height: 18),

                      // Game Cards - NEW UI matching image
                      ...results.map(
                        (game) => _GameCard(
                          id: game.gameId,
                          title: game.gameName,
                          gameType: game.gameType,
                          result: game.result,
                          status: game.statusText,
                          accountStatus: acc,
                          openSessionStatus: game.openSessionStatus,
                          closeSessionStatus: game.closeSessionStatus,
                          open: game.openTime,
                          close: game.closeTime,
                          openBidLastTime: game.openTime,
                          closeBidLastTime: game.closeTime,
                          getTranslatedString: _t,
                          getStatusColor: _getStatusColor,
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }
}

// ---------------- Game Card Widget (Updated to match image) ----------------
class _GameCard extends StatelessWidget {
  final int id;
  final String title;
  final String gameType;
  final String result;
  final String open;
  final String close;
  final String openBidLastTime;
  final String closeBidLastTime;
  final String status;
  final bool accountStatus;
  final bool openSessionStatus;
  final bool closeSessionStatus;
  final String Function(String) getTranslatedString;
  final Color Function(String) getStatusColor; // Added this parameter

  const _GameCard({
    required this.id,
    required this.title,
    required this.gameType,
    required this.result,
    required this.open,
    required this.close,
    required this.openBidLastTime,
    required this.closeBidLastTime,
    required this.status,
    required this.accountStatus,
    required this.openSessionStatus,
    required this.closeSessionStatus,
    required this.getTranslatedString,
    required this.getStatusColor, // Added this parameter
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      //  shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // CENTERED GAME INFO (when inactive) OR LEFT ALIGNED (when active)
            Expanded(
              child: Column(
                crossAxisAlignment: accountStatus
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8B4513),
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(left: accountStatus ? 10.0 : 0.0),
                    child: Text(
                      result,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: accountStatus ? 6.0 : 0.0),
                    child: Text(
                      getTranslatedString(
                        status,
                      ), // Changed from hardcoded "Closed for today" to dynamic status
                      style: GoogleFonts.poppins(
                        color: getStatusColor(
                          status,
                        ), // Using the helper method passed as parameter
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 1),

            if (accountStatus)
              Column(
                children: [
                  Row(
                    children: [
                      // TIMER ICON (NO CHANGE)
                      GestureDetector(
                        onTap: () {
                          closeBidDialogue1(
                            context: context,
                            gameName: title,
                            openResultTime: open,
                            openBidLastTime: openBidLastTime,
                            closeResultTime: close,
                            closeBidLastTime: closeBidLastTime,
                            isBettingClosed:
                                status.toLowerCase().contains(
                                  "closed for today",
                                ) ||
                                status.toLowerCase().contains(
                                  "holiday for today",
                                ),
                          );
                        },
                        child: Image.asset(
                          "assets/icons/iconwhite.png",
                          width: 46,
                          height: 46,
                        ),
                      ),

                      const SizedBox(width: 20),

                      // 🔥 PLAY ICON WITH OFFSET CHART ICON
                      SizedBox(
                        width: 70, // 👈 IMPORTANT: Stack ka hit-area
                        height: 70,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // ▶ PLAY BUTTON (NO CHANGE)
                            GestureDetector(
                              onTap: () {
                                final s = status.toLowerCase();
                                if (s.contains("closed for today") ||
                                    s.contains("holiday for today")) {
                                  closeBidDialogue1(
                                    context: context,
                                    gameName: title,
                                    openResultTime: open,
                                    openBidLastTime: openBidLastTime,
                                    closeResultTime: close,
                                    closeBidLastTime: closeBidLastTime,
                                    isBettingClosed: true,
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GameMenuScreen(
                                        title: title,
                                        gameId: id,
                                        openSessionStatus: openSessionStatus,
                                        closeSessionStatus: closeSessionStatus,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFE3E17),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF2600,
                                      ).withOpacity(0.2),
                                      blurRadius: 7,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),

                            // 📊 CHART ICON (OFFSET + PERFECT TAP)
                            Positioned(
                              top: -20, // 👈 ab negative ki zarurat nahi
                              right: -16,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChartTableScreen(
                                        gameId: id,
                                        gameType: gameType,
                                        gameName: title,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 40, // 👈 BIG & SAFE TAP AREA
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(),
                                  child: Image.asset(
                                    "assets/images/calendar_color.png",
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // LABELS (NO CHANGE)
                  Row(
                    children: [
                      Text(
                        getTranslatedString("Game time"),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        getTranslatedString("Play Game"),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              )
            // FOR INACTIVE USERS - SHOW CHART AND LAST BID TIMES
            else
              Column(
                children: [
                  Row(
                    children: [
                      // CHART ICON
                      GestureDetector(
                        onTap: () {
                          // Navigate to ChartTableScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChartTableScreen(
                                gameId: id,
                                gameType: gameType,
                                gameName: title,
                              ),
                            ),
                          );
                        },
                        child: Image.asset(
                          "assets/images/calendar_color.png", // Calendar chart icon
                          width: 44,
                          height: 44,
                        ),
                      ),

                      const SizedBox(width: 20),

                      // TIMER ICON FOR LAST BID
                      GestureDetector(
                        onTap: () {
                          closeBidDialogue1(
                            context: context,
                            gameName: title,
                            openResultTime: open,
                            openBidLastTime: openBidLastTime,
                            closeResultTime: close,
                            closeBidLastTime: closeBidLastTime,
                            isBettingClosed:
                                status.toLowerCase().contains(
                                  "closed for today",
                                ) ||
                                status.toLowerCase().contains(
                                  "holiday for today",
                                ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Image.asset(
                            "assets/icons/iconwhite.png", // Timer icon
                            width: 46,
                            height: 46,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Text(
                        "Chart",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 13.0),
                        child: Text(
                          "Game Time",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Category Button ----------------
class _CustomCategoryButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _CustomCategoryButton({
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFFFF2600),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.grey.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Contact Item ----------------
class _ContactItem extends StatelessWidget {
  final String number;

  const _ContactItem(this.number);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final cleanNumber = number
            .replaceAll('+91', '')
            .replaceAll(' ', '')
            .trim();
        final url = Uri.parse("https://wa.me/$cleanNumber");

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          log("Could not launch $url");
        }
      },
      child: Row(
        children: [
          Image.asset(
            "assets/images/whatsapp_figma.png",
            height: 25,
            width: 25,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.phone, color: Colors.green, size: 25);
            },
          ),
          const SizedBox(width: 5),
          Text(
            number,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
