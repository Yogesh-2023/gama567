import 'package:flutter/material.dart';
import 'package:new_sara/Bids/BidHistory/BidHistoryScreen.dart' hide Colors;
import 'package:new_sara/Bids/KingJackpotBidHis/KingJackpotHistoryScreen.dart';
import 'package:new_sara/Bids/KingStartlineBidHis/KingStarlineBidHistoryScreen.dart';
import 'package:new_sara/ulits/curved_appbar.dart';

class BidScreen extends StatelessWidget {
  final List<_BidOption> bidOptions = [
    _BidOption(
      "BID HISTORY",
      "assets/icons/auction.png",
      const Color(0xffE9DCF8), // Card background
      const Color(0xFF8011D2), // Image color
      const Color(0x338011D2), // Circle background
    ),

    _BidOption(
      "KING STARLINE BID HISTORY",
      "assets/icons/bank.png",
      const Color(0xffDBE8FB),
      const Color(0xff0A52CB),
      const Color(0xFF689EFE),
    ),

    _BidOption(
      "KING JACKPOT BID HISTORY",
      "assets/icons/poker-game.png",
      const Color(0xffD9EEF1),
      Colors.teal,
      const Color(0xFF75F0f8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CurvedAppBar(title: "My Bids"),
      body: Padding(
        padding: const EdgeInsets.only(top: 25),
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          itemCount: bidOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 0.87,
          ),
          itemBuilder: (context, index) {
            final item = bidOptions[index];

            return GestureDetector(
              onTap: () {
                if (item.title == "BID HISTORY") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BidHistoryPage()),
                  );
                } else if (item.title == "KING STARLINE BID HISTORY") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => KingStarlineBidHistoryScreen()),
                  );
                } else if (item.title == "KING JACKPOT BID HISTORY") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => KingJackpotHistoryScreen()),
                  );
                }
              },

              child: Container(
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // -----------------------------
                    //     TOP IMAGE ICON CIRCLE
                    // -----------------------------
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: item.circleColor, // ✔ Different circle color
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        item.imagePath,
                        width: 38,
                        height: 38,
                        color: item.iconColor, // ✔ Different image color
                      ),
                    ),

                    const SizedBox(height: 18),

                    // TITLE
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // BOTTOM COLOR BAR
                    Container(
                      width: 55,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.iconColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------
// UPDATED MODEL CLASS
// -----------------------------------
class _BidOption {
  final String title;
  final String imagePath;
  final Color bgColor;
  final Color iconColor;
  final Color circleColor;

  _BidOption(
      this.title,
      this.imagePath,
      this.bgColor,
      this.iconColor,
      this.circleColor
      );
}
