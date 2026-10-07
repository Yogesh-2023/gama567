import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:new_sara/Bids/KingJackpotResultHis/KingJackpotResultScreen.dart';
import '../Bids/KingStarlineResultHis/KingStarlineResultHis.dart'
    show KingStarlineResultScreen;

class CurvedAppBar2 extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;

  CurvedAppBar2({super.key, required this.title, this.onBack});

  // Removed GetX controller since we're not using GetMaterialApp

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // नीचे के लिए SafeArea ना चाहिए
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFFFF3A20),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(23),
            bottomRight: Radius.circular(23),
          ),
        ),
        padding: const EdgeInsets.only(top: 5, left: 15, right: 15),
        child: Row(
          children: [
            // Back Button
            GestureDetector(
              onTap: onBack ?? () => Navigator.pop(context),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(width: 10),

            // ⭐ Title with ellipsis, will shrink automatically
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ⭐ Wallet ALWAYS visible
            // Replace wallet section with View History
            GestureDetector(
              onTap: () {
                // 👉 Yaha apna navigation ya bottom sheet code likh sakte hain
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KingJackpotResultScreen(),
                  ),
                );
              },
              child: Row(
                children: const [
                  Icon(Icons.history, size: 20, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    "View History",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
