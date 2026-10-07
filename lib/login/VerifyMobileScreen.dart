import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:new_sara/Helper/Toast.dart';
import 'package:new_sara/HomeScreen/HomeScreen.dart';
import 'package:new_sara/Login/LoginWithMpinScreen.dart';
import 'package:new_sara/ulits/ColorsR.dart';
import 'package:new_sara/ulits/Constents.dart';
import 'package:provider/provider.dart';

// -----------------------------
// MODEL
// -----------------------------
class AuthResponse {
  final bool status;
  final String msg;
  final AuthInfo? info;

  AuthResponse({required this.status, required this.msg, this.info});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] as bool,
      msg: json['msg'] as String,
      info: json.containsKey('info') && json['info'] != null
          ? AuthInfo.fromJson(json['info'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AuthInfo {
  final String? registerId;
  final String? accessToken;

  AuthInfo({this.registerId, this.accessToken});

  factory AuthInfo.fromJson(Map<String, dynamic> json) {
    return AuthInfo(
      registerId: json['registerId'] as String?,
      accessToken: json['accessToken'] as String?,
    );
  }
}

// -----------------------------
// API SERVICE
// -----------------------------
class ApiService {
  final Map<String, String> _baseHeaders = {
    'deviceId': 'qwert',
    'deviceName': 'sm2233',
    'accessStatus': '1',
    'Content-Type': 'application/json',
  };

  Future<AuthResponse> registerWithPassword({
    required String fullName,
    required String mobileNo,
    required String password,
    required String securityPin,
  }) async {
    final Uri url = Uri.parse('${Constant.apiEndpoint}user-register');
    final Map<String, dynamic> requestBody = {
      "fullName": fullName,
      "mobileNo": int.tryParse(mobileNo),
      "password": password,
      "password_confirmation": password,
      "security_pin": int.tryParse(securityPin),
    };

    try {
      final response = await http.post(
        url,
        headers: _baseHeaders,
        body: jsonEncode(requestBody),
      );

      log("📥 Register response: ${response.body}");
      final json = jsonDecode(response.body);
      return AuthResponse.fromJson(json);
    } catch (e) {
      log("❌ Register error: $e");
      return AuthResponse(status: false, msg: "Registration failed.");
    }
  }
}

// -----------------------------
// VIEWMODEL
// -----------------------------
class VerifyMobileViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final GetStorage _storage = GetStorage();

  final TextEditingController passwordController = TextEditingController();

  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;
  bool _registrationSuccessful = false;

  bool get isVerifying => _isVerifying;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get registrationSuccessful => _registrationSuccessful;

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  Future<void> verifyPassword() async {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      _errorMessage = "Enter a valid password.";
      notifyListeners();
      return;
    }

    final mobile = _storage.read('mobile');
    final name = _storage.read('username') ?? "User";
    final mpin = _storage.read('user_mpin');

    if (mobile == null || mpin == null) {
      _errorMessage = "Missing data. Please restart registration.";
      notifyListeners();
      return;
    }

    _isVerifying = true;
    notifyListeners();

    try {
      final AuthResponse response = await _apiService.registerWithPassword(
        fullName: name,
        mobileNo: mobile,
        password: password,
        securityPin: mpin,
      );

      if (response.status) {
        if (response.info?.accessToken != null &&
            response.info?.registerId != null) {
          _storage.write('accessToken', response.info?.accessToken);
          _storage.write('registerId', response.info?.registerId);
        }

        _successMessage = response.msg;
        _registrationSuccessful = true;
      } else {
        _errorMessage = response.msg;
      }
    } catch (e) {
      _errorMessage = "Error verifying password: ${e.toString()}";
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }
}

// -----------------------------
// VIEW (FINAL UPDATED UI)
// -----------------------------
class VerifyMobileScreen extends StatelessWidget {
  const VerifyMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VerifyMobileViewModel(),
      child: const _VerifyMobileScreenUI(),
    );
  }
}

class _VerifyMobileScreenUI extends StatefulWidget {
  const _VerifyMobileScreenUI();

  @override
  State<_VerifyMobileScreenUI> createState() => _VerifyMobileScreenUIState();
}

class _VerifyMobileScreenUIState extends State<_VerifyMobileScreenUI> {
  final GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<VerifyMobileViewModel>(context, listen: false);

      vm.addListener(() {
        if (!mounted) return;

        // ❌ Error
        if (vm.errorMessage != null) {
          popToast(vm.errorMessage!, 4, Colors.white, ColorsR.appColorRed);

          vm.clearErrorMessage();
        }

        // ✅ Success
        if (vm.successMessage != null) {
          popToast(vm.successMessage!, 2, Colors.white, Colors.green);

          if (vm.registrationSuccessful) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }

          vm.clearSuccessMessage();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<VerifyMobileViewModel>(context);
    final mobile = storage.read('mobile') ?? "XXXXXXXXXX";

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // 🔴 SAME THEME BACKGROUND
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/login.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: Stack(
          children: [
            // 🔺 TOP SECTION
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, top: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "VERIFY  YOUR  MOBILE NUMBER",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          //letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 100),
                      Center(
                        child: Image.asset(
                          "assets/images/verification_avatar.png",
                          height: 110,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ⚪ WHITE CURVE CONTAINER
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 35,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(50)),
                ),

                child: Column(
                  children: [
                    // const SizedBox(height: 20),
                    Text(
                      "Enter Password",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Enter your password to verify\nand complete registration",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      mobile,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🔲 Underline style PASSWORD input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: vm.passwordController,
                          obscureText: true,
                          cursorColor: Colors.red,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Password",
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Container(height: 2, color: Color(0xffFF2600)),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 🔘 VERIFY BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: vm.isVerifying ? null : vm.verifyPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffFF2600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: vm.isVerifying
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "VERIFY",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
