import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../Helper/Toast.dart';
import '../ulits/ColorsR.dart';
import '../ulits/Constents.dart';
import 'package:new_sara/HomeScreen/HomeScreen.dart';

class SetNewPinScreen extends StatefulWidget {
  final String mobile;
  const SetNewPinScreen({super.key, required this.mobile});

  @override
  State<SetNewPinScreen> createState() => _SetNewPinScreenState();
}

class _SetNewPinScreenState extends State<SetNewPinScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final storage = GetStorage();
  late final String fcmToken;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fcmToken = storage.read('fcmToken') ?? '';
    log("FCM Token: $fcmToken");
  }

  Future<void> setNewPin() async {
    final mobile = widget.mobile;
    final password = passwordController.text.trim();
    final newPin = pinController.text.trim();

    if (password.isEmpty) {
      popToast(
        "Please enter your password",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
      return;
    }

    if (newPin.isEmpty || newPin.length != 4) {
      popToast(
        "Please enter a 4-digit PIN",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
      return;
    }

    setState(() => isLoading = true);

    final body = {
      "mobileNo": int.tryParse(mobile),
      "password": password,
      "security_pin": int.tryParse(newPin),
      "fcmToken": fcmToken,
    };

    try {
      final response = await http.post(
        Uri.parse('${Constant.apiEndpoint}reset-mpin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);
      final status = json['status'] ?? false;
      final msg = json['msg'] ?? "Something went wrong";

      if (status == true) {
        final info = json['info'];
        storage.write('user_mpin', newPin);
        storage.write('registerId', info['registerId']);
        storage.write('accessToken', info['accessToken']);

        popToast(msg, 2, Colors.white, Colors.green);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        popToast(msg, 4, Colors.white, ColorsR.appColorRed);
      }
    } catch (e) {
      popToast("❌ Error: $e", 4, Colors.white, ColorsR.appColorRed);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // 🔴 SAME BACKGROUND IMAGE
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/login.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: Stack(
          children: [
            // 🔺 TOP SET NEW PIN TEXT (like LOGIN text)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 32, top: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SET NEW PIN',
                        style: GoogleFonts.poppins(
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

            // ⚪ WHITE CURVED MAIN CARD (same as mpin screen)
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              bottom: 0,

              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
                ),

                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔤 Enter Password Label
                      const Text(
                        "Enter Password",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // PASSWORD FIELD (same underline design)
                      Column(
                        children: [
                          TextField(
                            controller: passwordController,
                            cursorColor: Color(0xFFFF2600),
                            obscureText: true,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              hintText: "Enter your password",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Container(
                            height: 2.5,
                            color: Colors.black,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Enter New mPIN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // NEW PIN FIELD (same underline)
                      Column(
                        children: [
                          TextField(
                            controller: pinController,
                            cursorColor: Color(0xFFFF2600),
                            obscureText: true,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              counterText: "",
                              hintText: "Enter 4 digit PIN",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Container(
                            height: 2.5,
                            color: Colors.black,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 🔘 SET PIN BUTTON (same design as LOGIN)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : setNewPin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF2600),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "SET PIN",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
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
