import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
// Import your game screens
import 'package:new_sara/game/Jodi/JodiBulkScreen.dart';
import 'package:new_sara/game/Panna/DoublePana/DoublePana.dart';
import 'package:new_sara/game/Panna/SinglePanna/SinglePanna.dart';
import 'package:new_sara/game/Panna/SinglePanna/SinglePannaBulk.dart'
    hide SingleDigitsBulkScreen;
import 'package:new_sara/game/RedBracket/RedBracketScreen.dart';
import 'package:new_sara/game/SPDPTPScreen/ChoiceSpDpTpBoardScreen.dart';
import 'package:new_sara/game/SPDPTPScreen/SPMotors.dart';
import 'package:new_sara/game/SPDPTPScreen/SpDpTpBoardScreen.dart';
import 'package:new_sara/game/SPDPTPScreen/TPMotorScreen.dart';
import 'package:new_sara/game/Sangam/FullSangamBoardScreen.dart';
import 'package:new_sara/game/Sangam/HalfSangamABoardScreen.dart';
import 'package:new_sara/game/Sangam/HalfSangamBBoardScreen.dart';

import '../Helper/TranslationHelper.dart';
import '../ulits/Constents.dart';
import '../ulits/curved_appbar.dart';
import 'DigitBasedBoard/DigitBasedBoardScreen.dart';
import 'GameItem.dart';
import 'Jodi/JodiBidScreen.dart';
import 'Jodi/group_jodi_screen.dart';
import 'OddEvenBoard/OddEvenBoardScreen.dart';
import 'PannelGroup/PannelGroup.dart';
import 'SPDPTPScreen/DPMotors.dart';
import 'SingleDigitBetScreen/SingleDigitBetScreen.dart';
import 'SingleDigitBetScreen/SingleDigitsBulkScreen.dart';
import 'TwoDigitPanel/TwoDigitPanel.dart';

class GameMenuScreen extends StatefulWidget {
  final String title;
  final int gameId;
  final bool openSessionStatus;
  final bool closeSessionStatus;
  const GameMenuScreen({
    super.key,
    required this.title,
    required this.gameId,
    required this.openSessionStatus,
    required this.closeSessionStatus,
  });

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  Future<List<GameItem>>? _futureGames;
  final storage = GetStorage();
  late String _currentLanguageCode;
  Future<String>? _translatedScreenTitleFuture;
  final Map<String, String> _translationCache = {};

  @override
  void initState() {
    super.initState();
    _currentLanguageCode = storage.read('selectedLanguage') ?? 'en';
    _translatedScreenTitleFuture = _getTranslatedName(widget.title);

    storage.listenKey('selectedLanguage', (value) {
      if (value != null && value is String && value != _currentLanguageCode) {
        setState(() {
          _currentLanguageCode = value;
          _translationCache.clear();
          _translatedScreenTitleFuture = _getTranslatedName(widget.title);
          _futureGames = fetchGameList();
        });
      }
    });
    _futureGames = fetchGameList();
  }

  Future<String> _getTranslatedName(String originalName) async {
    if (_currentLanguageCode == 'en') {
      return originalName;
    }

    final cacheKey = '$originalName:$_currentLanguageCode';
    if (_translationCache.containsKey(cacheKey)) {
      log(
        'Returning "$originalName" translation from in-memory cache.',
        name: 'TranslationCache',
      );
      return _translationCache[cacheKey]!;
    }

    final storedTranslation = storage.read('translation_$cacheKey');
    if (storedTranslation != null && storedTranslation is String) {
      _translationCache[cacheKey] = storedTranslation;
      log(
        'Returning "$originalName" translation from GetStorage cache.',
        name: 'TranslationCache',
      );
      return storedTranslation;
    }

    try {
      final translated = await TranslationHelper.translate(
        originalName,
        _currentLanguageCode,
      );
      if (translated.isNotEmpty) {
        _translationCache[cacheKey] = translated;
        storage.write('translation_$cacheKey', translated);
        log(
          'Fetched and cached translation for "$originalName": "$translated".',
          name: 'TranslationFetch',
        );
        return translated;
      } else {
        log(
          'TranslationHelper returned empty text for "$originalName". Falling back to original.',
          name: 'GameMenuScreen.Translation',
        );
        return originalName;
      }
    } catch (e) {
      log(
        'Error translating "$originalName": $e. Falling back to original name.',
        name: 'GameMenuScreen.Translation',
      );
      return originalName;
    }
  }

