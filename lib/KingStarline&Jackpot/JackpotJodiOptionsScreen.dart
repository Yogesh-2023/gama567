import 'dart:convert';
import 'dart:developer'; // For log messages

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:new_sara/KingStarline&Jackpot/games/StarlineJodiBidScreen.dart';
import 'package:new_sara/KingStarline&Jackpot/games/StarlineTriplePana.dart';
import 'package:new_sara/ulits/curved_appbar.dart';

// Ensure these imports are correct and the files exist in your project
import '../Helper/TranslationHelper.dart';
import '../Helper/UserController.dart';
import 'games/StarlineDPMotorsScreen.dart';
import 'games/StarlineOddEvenBoardScreen.dart';
import 'games/StarlineSPDPTPScreen.dart';
import 'games/StarlineSPMotorsScreen.dart';
import 'games/StarlineSingleDigit.dart';
import 'games/StarlineSinglePana.dart';

// JackpotBidType model class
class JackpotBidType {
  final int id;
  final String title;
  final String image;
  final String type;
  late String translatedTitle; // This will hold the translated title
  final bool sessionSelection;
  final bool digitJodiStatus;

  JackpotBidType({
    required this.id,
    required this.title,
    required this.image,
    required this.type,
    required this.sessionSelection,
    required this.digitJodiStatus,
    String translatedTitle =
        '', // Initialize with empty string, will be updated
  }) : this.translatedTitle = translatedTitle; // Use initializer list

  factory JackpotBidType.fromJson(Map<String, dynamic> json) {
    return JackpotBidType(
      id: json['id'] ?? 0,
      title: json['name'] ?? '',
      image: json['image'] ?? '',
      type: json['type'] ?? '',
      sessionSelection: json['sessionSelection'] ?? false,
      digitJodiStatus: json['digitJodiStatus'] ?? false,
      // Do not set translatedTitle here directly from JSON unless API provides it
      // translatedTitle will be updated after fetching
    );
  }

  // Method to update translated title after fetching
  void updateTranslatedTitle(String newTitle) {
    translatedTitle = newTitle;
  }
}

// JackpotJodiOptionsScreen widget
class JackpotJodiOptionsScreen extends StatefulWidget {
  final String gameTime;
  final int gameId;
  final String title;
  final bool digitJodiStatus;
  final bool sessionSelection;

  const JackpotJodiOptionsScreen({
    super.key,
    required this.gameTime,
    required this.gameId,
    required this.title,
    required this.digitJodiStatus,
    required this.sessionSelection,
  });

  @override
  State<JackpotJodiOptionsScreen> createState() =>
      _JackpotJodiOptionsScreenState();
}

class _JackpotJodiOptionsScreenState extends State<JackpotJodiOptionsScreen> {
  List<JackpotBidType> _options = [];
  bool _isLoading = true;

  final GetStorage _storage = GetStorage();
  late String _currentLanguageCode;
  int _walletBalance = 0;

  final Map<String, String> _translationCache = {};

  Future<String>? _translatedWalletTextFuture;
  Future<String>? _translatedNetworkErrorTextFuture;
  Future<String>? _translatedNoBidTypesTextFuture;
  Future<String>? _translatedMarketClosedTitleFuture;
  Future<String>? _translatedOkTextFuture;
  Future<String>? _translatedMarketClosedContentPrefixFuture;
  Future<String>? _translatedMarketClosedContentSuffixFuture;
  Future<String>? _translatedAuthenticationErrorTextFuture;
  Future<String>? _translatedFailedToLoadTextFuture;
  Future<String>? _translatedNoScreenConfiguredTextFuture;

  final UserController userController = Get.put(UserController());

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

    _preTranslateFixedTexts(); // Pre-translate fixed texts

    // Listen for language changes
    _storage.listenKey('selectedLanguage', (value) {
      if (value != null && value is String) {
        if (value != _currentLanguageCode) {
          _currentLanguageCode = value;
          _translationCache.clear(); // Clear cache on language change
          _preTranslateFixedTexts(); // Re-translate fixed texts
          fetchJackpotBidTypes(); // Re-fetch and re-translate all options
        }
      }
    });

    // Listen for wallet balance changes
    double walletBalance = double.parse(userController.walletBalance.value);
    _walletBalance = walletBalance.toInt();

