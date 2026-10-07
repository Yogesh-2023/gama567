import 'package:flutter/material.dart';
import '../widgets/top_curve_header.dart';
import '../widgets/bottom_nav.dart';
import 'aries_daily_screen.dart'; // ✅ IMPORT OK

class SelectSignScreen extends StatelessWidget {
  const SelectSignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4FF),

      // 🔻 Bottom Navigation
      bottomNavigationBar: const BottomNav(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // 🔺 Top Curve
            TopCurveHeader(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.black),
                    SizedBox(width: 6),
                    Text("Back", style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Select Your Sign",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // 🔮 Zodiac Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: signs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final item = signs[index];

                  return GestureDetector(
                    // ✅ ARIES NAVIGATION (FIXED)
                    onTap: () {
                      if (item['name'] == 'Aries') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AriesDailyScreen(), // ❌ const REMOVED
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.deepOrange,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            item['icon']!,
                            height: 36,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 36,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 🔻 Non Sign Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE53935), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Non Sign",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53935),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Name",
                      style: TextStyle(fontSize: 18, color: Color(0xFFF26A6A)),
                    ),
                    const SizedBox(height: 6),
                    _borderField(hint: "Enter Name"),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "DOB",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFF26A6A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _iconField(
                                text: "09-10-2025",
                                iconPath: "assets/random/icon_calendar.png",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TOB",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFF26A6A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _iconField(
                                text: "12:00 AM",
                                iconPath: "assets/random/icon_clock.png",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Birth Place",
                      style: TextStyle(fontSize: 18, color: Color(0xFFF26A6A)),
                    ),
                    const SizedBox(height: 6),
                    _borderField(hint: "Enter"),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          "Check",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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

//
// 🔧 HELPER WIDGETS
//

Widget _borderField({required String hint}) {
  return Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFB74D), width: 2),
    ),
    child: Text(
      hint,
      style: const TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
    ),
  );
}

Widget _iconField({required String text, required String iconPath}) {
  return Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFB74D), width: 2),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
          ),
        ),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              iconPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.calendar_month, color: Colors.white);
              },
            ),
          ),
        ),
      ],
    ),
  );
}

// 🔹 Zodiac Data
final List<Map<String, String>> signs = [
  {"name": "Aries", "icon": "assets/zodiac/aries.png"},
  {"name": "Taurus", "icon": "assets/zodiac/taurus.png"},
  {"name": "Gemini", "icon": "assets/zodiac/gemini.png"},
  {"name": "Cancer", "icon": "assets/zodiac/cancer.png"},
  {"name": "Leo", "icon": "assets/zodiac/leo.png"},
  {"name": "Virgo", "icon": "assets/zodiac/virgo.png"},
  {"name": "Libra", "icon": "assets/zodiac/libra.png"},
  {"name": "Scorpio", "icon": "assets/zodiac/scorpio.png"},
  {"name": "Sagittarius", "icon": "assets/zodiac/sagittarius.png"},
  {"name": "Capricorn", "icon": "assets/zodiac/capricorn.png"},
  {"name": "Aquarius", "icon": "assets/zodiac/aquarius.png"},
  {"name": "Pisces", "icon": "assets/zodiac/pisces.png"},
];