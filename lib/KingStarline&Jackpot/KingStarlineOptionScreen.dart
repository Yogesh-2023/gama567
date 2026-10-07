import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:new_sara/KingStarline&Jackpot/games/StarlineDoublePana.dart';
import 'package:new_sara/KingStarline&Jackpot/games/StarlineSPDPTPScreen.dart';
import 'package:new_sara/KingStarline&Jackpot/games/StarlineSPMotorsScreen.dart';
import 'package:new_sara/KingStarline&Jackpot/games/StarlineSinglePana.dart';
import 'package:new_sara/ulits/curved_appbar.dart';

import '../Helper/TranslationHelper.dart';
import '../Helper/UserController.dart';
import '../ulits/Constents.dart';
import 'games/StarlineDPMotorsScreen.dart';
import 'games/StarlineOddEvenBoardScreen.dart';
import 'games/StarlineSingleDigit.dart';
import 'games/StarlineTriplePana.dart';

// Class to model a bid type option for King Starline games.
class KingStarlineBidType {
  final int id;
  final String title;
  final String image;
  final String type;
  final bool digitPannaStatus;
  String translatedTitle;

  KingStarlineBidType({
    required this.id,
    required this.title,
    required this.image,
    required this.type,
    required this.digitPannaStatus,
    this.translatedTitle = '',
  });

  factory KingStarlineBidType.fromJson(Map<String, dynamic> json) {
    return KingStarlineBidType(
      id: json['id'] ?? 0,
      title: json['name'] ?? '',
      image: json['image'] ?? '',
      type: json['type'] ?? '',
      digitPannaStatus: json['digitPannaStatus'] ?? false,
    );
  }

  void updateTranslatedTitle(String newTitle) {
    translatedTitle = newTitle;
  }
}

// The main screen for displaying King Starline game options.
class KingStarlineOptionScreen extends StatefulWidget {
  final String gameTime;
  final String title;
  final dynamic starlineGameId;
  final bool paanaStatus;
  final String registeredId;

  const KingStarlineOptionScreen({
    super.key,
    required this.gameTime,
    required this.title,
    required this.starlineGameId,
    required this.paanaStatus,
    required this.registeredId,
  });

  @override
  State<KingStarlineOptionScreen> createState() =>
      _KingStarlineOptionScreenState();
}

class _KingStarlineOptionScreenState extends State<KingStarlineOptionScreen> {
  List<KingStarlineBidType> _options = [];
  bool _isLoading = true;
  final GetStorage _storage = GetStorage();
  final UserController userController = Get.put(UserController());

  late String _currentLanguageCode;
  int _walletBalance = 0;

  final Map<String, String> _translationCache = {};

  Future<String>? _translatedWalletTextFuture;
  Future<String>? _translatedNetworkErrorTextFuture;
  Future<String>? _translatedNoBidTypesTextFuture;
  Future<String>? _translatedAuthenticationErrorTextFuture;
  Future<String>? _translatedFailedToLoadTextFuture;
  Future<String>? _translatedNoScreenConfiguredTextFuture;

  // Helper methods for card colors based on image (copied from GameScreen.dart)
  Color _getCardColor(int index) {
    final colors = [
      const Color(0xFFF5E6E8), // Light pink - Single Digits
      const Color(0xFFFFF9E6), // Light yellow - Single Digits Bulk
      const Color(0xFFEFE6F5), // Light purple - Jodi
      const Color(0xFFEFE6F5), // Light purple - Jodi Bulk
      const Color(0xFFEFE6F5), // Light purple - Single Pana
      const Color(0xFFFDE6EB), // Light pink - Single Pana Bulk
      const Color(0xFFE6F5ED), // Light green - Double Pana
      const Color(0xFFFEF0E6), // Light peach - Double Pana Bulk
    ];
    return colors[index % colors.length];
  }

  Color _getIconCircleColor(int index) {
    final colors = [
      const Color(0xFFFFD4CC), // Peach circle
      const Color(0xFFFFF4CC), // Yellow circle
      const Color(0xFFE8C4F0), // Pink circle
      const Color(0xFFE8C4F0), // Pink circle
      const Color(0xFFD4C4F0), // Purple circle
      const Color(0xFFFFCCDD), // Pink circle
      const Color(0xFFCCF5DD), // Green circle
      const Color(0xFFFFDDCC), // Orange circle
    ];
    return colors[index % colors.length];
  }