    fetchJackpotBidTypes(); // Initial fetch of jackpot bid types
  }

  void _preTranslateFixedTexts() {
    _translatedWalletTextFuture = _getTranslatedText('Wallet');
    _translatedNetworkErrorTextFuture = _getTranslatedText(
      'Network error. Please try again later.',
    );
    _translatedNoBidTypesTextFuture = _getTranslatedText(
      'No jackpot bid types available or failed to load.',
    );
    _translatedMarketClosedTitleFuture = _getTranslatedText('Market Closed');
    _translatedOkTextFuture = _getTranslatedText('OK');
    _translatedMarketClosedContentPrefixFuture = _getTranslatedText(
      'The market for',
    );
    _translatedMarketClosedContentSuffixFuture = _getTranslatedText(
      'is currently closed.',
    );
    _translatedAuthenticationErrorTextFuture = _getTranslatedText(
      'Authentication error: Please log in again.',
    );
    _translatedFailedToLoadTextFuture = _getTranslatedText(
      'Failed to load jackpot bid types:',
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

  Future<void> fetchJackpotBidTypes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _options = []; // Clear previous options when fetching new ones
    });

    final url = Uri.parse(
      'https://admin.gama567s.com/api/v1/jackpot-game-bid-type',
    );
    String? bearerToken = _storage.read("accessToken");

    if (bearerToken == null || bearerToken.isEmpty) {
      log('Error: Access token not found or is empty.');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

      if (!mounted) return; // Check mounted status after async operation

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('Full Jackpot API Response Data: ${jsonEncode(data)}');

        if (data['status'] == true && data['info'] != null) {
          final List<dynamic> list = data['info'];
          List<JackpotBidType> fetchedOptions = [];

          for (var itemJson in list) {
            try {
              var option = JackpotBidType.fromJson(itemJson);
              fetchedOptions.add(option);
            } catch (e) {
              log(
                'Error parsing JackpotBidType from JSON item: $itemJson. Error: $e',
              );
            }
          }

          List<JackpotBidType> translatedOptions = await Future.wait(
            fetchedOptions.map((option) async {
              // Ensure translation is done on the 'title' property
              option.updateTranslatedTitle(
                await _getTranslatedText(option.title),
              );
              return option;
            }).toList(),
          );

          if (mounted) {
            setState(() {
              _options = translatedOptions;
              _isLoading = false;
            });
          }
        } else {
          log(
            "Jackpot API Response Status Not True or Info Missing: ${json.encode(data)}",
          );
          if (mounted) {
            setState(() {
              _options = [];
              _isLoading = false;
            });
          }
          final String noBidTypesMsg =
              await _translatedNoBidTypesTextFuture ??
              'No jackpot bid types available or failed to load.';
          _showSnackBar(noBidTypesMsg);
        }
      } else {
        log("Jackpot API Error: ${response.statusCode}, ${response.body}");
        if (mounted) {
          setState(() => _isLoading = false);
        }
        final String failedToLoadMsg =
            await _translatedFailedToLoadTextFuture ??
            'Failed to load jackpot bid types:';
        _showSnackBar('$failedToLoadMsg ${response.statusCode}');
      }
    } catch (e) {
      log("Exception during Jackpot API call: $e");
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CurvedAppBar(title: widget.title),
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
                          'No jackpot bid types available or failed to load.',
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
    JackpotBidType item,
    int index,
    Color cardColor,
    Color iconCircleColor,
    Color iconColor,
    Color bottomBarColor,
  ) {
    return InkWell(
      onTap: () async {
        log(
          'Tapped on: ${item.translatedTitle} (Original: ${item.title}), Type: ${item.type}',
        );

        final String nextScreenTitle =
            "${widget.title}, ${item.translatedTitle}";

        Widget? destinationScreen;
        final String normalizedItemType = item.type.toLowerCase().trim();
        log('Normalized Item Type for switch: $normalizedItemType');

        switch (normalizedItemType) {
          case 'singledigits':
            destinationScreen = StarlineSingleDigitBetScreen(
              title: nextScreenTitle,
              gameId: widget.gameId,
              gameName: item.title,
              gameCategoryType: item.type,
              selectionStatus: true,
            );
            break;

          case 'oddeven':
            destinationScreen = StarlineOddEvenBoardScreen(
              title: nextScreenTitle,
              gameId: widget.gameId,
              gameName: item.title,
              gameType: item.type,
              selectionStatus: true,
            );
            break;

          case 'singlepana':
            destinationScreen = StarlineSinglePannaScreen(
              title: nextScreenTitle,
              gameId: widget.gameId,
              gameName: item.title,
              gameType: item.type,
              selectionStatus: true,
            );
            break;

          case 'doublepana':
            destinationScreen = StarlineDPMotorsScreen(
              title: nextScreenTitle,
              gameId: widget.gameId,
              gameName: item.title,
              gameCategoryType: item.type,
            );
            break;

          case 'triplepana':
            destinationScreen = StarlineTPMotorsScreen(
              title: nextScreenTitle,
              gameId: widget.gameId,
              gameName: item.title,
              selectionStatus: true,
              gameCategoryType: item.type,
            );
            break;

          case 'spdptp':
            destinationScreen = StarlineSpDpTpScreen(
              screenTitle: nextScreenTitle,
              gameId: widget.gameId,
              gameType: item.type,
            );
            break;

          case 'spmotor':
            destinationScreen = StarlineSPMotorsScreen(
              title: nextScreenTitle,
              gameId: widget.gameId,
              gameName: item.title,
              gameCategoryType: item.type,
            );
            break;

          case 'dpmotor':
            destinationScreen = StarlineDPMotorsScreen(
              title: nextScreenTitle,
              gameId: widget.gameId,
              gameName: item.title,
              gameCategoryType: item.type,
            );
            break;

          case 'jodi':
            // You need to replace `StarlineJodiScreen` with your actual Jodi betting screen.
            // This is a placeholder. Make sure you have this screen created and imported.
            destinationScreen = StarlineJodiBidScreen(
              title: nextScreenTitle,
              gameId: widget.gameId,
              gameName: item.title,
              gameType: item.type,
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
              width: 90,
              height: 90,
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
                    log('Image load error: ${item.image} | $error');
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
                item.translatedTitle, // Display the translated title
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
