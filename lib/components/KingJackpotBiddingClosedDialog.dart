import 'package:flutter/material.dart';

class KingJackpotBiddingClosedDialog extends StatelessWidget {
  final String time;
  final String resultTime;
  final String bidLastTime;

  const KingJackpotBiddingClosedDialog({
    super.key,
    required this.time,
    required this.resultTime,
    required this.bidLastTime,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero, // 🔥 पूरी screen पर फैल जाएगा
      backgroundColor: Colors.transparent, // ताकि white card दिखे
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95, // 🔥 90% SCREEN WIDTH

        //  padding: const EdgeInsets.all(10),
        child: AlertDialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.zero, // width limit बंद
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.shade50,
                radius: 30,
                child: const Icon(Icons.close, size: 40, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                "Bidding Is Closed For Today",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 16),

              // GREY CONTAINER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoRow("Open Result Time :", resultTime),
                    const SizedBox(height: 10),
                    _infoRow("Open Bid Last Time :", bidLastTime),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
