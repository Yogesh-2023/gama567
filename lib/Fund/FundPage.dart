import 'package:flutter/material.dart';
import 'package:new_sara/Fund/BankDetailsFragment.dart';

import '../Helper/TranslationHelper.dart';
import '../ulits/curved_appbar.dart';
import 'AddFundScreen.dart';
import 'DepositHistoryPage.dart';
import 'WithdrawScreen.dart';
import 'WithdrawalHistoryPage.dart';

class FundsScreen extends StatelessWidget {
  final void Function(String title)? onItemTap;
  final TranslationHelper translationHelper = TranslationHelper();

  FundsScreen({super.key, this.onItemTap});

  final List<_FundOption> fundOptions = [
    _FundOption(
      "Add Funds",
      "assets/icons/plus.png",
      Color(0xFFF4D8D0),
      Color(0xFFFF2600),
      Color(0xFFF3C2A4),
    ),
    _FundOption(
      "Manual Deposit Requests",
      "assets/icons/wall-clock.png",
      Color(0xFFF5D6C9),
      Colors.deepOrange,
      Color(0xFFF3C2A4),
    ),
    _FundOption(
      "Withdraw History",
      "assets/icons/his.png",
      Color(0xFFE7D7F6),
      Colors.deepPurple,
      Color(0xFFF2E6FC),
    ),
    _FundOption(
      "Add Bank Details",
      "assets/icons/bank.png",
      Color(0xFFD3F3F4),
      Colors.teal,
      Color(0xFF75F0F8),
    ),
    _FundOption(
      "Withdraw Funds",
      "assets/icons/witfund.png",
      Color(0xFFDDEAFF),
      Color(0xff1f44B3),
      Color(0xFF689EE),
    ),
    _FundOption(
      "Account Statement",
      "assets/icons/funhiss.png",
      Color(0xFFE5F8D4),
      Color(0xff198E34),
      Color(0xFFA7FD82),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CurvedAppBar(title: 'Funds'),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: GridView.builder(
          itemCount: fundOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final item = fundOptions[index];

            return GestureDetector(
              onTap: () {
                switch (item.title) {
                  case "Add Funds":
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddFundScreen()),
                    );
                    break;

                  case "Manual Deposit Requests":
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DepositHistoryPage()),
                    );
                    break;

                  case "Withdraw History":
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WithdrawalHistoryPage(),
                      ),
                    );
                    break;

                  case "Add Bank Details":
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BankDetailsFragment()),
                    );
                    break;

                  case "Withdraw Funds":
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WithdrawScreen()),
                    );
                    break;

                  case "Account Statement":
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DepositHistoryPage()),
                    );
                    break;
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 2),

                    // ⭐ CUSTOM IMAGE ICON
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: item.circleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        item.iconPath,
                        width: 36,
                        height: 36,
                        color: item.iconColor, // colored icon
                      ),
                    ),

                    // TITLE TEXT
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      child: Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // BOTTOM COLORED BAR
                    Container(
                      width: 60,
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

class _FundOption {
  final String title;
  final String iconPath; // CUSTOM IMAGE
  final Color bgColor;
  final Color iconColor;
  final Color circleColor;

  _FundOption(
      this.title,
      this.iconPath,
      this.bgColor,
      this.iconColor,
      this.circleColor,
      );
}