  Future<List<GameItem>> fetchGameList() async {
    String? bearerToken = storage.read('accessToken');
    if (bearerToken == null || bearerToken.isEmpty) {
      log(
        'Error: Access token not found in GetStorage or is empty.',
        name: 'GameMenuScreen.Auth',
      );
      throw Exception('Access token not found or is empty');
    }

    log('Fetching game bid types from API...', name: 'GameMenuScreen.API');
    final response = await http.get(
      Uri.parse("${Constant.apiEndpoint}game-bid-type"),
      headers: {
        'deviceId': 'qwert',
        'deviceName': 'sm2233',
        'accessStatus': '1',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['status'] == true && decoded['info'] != null) {
        final List data = decoded['info'];
        List<GameItem> gameItems = [];

        log("API Response Status True: ${json.encode(decoded)}");

        for (var itemJson in data) {
          GameItem gameItem = GameItem.fromJson(itemJson);
          gameItems.add(gameItem);

          _getTranslatedName(gameItem.name)
              .then((translatedName) {
                if (mounted) {
                  setState(() {
                    gameItem.updateDisplayName(translatedName);
                  });
                }
              })
              .catchError((e) {
                log(
                  'Error setting display name for ${gameItem.name}: $e',
                  name: 'GameMenuScreen.Translation',
                );
              });
        }
        log(
          'Successfully fetched and initialized ${gameItems.length} game items.',
          name: 'GameMenuScreen.API',
        );
        return gameItems;
      } else {
        log(
          "API Response Status Not True or Info Missing: ${json.encode(decoded)}",
          name: 'GameMenuScreen.API',
        );
        throw Exception(
          "No game items found in API response or status is false.",
        );
      }
    } else {
      log(
        "API Error: ${response.statusCode}, ${response.body}",
        name: 'GameMenuScreen.API',
      );
      throw Exception("Failed to load game list: ${response.statusCode}");
    }
  }

