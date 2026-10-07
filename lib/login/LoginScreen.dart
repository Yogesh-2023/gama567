import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../ulits/ColorsR.dart';
import '../../../Components/showAccountRecoveryDialog.dart';
import '../../../Helper/Toast.dart';
import '../ulits/Constents.dart';
import 'CreateAccountScreen.dart';

class EnterMobileScreen extends StatefulWidget {
  const EnterMobileScreen({super.key});

  @override
  State<EnterMobileScreen> createState() => _EnterMobileScreenState();
}

class _EnterMobileScreenState extends State<EnterMobileScreen> {
  final TextEditingController mobileController = TextEditingController();
  final storage = GetStorage();

  bool isLoading = false;

  String? validateMobile(String mobile) {
    if (mobile.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  Future<void> _handleNextPressed() async {
    final mobile = mobileController.text.trim();
    final validation = validateMobile(mobile);

    if (validation != null) {
      popToast(validation, 4, Colors.white, ColorsR.appColorRed);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('${Constant.apiEndpoint}check-mobile'),
            headers: {
              'deviceId': 'qwert',
              'deviceName': 'sm2233',
              'accessStatus': '1',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({"mobileNo": int.tryParse(mobile)}),
          )
          .timeout(const Duration(seconds: 10));

      final statusCode = response.statusCode;

      if (statusCode == 200) {
        final data = jsonDecode(response.body);
        final statusRaw = data['status'];
        final bool status = statusRaw.toString().toLowerCase() == "true";

        storage.write('mobile', mobile);

        if (status) {
          showAccountRecoveryDialog(context, mobile);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
          );
        }
      } else {
        popToast(
          "Server Error: $statusCode",
          4,
          Colors.white,
          ColorsR.appColorRed,
        );
      }
    } on TimeoutException {
      popToast(
        "Request timed out. Please check your internet connection.",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
    } catch (e) {
      popToast(
        "Something went wrong. Please try again.",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
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

        // 🔴 SAME BACKGROUND AS LoginWithMPIN
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/login.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: Stack(
          children: [
            // 🔺 TOP TEXT (LOGIN की तरह)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 23, top: 38),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Your Mobile Number',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          // letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 100),

                      // Center Mobile Icon (same opacity style)
                    ],
                  ),
                ),
              ),
            ),

            // ⚪ WHITE CURVED MAIN CARD (same as login mpin)
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(50)),
                ),

                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 60,
                  ),
                  child: Column(
                    children: [
                      // APP LOGO (same placement as mpin)
                      Center(
                        child: Image.asset(
                          'assets/images/phone2.png',
                          height: 68,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 🔲 TEXTFIELD WITH SAME STYLE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0),
                            child: Row(
                              children: [
                                // 📱 Left Side Small Mobile Icon
                                SvgPicture.asset(
                                  "assets/icons/phone.svg",
                                  fit: BoxFit.contain,
                                  height: 36,
                                  width: 36,
                                ),

                                const SizedBox(width: 10),

                                // 🔤 TextField LEFT aligned
                                Expanded(
                                  child: TextField(
                                    controller: mobileController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    textAlign: TextAlign.left, // ← LEFT ALIGN
                                    cursorColor: Color(0xFFFF2600),

                                    decoration: const InputDecoration(
                                      counterText: "",
                                      hintText:
                                          "Enter Your Mobile Number", // ← LEFT HINT
                                      hintStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15.5,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 🔻 Red Line Below (Same Style)
                          Container(
                            height: 2,
                            color: Color(0xffFF2600),
                            margin: const EdgeInsets.only(left: 14, right: 0),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 🔘 SAME RED BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleNextPressed,
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
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Next",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
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
