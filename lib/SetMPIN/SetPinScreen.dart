import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:new_sara/login/VerifyMobileScreen.dart';

import '../../../ulits/ColorsR.dart';
import '../../Helper/Toast.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final TextEditingController mpinController = TextEditingController();
  final storage = GetStorage();
  bool isLoading = false;

  void _onSetPinPressed() async {
    final pin = mpinController.text.trim();

    if (pin.isEmpty || pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      popToast("Please enter a valid 4-digit PIN", 4, Colors.white, ColorsR.appColorRed);
      return;
    }

    final mobile = storage.read('mobile');
    if (mobile == null || mobile.toString().isEmpty) {
      popToast("Mobile number not found", 4, Colors.white, ColorsR.appColorRed);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Save PIN temporarily
      storage.write('user_mpin', pin);

      Future.delayed(const Duration(milliseconds: 400), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerifyMobileScreen()),
        );
      });
    } catch (e) {
      popToast("Something went wrong: $e", 4, Colors.white, ColorsR.appColorRed);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    mpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // 🔴 SAME BACKGROUND as all your login screens
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/login.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: Stack(
          children: [
            // 🔺 TOP HEADING (White)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 25, top: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SET YOUR PIN",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          //letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 100),

                      // Center Icon with opacity
                      Center(
                        child: Image.asset(
                          "assets/images/set_mpin_avatar.png",
                          height: 110,
                          width: 110,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ⚪ WHITE CURVED MAIN AREA
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              bottom: 0,

              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                  ),
                ),

                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // const Text(
                      //   "Enter New mPin",
                      //   style: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.w600,
                      //     color: Colors.black87,
                      //   ),
                      // ),

                      const SizedBox(height: 40),

                      // 🔲 PIN TEXTFIELD (Underline Style)
                      Column(
                        children: [
                          TextField(
                            controller: mpinController,
                            cursorColor: Color(0xFFFF2600),
                            obscureText: true,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              counterText: "",
                              hintText: "Enter 4 digit PIN",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            height: 2,
                            color: Color(0xffFf2600),
                           // margin: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 🔘 BUTTON (Same as all others)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onSetPinPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF2600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 3,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            "SET PIN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
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