  Future<void> _showMarketClosedDialog(String gameName) async {
    final translatedTitle = await _getTranslatedName('Market Closed');
    final translatedOk = await _getTranslatedName('OK');
    final translatedContentPrefix = await _getTranslatedName('The market for');
    final translatedContentSuffix = await _getTranslatedName(
      'is currently closed.',
    );

    final String fullyTranslatedContent =
        '$translatedContentPrefix $gameName $translatedContentSuffix';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(translatedTitle),
          content: Text(fullyTranslatedContent),
          actions: <Widget>[
            TextButton(
              child: Text(translatedOk),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper methods for card colors based on image
  Color _getCardColor(int index) {
    final colors = [
      const Color(0xFFF0d9d3), // Light pink - Single Digits
      const Color(0xFFEFE6c9), // Light yellow - Single Digits Bulk
      const Color(0xFFF0D6EF), // Light purple - Jodi
      const Color(0xFFF0D6EF), // Light purple - Jodi Bulk
      const Color(0xFFE9dCf8), // Light purple - Single Pana
      const Color(0xFFF1d7E4), // Light pink - Single Pana Bulk
      const Color(0xFFDDEFD9), // Light green - Double Pana
      const Color(0xFFFEF0E6),
      const Color(0xFFF0D6EF),
      const Color(0xFFFF0D9D3),
      const Color(0xFFFF0D9D3),
      const Color(0xFFD8ECF3),
      // Light peach - Double Pana Bulk
    ];
    return colors[index % colors.length];
  }

  Color _getIconCircleColor(int index) {
    final colors = [
      const Color(0xFFF4c1a2), // Peach circle
      const Color(0xFFF3D881), // Yellow circle
      const Color(0xFFF56EEE), // Pink circle
      const Color(0xFFF56EEE), // Pink circle
      const Color(0xFFc98FFF), // Purple circle
      const Color(0xFFFE97C2), // Pink circle
      const Color(0xFFA7FD82), // Green circle
      const Color(0xFFFFDDCC), // Orange circle
    ];
    return colors[index % colors.length];
  }

  Color _getIconColor(int index) {
    final colors = [
      const Color(0xFFFF6B4A), // Orange-red icon
      const Color(0xFFFFB800), // Yellow-orange icon
      const Color(0xFFBC43D1), // Magenta icon
      const Color(0xFFBC43D1), // Magenta icon
      const Color(0xFF9D4EDD), // Purple icon
      const Color(0xFFFF4081), // Pink icon
      const Color(0xFF10B981), // Green icon
      const Color(0xFFFF8C42), // Orange icon
    ];
    return colors[index % colors.length];
  }

  Color _getBottomBarColor(int index) {
    final colors = [
      const Color(0xFFFF6B4A), // Orange bar
      const Color(0xFFFFB800), // Yellow bar
      const Color(0xFFD946EF), // Magenta bar
      const Color(0xFFD946EF), // Magenta bar
      const Color(0xFF9D4EDD), // Purple bar
      const Color(0xFFFF4081), // Pink bar
      const Color(0xFF10B981), // Green bar
      const Color(0xFFFF8C42), // Orange bar
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CurvedAppBar(title: widget.title),
      body: SafeArea(
        child: RefreshIndicator(
          color: Color(0xFFFF2600),
          onRefresh: () async {
            log('Refreshing game menu data...', name: 'GameMenuScreen.Refresh');
            setState(() {
              _translationCache.clear();
              _translatedScreenTitleFuture = _getTranslatedName(widget.title);
              _futureGames = fetchGameList();
            });
          },
          child: FutureBuilder<List<GameItem>>(
            future: _futureGames,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF2600)),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Text(
                      "Error loading games: ${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFF2600),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No games found"));
              } else {
                final games = snapshot.data!;

                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(40),
                  child: GridView.builder(
                    itemCount: games.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.89,
                        ),
                    itemBuilder: (context, index) {
                      final item = games[index];
                      final gameType = item.type;

                      // Get colors based on index from predefined color schemes
                      Color cardColor = _getCardColor(index);
                      Color iconCircleColor = _getIconCircleColor(index);
                      Color iconColor = _getIconColor(index);
                      Color bottomBarColor = _getBottomBarColor(index);

                      return GestureDetector(
                        onTap: () async {
                          log(
                            "Attempting navigation for Game Type: $gameType, Name: ${item.name}",
                            name: 'GameMenuScreen.Tap',
                          );

                          if (widget.openSessionStatus == false &&
                              item.sessionSelection == false) {
                            await _showMarketClosedDialog(
                              item.currentDisplayName,
                            );
                            return;
                          }

                          String parentScreenTranslatedTitle =
                              await _translatedScreenTitleFuture!;

                          Widget? destinationScreen;
                          try {
                            switch (gameType) {
                              case 'singleDigits':
                                destinationScreen = SingleDigitBetScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameName: item.name,
                                  gameCategoryType: item.type,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'spMotor':
                                destinationScreen = SPMotorsBetScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameName: item.name,
                                  gameCategoryType: item.type,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'doublePana':
                                destinationScreen = DoublePanaBetScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameName: item.name,
                                  gameCategoryType: item.type,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'dpMotor':
                                destinationScreen = DPMotorsBetScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameName: item.name,
                                  gameCategoryType: item.type,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'triplePana':
                                destinationScreen = TPMotorsBetScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameName: item.name,
                                  gameCategoryType: item.type,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'singleDigitsBulk':
                                destinationScreen = SingleDigitsBulkScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  gameName: item.name,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'doublePanaBulk':
                              case 'singlePanaBulk':
                                destinationScreen = SinglePannaBulkBoardScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  gameName: item.name,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'panelGroup':
                                destinationScreen = PanelGroupScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameName: item.name,
                                  gameCategoryType: item.type,
                                );
                                break;

                              case 'jodi':
                              case 'groupDigit':
                              case 'twoDigitPanna':
                                destinationScreen = JodiBidScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  gameName: item.name,
                                );
                                break;

                              case 'jodiBulk':
                                destinationScreen = JodiBulkScreen(
                                  screenTitle:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  gameName: item.name,
                                );
                                break;

                              case 'singlePana':
                                destinationScreen = SinglePanaScreen(
                                  title:
                                      "$parentScreenTranslatedTitle ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'twoDigitsPanel':
                                destinationScreen = TwoDigitPanelScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                );
                                break;

                              case 'groupJodi':
                                destinationScreen = GroupJodiScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                );
                                break;

                              case 'digitBasedJodi':
                                destinationScreen = DigitBasedBoardScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId.toString(),
                                  gameType: item.type,
                                  gameName: item.name,
                                );
                                break;

                              case 'oddEven':
                                destinationScreen = OddEvenBoardScreen(
                                  title:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'choicePannaSPDP':
                                destinationScreen = ChoiceSpDpTpBoardScreen(
                                  screenTitle:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  gameName: item.name,
                                  selectionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'SPDPTP':
                                destinationScreen = SpDpTpBoardScreen(
                                  screenTitle:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  openSessionStatus: widget.openSessionStatus,
                                );
                                break;

                              case 'redBracket':
                                destinationScreen = RedBracketBoardScreen(
                                  screenTitle:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                );
                                break;

                              case 'halfSangamA':
                                destinationScreen = HalfSangamABoardScreen(
                                  screenTitle:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  gameName: item.name,
                                );
                                break;

                              case 'halfSangamB':
                                destinationScreen = HalfSangamBBoardScreen(
                                  screenTitle:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  gameName: item.name,
                                );
                                break;

                              case 'fullSangam':
                                destinationScreen = FullSangamBoardScreen(
                                  screenTitle:
                                      "$parentScreenTranslatedTitle, ${item.currentDisplayName}",
                                  gameId: widget.gameId,
                                  gameType: item.type,
                                  gameName: item.name,
                                );
                                break;

                              default:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "No screen available for ${item.currentDisplayName}",
                                    ),
                                  ),
                                );
                                log(
                                  "Unhandled game type: ${item.type}",
                                  name: 'GameMenuScreen.Navigation',
                                );
                                break;
                            }

                            if (destinationScreen != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => destinationScreen!,
                                ),
                              );
                            }
                          } catch (e, st) {
                            log(
                              "Error navigating: $e\n$st",
                              name: 'GameMenuScreen.Navigation',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Failed to navigate: ${e.toString()}",
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Circular icon container
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: iconCircleColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.network(
                                    item.image,
                                    width: 35,
                                    height: 35,
                                    color: iconColor,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                      Icons.casino_outlined,
                                      size: 45,
                                      color: iconColor,
                                    ),
                                  ),
                                ),
                              ),
                              // Game name text
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: Text(
                                  item.currentDisplayName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3142),
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              // Bottom colored bar indicator
                              Container(
                                height: 6,
                                width: 53,
                                decoration: BoxDecoration(
                                  color: bottomBarColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
