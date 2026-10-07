// File: lib/HomeScreen.dart
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Bids/MyBidsPage.dart';
import '../ChartScreen/ChartScreen.dart';
import '../Helper/Toast.dart';
import '../Helper/UserController.dart';
import '../Login/LoginWithMpinScreen.dart';
import '../Navigation/FundsFragmentContainer.dart';
import '../Notice/WithdrawInfoScreen.dart';
import '../Notification/NotificationScreen.dart'; // assumes NoticeHistoryScreen is here
import '../Passbook/PassbookPage.dart';
import '../SetMPIN/SetNewPinScreen.dart';
import '../SettingsScreen/SettingsScreen.dart';
import '../Support/ChatSupport/ChatSupport.dart';
import '../Support/SupportPage.dart';
import '../Video/LanguageSelectionScreen.dart';
import '../components/AppName.dart';
import '../game/gameRates/GameRateScreen.dart';
import '../ulits/ColorsR.dart';
import '../ulits/Constents.dart';
import 'HomePage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Safe find-or-put (in case main.dart missed registering once)
  late final UserController userController = Get.isRegistered<UserController>()
      ? Get.find<UserController>()
      : Get.put(UserController(), permanent: true);

  final GetStorage storage = GetStorage();

  int _selectedIndex = 2; // Default: Home tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    log('HomeScreen sees UserController hash: ${userController.hashCode}');

    // ✅ First fill user → then others (avoid race)
    _bootstrapLoad();

    storage.write('isLoggedIn', true);

    // Optional: start polling so wallet/flags stay fresh
    userController.startLivePolling(interval: const Duration(seconds: 6));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    userController.stopLivePolling();
    super.dispose();
  }

  // App resume par light refresh
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      userController.fetchAndUpdateUserDetails();
    }
  }

  Future<void> _bootstrapLoad() async {
    try {
      // 1) Must be first (sets mobileNo, accountStatus, wallet, etc.)
      await userController.fetchAndUpdateUserDetails();

      // 2) Dependent stuff in parallel
      await Future.wait([
        userController.fetchAndUpdateFeeSettings(),
        userController.fetchAndUpdateContactDetails(),
        userController.fetchPaymentDetails(),
      ]);
    } catch (e, st) {
      log('Warm-up error: $e', stackTrace: st);
    }
  }

  // ---------- WhatsApp Helpers ----------
  String _normalizePhone(String raw, {String defaultCountryCode = '91'}) {
    var p = raw.replaceAll(RegExp(r'[^0-9]'), '');
    p = p.replaceFirst(RegExp(r'^0+'), '');
    if (p.length == 10) p = '$defaultCountryCode$p';
    return p;
  }

  /// Priority: contactWhatsapp -> contactMobile -> storage.whatsappNo -> user.mobileNo
  String? _getSupportNumber() {
    final w = userController.contactWhatsappNo.value.trim();
    if (w.isNotEmpty) return w;

    final c = userController.contactMobileNo.value.trim();
    if (c.isNotEmpty) return c;

    final s = (storage.read('whatsappNo') ?? '').toString().trim();
    if (s.isNotEmpty) return s;

    final u = userController.mobileNo.value.trim();
    if (u.isNotEmpty) return u;

    return null;
  }

  Future<void> launchWhatsAppChat({String? message}) async {
    try {
      final raw = _getSupportNumber();
      if (raw == null) {
        popToast(
          "WhatsApp number not available",
          4,
          Colors.white,
          ColorsR.appColorRed,
        );
        log("❌ WhatsApp number missing (all sources empty)");
        return;
      }

      final phone = _normalizePhone(raw);
      final encoded = (message ?? '').trim().isEmpty
          ? ''
          : Uri.encodeComponent(message!.trim());

      final nativeUri = Uri.parse(
        'whatsapp://send?phone=$phone${encoded.isNotEmpty ? '&text=$encoded' : ''}',
      );
      if (await canLaunchUrl(nativeUri)) {
        final ok = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
        log(
          ok ? '✅ Launched WhatsApp (native): $nativeUri' : '❌ Failed (native)',
        );
        if (ok) return;
      }

      final webUri = Uri.parse(
        'https://wa.me/$phone${encoded.isNotEmpty ? '?text=$encoded' : ''}',
      );
      if (await canLaunchUrl(webUri)) {
        final ok = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
        log(ok ? '✅ Launched WhatsApp (web): $webUri' : '❌ Failed (web)');
        if (ok) return;
      }

      popToast(
        "Could not launch WhatsApp",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
    } catch (e, st) {
      log('❌ WhatsApp launch error: $e', stackTrace: st);
      popToast(
        "Error launching WhatsApp",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
    }
  }
  // --------------------------------------
  
  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://gama567s.com/privacy-policy'); // Privacy Policy URL
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      popToast(
        "Could not open privacy policy",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
      log("Could not launch privacy policy URL: $url");
    }
  }
  final List<Widget> _screens = [
    BidScreen(), // 0
    PassbookPage(), // 1
    HomePage(), // 2 (Main Home Tab)
    FundsFragmentContainer(), // 3
    SupportPage(), // 4
    WithdrawInfoScreen(), // 5 (Notice/Rules)
    SettingsScreen(), // 6
    GameRateScreen(), // 7
    ChatScreen(), // 8 (we open WhatsApp instead on tap)
  ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _selectedIndex = index);
    } else {
      log("Error: Attempted to select invalid index: $index");
    }
  }

  void _navigateToNewScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _navigateToDrawerScreenAndPush(Widget screen) {
    Navigator.pop(context);
    _navigateToNewScreen(screen);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 2) {
          _onItemTapped(2);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        drawer: _buildDrawer(),
        // Conditionally show AppBar - hide when Funds tab (index 3) is selected
        appBar: (_selectedIndex == 3 || _selectedIndex == 0)
            ? null
            : _buildAppBar(context),
        body: SafeArea(
          child: (_selectedIndex >= 0 && _selectedIndex < _screens.length)
              ? _screens[_selectedIndex]
              : const Center(child: Text("Error: Screen not found")),
        ),
        bottomNavigationBar: SafeArea(child: _buildBottomAppBar()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 60,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Menu Icon
            Builder(
              builder: (ctx) => InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.menu, size: 28, color: Colors.red.shade700),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Image.asset(
              "assets/images/logo2.png", // ← अपना logo path डालें
              height: 42,
              // height आप change कर सकते हैं
              fit: BoxFit.contain,
            ),

            const Spacer(),

            // Wallet Section
            Obx(
              () => userController.accountStatus.value
                  ? Row(
                      children: [
                        Image.asset(
                          "assets/icons/walletCard.png", // yaha apna icon ka path
                          width: 24,
                          height: 24,
                          //  color: Colors.white, // optional: agar aap icon ko color dena chahte ho
                        ),

                        const SizedBox(width: 4),
                        Text(
                          "₹${userController.walletBalance.value}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Notification
            Obx(
              () => userController.accountStatus.value
                  ? IconButton(
                      onPressed: () {
                        _navigateToNewScreen(const NoticeHistoryScreen());
                      },
                      icon: Image.asset(
                        "assets/images/notification.png", // <-- अपना icon path डालें
                        height: 24,
                        width: 24,
                        color:
                            Colors.black, // remove if original color चाहते हो
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF3A3939), // LIGHTER GREY
      child: SafeArea(
        child: Column(
          children: [
            // Header (Name + Mobile)
            Container(
              padding: const EdgeInsets.all(16),
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFF4A4A4A), // SAME BACKGROUND
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 42, color: Colors.grey),

                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(
                                () => Text(
                                  userController.fullName.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Obx(
                                () => Text(
                                  userController.mobileNoEnc.value,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Menu items for inactive users (including logout)
            Obx(() => !userController.accountStatus.value
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: _drawerItem("assets/images/share.png", "Share Application", () {
                          Navigator.pop(context);
                          Share.share("Visit our website:\nhttps://gama567s.com");
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: _drawerItem("assets/images/policy.png", "Privacy Policy", () {
                          Navigator.pop(context);
                          _launchPrivacyPolicy();
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: _drawerItem("assets/images/whatsapp.png", "Support WhatsApp", () {
                          Navigator.pop(context);
                          launchWhatsAppChat();
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: _drawerItem("assets/images/charts.png", "Charts", () {
                          _navigateToDrawerScreenAndPush(const ChartScreen());
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: _drawerItem("assets/images/power.png", "Logout", () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginWithMpinScreen(),
                            ),
                          );
                        }),
                      ),
                    ],
                  )
                : const SizedBox.shrink()),
            // Drawer Menu Items - Only show when account is active
            Obx(() => userController.accountStatus.value
                ? Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _drawerItem("assets/images/home.png", "Home", () {
                          Navigator.pop(context);
                          _onItemTapped(2);
                        }),
                        _drawerItem("assets/icons/bid_nav1.png", "My Bids", () {
                          Navigator.pop(context);
                          _onItemTapped(0);
                        }),
                        _drawerItem("assets/images/mpin_nav.png", "MPIN", () {
                          Navigator.pop(context);
                          _handleMpin();
                        }),
                        _drawerItem("assets/images/passbook.png", "Passbook", () {
                          _navigateToDrawerScreenAndPush(const PassbookPage());
                        }),
                        _drawerItem("assets/images/videos.png", "Videos", () {
                          _navigateToDrawerScreenAndPush(
                            const LanguageSelectionScreen(),
                          );
                        }),
                        _drawerItem("assets/images/rate_stars.png", "Game Rates", () {
                          Navigator.pop(context);
                          _onItemTapped(7);
                        }),
                        _drawerItem("assets/images/charts.png", "Charts", () {
                          _navigateToDrawerScreenAndPush(const ChartScreen());
                        }),
                        _drawerItem("assets/images/setting_nav.png", "Settings", () {
                          Navigator.pop(context);
                          _onItemTapped(6);
                        }),
                        _drawerItem(
                          "assets/images/share.png",
                          "Share Application",
                          () {
                            Navigator.pop(context);
                            Share.share("Visit our website:\nhttps://gama567s.com");
                          },
                        ),
                        _drawerItem("assets/images/policy.png", "Privacy Policy", () {
                          Navigator.pop(context);
                          _launchPrivacyPolicy();
                        }),
                        _drawerItem("assets/images/whatsapp.png", "Support WhatsApp", () {
                          Navigator.pop(context);
                          launchWhatsAppChat();
                        }),
                        _drawerItem("assets/images/power.png", "Logout", () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginWithMpinScreen(),
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                : const Expanded(child: SizedBox.shrink())),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(String icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: Image.asset(icon, width: 24, height: 24, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDrawerItem(
    String imagePath,
    String title,
    VoidCallback onTap,
    bool visible,
  ) {
    if (!visible) return const SizedBox.shrink();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Image.asset(
        imagePath,
        width: 24,
        height: 24,
        color: Colors.white, // Make icons white
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white, // Make text white
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),

      onTap: onTap,
    );
  }

  void _handleMpin() async {
    final String mobile = userController.mobileNo.value;
    if (mobile.isEmpty) {
      log("Mobile number is not available.");
      popToast(
        "Mobile number is not available",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
      return;
    }

    log("Mobile number: $mobile");
    // Navigate directly to SetNewPinScreen without sending OTP
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SetNewPinScreen(mobile: mobile)),
    );
  }

  Widget _buildBottomAppBar() {
    return Obx(() {
      final accountStatus = userController.accountStatus.value;
      return SafeArea(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300, // 👈 Color
                    width: 1, // 👈 Thickness
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          "assets/icons/bid_nav1.png",
                          "My Bids",
                          0,
                          visible: accountStatus,
                        ),
                        _buildNavItem(
                          "assets/images/passbook.png",
                          "Passbook",
                          1,
                          visible: accountStatus,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.15),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          "assets/images/funds.png",
                          "Funds",
                          3,
                          visible: accountStatus,
                        ),
                        _buildNavItem(
                          "assets/images/chat_icon.png",
                          "Support",
                          8,
                          visible: accountStatus,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Center FAB-like home button (partially above bottom bar)
            Positioned(
              top: -16,
              child: SizedBox(
                width: 55,
                height: 55,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onItemTapped(2),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Color(0xffFF2600),
                        shape: BoxShape.circle,
                        //   border: Border.all(color: Color(0xFFFF2600)width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          "assets/icons/home.png", // <-- अपना icon file यहाँ
                          height: 24,
                          width: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNavItem(
    String iconPath,
    String label,
    int index, {
    bool visible = true,
  }) {
    if (!visible) return const SizedBox.shrink();

    final isSelected = _selectedIndex == index;
    final color = isSelected ? Color(0xffFF2600) : Colors.black;

    return GestureDetector(
      onTap: () {
        if (index == 8) {
          launchWhatsAppChat();
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PassbookPage()),
          );
        } else {
          _onItemTapped(index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 30, height: 30, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