  Color _getIconColor(int index) {
    final colors = [
      const Color(0xFFFF6B4A), // Orange-red icon
      const Color(0xFFFFB800), // Yellow-orange icon
      const Color(0xFFD946EF), // Magenta icon
      const Color(0xFFD946EF), // Magenta icon
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
  void initState() {
    super.initState();
    _currentLanguageCode = _storage.read('selectedLanguage') ?? 'en';

    fetchKingStarlineBidTypes();
    _preTranslateFixedTexts();
    double walletBalance = double.parse(userController.walletBalance.value);
    _walletBalance = walletBalance.toInt();

    _storage.listenKey('selectedLanguage', (value) {
      if (value != null && value is String && value != _currentLanguageCode) {
        _currentLanguageCode = value;
        _translationCache.clear();
        _preTranslateFixedTexts();
        fetchKingStarlineBidTypes();
      }
    });
  }

  void _preTranslateFixedTexts() {
    _translatedWalletTextFuture = _getTranslatedText('Wallet');
    _translatedNetworkErrorTextFuture = _getTranslatedText(
      'Network error. Please try again later.',
    );
    _translatedNoBidTypesTextFuture = _getTranslatedText(
      'No Starline games available.\nPlease try again later.',
    );
    _translatedAuthenticationErrorTextFuture = _getTranslatedText(
      'Authentication error: Please log in again.',
    );
    _translatedFailedToLoadTextFuture = _getTranslatedText(
      'Failed to load starline bid types:',
    );
    _translatedNoScreenConfiguredTextFuture = _getTranslatedText(
      'No screen configured for game type:',
    );
  }

  Future<String> _getTranslatedText(String text) async {
    if (_currentLanguageCode == 'en') {
      return text;
    }
    final cacheKey = '$text:$_currentLanguageCode';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }
    final storedTranslation = _storage.read('translation_$cacheKey');
    if (storedTranslation != null && storedTranslation is String) {
      _translationCache[cacheKey] = storedTranslation;
      return storedTranslation;
    }
    try {
      final translated = await TranslationHelper.translate(
        text,
        _currentLanguageCode,
      );
      if (translated.isNotEmpty) {
        _translationCache[cacheKey] = translated;
        _storage.write('translation_$cacheKey', translated);
        return translated;
      } else {
        log(
          'TranslationHelper returned empty text for "$text". Falling back to original.',
        );
        return text;
      }
    } catch (e) {
      log('Error translating "$text": $e. Falling back to original text.');
      return text;
    }
  }

  Future<void> fetchKingStarlineBidTypes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _options = [];
    });

    final url = Uri.parse('${Constant.apiEndpoint}starline-game-bid-type');
    String? bearerToken = _storage.read("accessToken");

    if (bearerToken == null || bearerToken.isEmpty) {
      log('Error: Access token not found or is empty. Cannot fetch bid types.');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      final String authErrorMsg =
          await _translatedAuthenticationErrorTextFuture ??
          'Authentication error: Please log in again.';
      _showSnackBar(authErrorMsg);
      return;
    }

    final headers = {
      'deviceId': 'qwerr',
      'deviceName': 'sm2233',
      'accessStatus': '1',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $bearerToken',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('Full KingStarline API Response Data: ${jsonEncode(data)}');

        if (data['status'] == true && data['info'] != null) {
          final List<dynamic> list = data['info'];
          List<KingStarlineBidType> fetchedOptions = [];

          for (var itemJson in list) {
            try {
              var option = KingStarlineBidType.fromJson(itemJson);
              fetchedOptions.add(option);
            } catch (e) {
              log(
                'Error parsing KingStarlineBidType from JSON item: $itemJson. Error: $e',
              );
            }
          }
          List<Future<void>> translationFutures = [];
          for (var option in fetchedOptions) {
            translationFutures.add(
              _getTranslatedText(option.title).then((translatedName) {
                option.updateTranslatedTitle(translatedName);
              }),
            );
          }
          await Future.wait(translationFutures);
          if (mounted) {
            setState(() {
              _options = fetchedOptions;
              _isLoading = false;
            });
          }
        } else {
          log(
            "KingStarline API Response Status Not True or Info Missing: ${json.encode(data)}",
          );
          if (mounted) {
            setState(() => _isLoading = false);
          }
          final String noBidTypesMsg =
              await _translatedNoBidTypesTextFuture ??
              'No Starline games available.\nPlease try again later.';
          _showSnackBar(noBidTypesMsg);
        }
      } else {
        log("KingStarline API Error: ${response.statusCode}, ${response.body}");
        if (mounted) {
          setState(() => _isLoading = false);
        }
        final String failedToLoadMsg =
            await _translatedFailedToLoadTextFuture ??
            'Failed to load starline bid types:';
        _showSnackBar('$failedToLoadMsg ${response.statusCode}');
      }
    } catch (e) {
      log("Exception during KingStarline API call: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
      final String networkErrorMsg =
          await _translatedNetworkErrorTextFuture ??
          'Network error. Please try again later.';
      _showSnackBar(networkErrorMsg);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.title;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CurvedAppBar(title: appBarTitle),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF2600)),
              )
            : _options.isEmpty
            ? Center(
                child: FutureBuilder<String>(
                  future: _translatedNoBidTypesTextFuture,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ??
                          'No Starline games available.\nPlease try again later.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    );
                  },
                ),
              )
            : Container(
                color: Colors.white,
                padding: const EdgeInsets.all(30),
                child: GridView.builder(
                  itemCount: _options.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final item = _options[index];
                    // Get colors based on index from predefined color schemes
                    Color cardColor = _getCardColor(index);
                    Color iconCircleColor = _getIconCircleColor(index);
                    Color iconColor = _getIconColor(index);
                    Color bottomBarColor = _getBottomBarColor(index);

                    return _optionItem(
                      item,
                      index,
                      cardColor,
                      iconCircleColor,
                      iconColor,
                      bottomBarColor,
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _optionItem(
    KingStarlineBidType item,
    int index,
    Color cardColor,
    Color iconCircleColor,
    Color iconColor,
    Color bottomBarColor,
  ) {
    final String parentScreenTitle = widget.title;
    final String nextScreenTitle =
        "$parentScreenTitle, ${item.translatedTitle}";

    return InkWell(
      onTap: () async {
        log(
          'Tapped on: ${item.translatedTitle} (Original Title: ${item.title}, Type: ${item.type})',
        );
        final gameType = item.type.toLowerCase().trim();
        Widget? destinationScreen;

        switch (gameType) {
          case 'singledigits':
            destinationScreen = StarlineSingleDigitBetScreen(
              title: nextScreenTitle,
              gameId: widget.starlineGameId,
              gameName: item.title,
              gameCategoryType: item.type,
              selectionStatus: item.digitPannaStatus,
            );
            break;

          case 'oddeven':
            destinationScreen = StarlineOddEvenBoardScreen(
              title: nextScreenTitle,
              gameId: widget.starlineGameId,
              gameName: item.title,
              gameType: item.type,
              selectionStatus: true,
            );
            break;

          case 'singlepana':
            destinationScreen = StarlineSinglePannaScreen(
              title: nextScreenTitle,
              gameId: widget.starlineGameId,
              gameName: item.title,
              gameType: item.type,
              selectionStatus: true,
            );
            break;

          case 'doublepana':
            destinationScreen = StarlineDoublePanaBetScreen(
              title: nextScreenTitle,
              gameId: widget.starlineGameId,
              gameName: item.title,
              gameCategoryType: item.type,
              selectionStatus: true,
            );
            break;

          case 'triplepana':
            destinationScreen = StarlineTPMotorsScreen(
              title: nextScreenTitle,
              gameId: widget.starlineGameId,
              gameName: item.title,
              selectionStatus: true,
              gameCategoryType: item.type,
            );
            break;

          case 'spdptp':
            destinationScreen = StarlineSpDpTpScreen(
              screenTitle: nextScreenTitle,
              gameId: widget.starlineGameId,
              gameType: item.type,
            );
            break;

          case 'spmotor':
            destinationScreen = StarlineSPMotorsScreen(
              title: nextScreenTitle,
              gameId: widget.starlineGameId,
              gameName: item.title,
              gameCategoryType: item.type,
            );
            break;

          case 'dpmotor':
            destinationScreen = StarlineDPMotorsScreen(
              title: nextScreenTitle,
              gameId: widget.starlineGameId,
              gameName: item.title,
              gameCategoryType: item.type,
            );
            break;

          default:
            final String noScreenConfiguredMsg =
                await _translatedNoScreenConfiguredTextFuture ??
                'No screen configured for game type:';
            _showSnackBar("$noScreenConfiguredMsg '${item.type}'");
            log("Unhandled game type: ${item.type}");
            break;
        }

        if (destinationScreen != null) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destinationScreen!),
          );
        }
      },
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular icon container
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: iconCircleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.network(
                  item.image,
                  width: 45,
                  height: 45,
                  color: iconColor,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    log(
                      'Image load error for ${item.title}: ${item.image} | $error',
                    );
                    return Icon(Icons.broken_image, size: 45, color: iconColor);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Game name text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.translatedTitle,
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
            const SizedBox(height: 12),
            // Bottom colored bar indicator
            Container(
              height: 4,
              width: 60,
              decoration: BoxDecoration(
                color: bottomBarColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
