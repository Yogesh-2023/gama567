import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_sara/SetMPIN/SetPinScreen.dart';
import '../../../../ulits/ColorsR.dart';
import '../../../Helper/Toast.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final storage = GetStorage();

  String mobile = '';

  @override
  void initState() {
    super.initState();
    mobile = storage.read('mobile') ?? '';
  }

  void _onNextPressed() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty) {
      popToast(
        "Please enter your username",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
      return;
    }
    if (password.isEmpty) {
      popToast(
        "Please enter your password",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
      return;
    }
    if (password.length < 6) {
      popToast(
        "Password must be at least 6 characters",
        4,
        Colors.white,
        ColorsR.appColorRed,
      );
      return;
    }
    if (password != confirmPassword) {
      popToast("Passwords do not match", 4, Colors.white, ColorsR.appColorRed);
      return;
    }

    storage.write('username', username);
    storage.write('password', password);
    storage.write('mobile', mobile);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SetPinScreen()),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 👈 Keyboard Hide
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.infinity,
          height: double.infinity,

          // 🔴 SAME BACKGROUND IMAGE AS OTHER SCREENS
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/login.png"),
              fit: BoxFit.cover,
            ),
          ),

          child: Stack(
            children: [
              // 🔺 TOP HEADING (WHITE TEXT)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, top: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New  Account',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            // letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 100),

                        Center(
                          child: Icon(
                            Icons.person_add_alt_1,
                            color: Colors.white.withOpacity(0.3),
                            size: 110,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ⚪ WHITE MAIN CURVED CARD
              Positioned(
                top: 190,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                    ),
                  ),

                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 50,
                    ),
                    child: Column(
                      children: [
                        // USERNAME FIELD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Username"),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _usernameController,
                              cursorColor: Color(0xFFFF2600),
                              decoration: const InputDecoration(
                                hintText: "Enter username",
                                border: InputBorder.none,
                              ),
                            ),
                            Container(
                              height: 1.5,
                              color: Color(0xffFF2600),
                              //  margin: const EdgeInsets.symmetric(horizontal: 0),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // PASSWORD FIELD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Password"),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _passwordController,
                              cursorColor: Color(0xFFFF2600),
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: "Enter password",
                                border: InputBorder.none,
                              ),
                            ),
                            Container(
                              height: 1.5,
                              color: Color(0xFFFF2600),
                              // margin: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // CONFIRM PASSWORD FIELD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Confirm Password"),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _confirmPasswordController,
                              cursorColor: Color(0xFFFF2600),
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: "Enter password",
                                border: InputBorder.none,
                              ),
                            ),
                            Container(
                              height: 1.5,
                              color: Color(0xffFF2600),
                              //  margin: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // RED BUTTON (SAME AS OTHER SCREENS)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _onNextPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF2600),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              "NEXT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
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
      ),
    );
  }
}
