
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void closeBidDialogue1({
  required BuildContext context,
  required String gameName,
  required String openResultTime,
  required String openBidLastTime,
  required String closeResultTime,
  required String closeBidLastTime,
  bool isBettingClosed = true, // Add parameter to control warning message
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, __, ___) {
      return Material(

        color: Colors.black54,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ----------- GAME NAME TITLE ----------
                Text(
                  gameName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xffFF2600),
                  ),
                ),

                const SizedBox(height: 4),

                // ------------ DAY (OPTIONAL) -----------
                Text(
                  DateFormat('dd MMM, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                // --------- Status Text (conditional) ----------
                if (isBettingClosed) ...[
                  const Text(
                    "Betting is Closed for Today",
                    style: TextStyle(
                      fontSize: 16,
                      color:Color(0xffFF2600),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  const Text(
                    "Betting is Running",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4CAF50), // Green color for running status
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ------------- TWO BOXES --------------
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeCard(
                        title: "Open",
                        resultTime: openResultTime,
                        lastTime: openBidLastTime,
                        resultLabel: "Open Result Time",
                        bidLabel: "Open Bid Last Time",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTimeCard(
                        title: "Close",
                        resultTime: closeResultTime,
                        lastTime: closeBidLastTime,
                        resultLabel: "Close Result Time",
                        bidLabel: "Close Bid Last Time",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // ------------------- OK BUTTON -------------------
                SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF2600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 18,
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
      );
    },
  );
}

Widget _buildTimeCard({
  required String title,
  required String resultTime,
  required String lastTime,
  String resultLabel = "Result Time", // Add custom label for result time
  String bidLabel = "Bid Last Time", // Add custom label for bid time
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.red.shade300, width: 1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xffFF2600),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        Text(resultLabel,
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          resultTime,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(height: 10),

        Text(bidLabel,
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          lastTime,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ],
    ),
  );
}
