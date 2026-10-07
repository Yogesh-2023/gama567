import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:new_sara/SetMPIN/SetNewPinScreen.dart';
import 'package:new_sara/HomeScreen/HomeScreen.dart';
import 'package:new_sara/components/AppNameBold.dart';

import '../Helper/Toast.dart';
import '../ulits/ColorsR.dart';
import '../ulits/Constents.dart';

class LoginWithMpinScreen extends StatefulWidget {
  const LoginWithMpinScreen({super.key});

  @override
  State<LoginWithMpinScreen> createState() => _LoginWithMpinScreenState();
}

class _LoginWithMpinScreenState extends State<LoginWithMpinScreen> {
  final TextEditingController mpinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  final storage = GetStorage();
  bool isLoading = false;
  bool isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      final biometrics = await auth.getAvailableBiometrics();

      if (isAvailable && isDeviceSupported && biometrics.isNotEmpty) {
        setState(() {
          isBiometricAvailable = true;
        });
      }
    } catch (e) {
      log("Biometric availability check error: $e");
    }
  }

  Future<void> _tryBiometricAuth() async {
    try {
      final isAvailable = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      final biometrics = await auth.getAvailableBiometrics();

      if (!isAvailable || !isDeviceSupported || biometrics.isEmpty) {
        _showSnackBar('Biometric authentication not available or supported');
        return;
      }

      final authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to verify',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        if (mounted) {
          _validateSavedMpinAndNavigate();
        }
      } else {
        _showSnackBar('Biometric authentication failed');
      }
    } catch (e) {
      log("Biometric error: $e");
      _showSnackBar('Biometric error: $e');
    }
  }

  void _onSetPinPressed() async {
    final mobileNo = storage.read('mobile');
    if (mobileNo == null || mobileNo.toString().isEmpty) {
      popToast("Mobile number not found", 4, Colors.white, ColorsR.appColorRed);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SetNewPinScreen(mobile: mobileNo)),
    );
  }

  Future<void> _loginWithMpin() async {
    final enteredMpin = mpinController.text.trim();

    if (enteredMpin.isEmpty) {
      _showSnackBar('Please enter your mPIN');
      return;
    }

    final String registerId = storage.read('registerId');
    final String accessToken = storage.read('accessToken');
    final String deviceId = storage.read('deviceId') ?? '';
    final String deviceName = storage.read('deviceName') ?? '';

    log("Register Id: $registerId");
    log("Access Token: $accessToken");

    if (registerId == null || registerId.isEmpty) {
      _showSnackBar('Registration ID not found. Please re-register.');
      return;
    }

    if (accessToken == null || accessToken.isEmpty) {
      _showSnackBar('Access token not found. Please re-login.');
      return;
    }

    try {
      final url = Uri.parse('${Constant.apiEndpoint}verify-mpin');
      final response = await http.post(
        url,
        headers: {
          'deviceId': deviceId,
          'deviceName': deviceName,
          'accessStatus': '1',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "registerId": registerId,
          "pinNo": int.tryParse(enteredMpin),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        log("MPIN Verification Response: $responseData");
        if (responseData['status'] == true) {
          _showSnackBar('Login successful!');
          await fetchAndSaveUserDetails(registerId);
          _navigateToHome();
        } else {
          _showSnackBar(
            responseData['message'] ?? 'Incorrect mPIN. Please try again.',
          );
        }
      } else {
        log(
          "❌ MPIN Verification Failed: ${response.statusCode} => ${response.body}",
        );
        _showSnackBar('Failed to verify mPIN. Please try again later.');
      }
    } catch (e) {
      log("❌ Exception during MPIN verification: $e");
      _showSnackBar('An error occurred during mPIN verification: $e');
    }
  }

  Future<void> _validateSavedMpinAndNavigate() async {
    final String? registerId = storage.read('registerId');
    if (registerId == null || registerId.isEmpty) {
      _showSnackBar('Registration ID not found. Please re-register.');
      return;
    }
    await fetchAndSaveUserDetails(registerId);
    _navigateToHome();
  }

  Future<void> fetchAndSaveUserDetails(String registerId) async {
    final storage = GetStorage();
    final url = Uri.parse('${Constant.apiEndpoint}user-details-by-register-id');
    String accessToken = storage.read('accessToken') ?? '';

    log("Register Id: $registerId");
    log("Access Token: $accessToken");

    try {
      final response = await http.post(
        url,
        headers: {
          'deviceId': 'qwert',
          'deviceName': 'sm2233',
          'accessStatus': '1',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({"registerId": registerId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final info = responseData['info'];
        log("User details: $info");

        storage.write('userId', info['userId']);
        storage.write('fullName', info['fullName']);
        storage.write('emailId', info['emailId']);
        storage.write('mobileNo', info['mobileNo']);
        storage.write('mobileNoEnc', info['mobileNoEnc']);
        storage.write('walletBalance', info['walletBalance']?.toString());
        storage.write('profilePicture', info['profilePicture']);
        storage.write('accountStatus', info['accountStatus']);
        storage.write('betStatus', info['betStatus']);

        log("✅ User details saved to GetStorage:");
        info.forEach((key, value) => log('$key: $value'));
      } else {
        print(
          "❌ Failed to fetch user details: ${response.statusCode} => ${response.body}",
        );
      }
    } catch (e) {
      print("❌ Exception fetching user details: $e");
    }
  }

  void _navigateToHome() {
    // Check if the widget is still mounted before navigating
    if (!mounted) return;

    storage.write('is_logged_in', true);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showSnackBar(String message) {
    // Check if the widget is still mounted before accessing context
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    mpinController.dispose();
    super.dispose();
  }

  /// Checks if the widget is still mounted (not disposed)
  bool get mounted {
    try {
      // Accessing context will throw if widget is disposed
      context;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/login.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Top Section with LOGIN text
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 25, top: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 100),
                      Center(
                        child: Image.asset(
                          'assets/images/lock.png',
                          width: 80,
                          height: 80,
                          color: const Color(0xFFFF2600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content - White Card
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    //  topRight: Radius.circular(50),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Image.asset(
                          "assets/images/logo2.png", // <-- अपने image path से replace करें
                          height: 170, // आप size बदल सकते हैं
                          width: 210,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // MPIN TextField
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: mpinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            cursorColor: const Color(0xFFFF3333),
                            textAlign:
                                TextAlign.center, // 🔥 Hint + Text दोनों Center

                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Login with mPIN",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 20,
                              ),
                              border: InputBorder.none,
                            ),
                          ),

                          // 🔥 यह आपकी ब्लैक लाइन है
                          Container(
                            height: 2,
                            color: Color(0xffFF2600),
                            // margin: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2600),
                            elevation: 2,
                            shadowColor: const Color(
                              0xFFFF3333,
                            ).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _loginWithMpin,
                          child: const Text(
                            "LOGIN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Forgot M-Pin
                      GestureDetector(
                        onTap: _onSetPinPressed,
                        child: const Text(
                          "Forgot M-Pin?",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            //    decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Biometric Section
                      // if (isBiometricAvailable) ...[
                      //   GestureDetector(
                      //     onTap: _tryBiometricAuth,
                      //     child: Container(
                      //       padding: const EdgeInsets.all(16),
                      //       decoration: BoxDecoration(
                      //         color: const Color(0xFFF5F5F5),
                      //         borderRadius: BorderRadius.circular(50),
                      //       ),
                      //       child: const Icon(
                      //         Icons.fingerprint,
                      //         size: 50,
                      //         color: Color(0xFFFF3333),
                      //       ),
                      //     ),
                      //   ),
                      //   const SizedBox(height: 12),
                      //   const Text(
                      //     "Use fingerprint to login",
                      //     style: TextStyle(
                      //       color: Color(0xFF666666),
                      //       fontSize: 14,
                      //     ),
                      //   ),
                      // ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
