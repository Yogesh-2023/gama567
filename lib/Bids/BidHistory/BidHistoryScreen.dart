// File: lib/Passbook/BidHistoryPage.dart (adjust path if different)
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../ulits/Constents.dart';
import '../../Helper/UserController.dart';
import '../../ulits/curved_appbar.dart';

class BidHistoryPage extends StatefulWidget {
  const BidHistoryPage({Key? key}) : super(key: key);
  @override
  State<BidHistoryPage> createState() => _BidHistoryPageState();
}

class _BidHistoryPageState extends State<BidHistoryPage> {
  List<BetHistoryEntry> entries = [];
  bool loading = false;

  // Default to today's data
  DateTime _selectedFromDate = DateTime.now();

  final UserController userController = Get.isRegistered<UserController>()
      ? Get.find<UserController>()
      : Get.put(UserController());

  @override
  void initState() {
    super.initState();
    fetchEntries();
  }

  Future<void> fetchEntries() async {
    setState(() => loading = true);

    final storage = GetStorage();
    final token = (storage.read("accessToken") ?? '').toString();
    final registerId = (storage.read("registerId") ?? '').toString();

    final url = Uri.parse('${Constant.apiEndpoint}bet-history');

    // Format yyyy-MM-dd
    final String formattedFromDate = DateFormat(
      'yyyy-MM-dd',
    ).format(_selectedFromDate);

    final body = {
      'registerId': registerId,
      'pageIndex': 1, // pagination removed
      'recordLimit': 10000, // pagination removed
      'placeType': 'game', // general game history
      'fromDate': formattedFromDate,
    };

    log("Fetching Bid History entries...");
    log("Register Id: $registerId");
    log("Access Token: ${token.isNotEmpty ? '*' : '(empty)'}");
    log("Request Body: ${jsonEncode(body)}");

    try {
      final res = await http.post(
        url,
        headers: <String, String>{
          'deviceId': 'qwert',
          'deviceName': 'sm2233',
          'accessStatus': '1',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      log("Response Status Code: ${res.statusCode}");
      log("Response Body: ${res.body}");

      if (res.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {
          debugPrint('Invalid JSON in response');
          setState(() => entries = []);
          return;
        }

        // Handle 'info' possibly being "" (empty string) from server
        final info =
            (data['info'] is String && (data['info'] as String).isEmpty)
            ? null
            : data['info'] as Map<String, dynamic>?;

        if (info != null) {
          final list = (info['list'] as List?) ?? [];
          setState(() {
            entries = list
                .map((e) => BetHistoryEntry.fromJson(e as Map<String, dynamic>))
                .toList();
          });
          log("Parsed Bid History entries count: ${entries.length}");
        } else {
          setState(() => entries = []);
          debugPrint('Info field is null or empty in API response');
        }
      } else {
        debugPrint('Error ${res.statusCode}: ${res.body}');
        setState(() => entries = []);
      }
    } catch (e) {
      debugPrint('Exception: $e');
      setState(() => entries = []);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF2600),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFFFF2600)),
            ),
          ),
          child: child,
        );
      },
    );
    if (picked != null && picked != _selectedFromDate) {
      setState(() => _selectedFromDate = picked);
      await fetchEntries(); // refresh for new date
    }
  }

  @override
  void dispose() {
    // Lock orientation to portrait as you had it (note: this affects the whole app until changed again)
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd-MM-yyyy').format(_selectedFromDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CurvedAppBar(title: "Bid History\n(From: $dateLabel)"),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF2600),
                      ),
                    )
                  : entries.isEmpty
                  ? const Center(
                      child: Text(
                        "No bid entries found.",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: entries.length,
                      itemBuilder: (context, index) =>
                          _buildPlayedMatchCard(entries[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayedMatchCard(BetHistoryEntry entry) {
    // If server already formats these, we show as-is.
    final formattedBidDate = entry.date;
    final formattedTransactionTime = entry.transactionTime;

    // Amount formatted with grouping, if numeric:
    String displayAmount = entry.amount;
    final num? parsedAmount = num.tryParse(entry.amount);
    if (parsedAmount != null) {
      displayAmount = NumberFormat.decimalPattern().format(parsedAmount);
    }

    final statusLower = entry.status.toLowerCase();
    final isPositive =
        statusLower.contains('good luck') ||
        statusLower.contains('win') ||
        statusLower.contains('best of luck');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      color: Colors.white,
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFF2600),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.gameName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.betType} (${entry.digit})',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
                // Right
                Text(
                  "Amount\n$displayAmount",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Card Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Dates/Times
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bid Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bid Date",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          formattedBidDate,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // Transaction Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Transaction Time",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          formattedTransactionTime,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bid ID
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bid ID",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        entry.bidId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.grey, thickness: 0.5),

                // Status
                Text(
                  entry.status,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (kept for future reuse)
  Widget _navButton(String label, bool enabled, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: enabled ? Color(0xFFFF2600) : Colors.grey,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Data model
class BetHistoryEntry {
  final String date; // "bidDate"
  final String gameName; // "title"
  final String betType; // "gameType"
  final String digit; // "selectedDigit"
  final String amount; // "bidAmount"
  final String transactionTime; // "bidTime"
  final String bidId; // "bidId"
  final String winAmount; // "winAmount"
  final String status; // "statusText"

  BetHistoryEntry({
    required this.date,
    required this.gameName,
    required this.betType,
    required this.digit,
    required this.amount,
    required this.transactionTime,
    required this.bidId,
    required this.winAmount,
    required this.status,
  });

  factory BetHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BetHistoryEntry(
      date: (json['bidDate'] ?? 'Unknown Date').toString(),
      gameName: (json['title'] ?? 'Unknown Game').toString(),
      betType: (json['gameType'] ?? 'N/A').toString(),
      digit: (json['selectedDigit'] ?? 'N/A').toString(),
      amount: (json['bidAmount'] ?? '0').toString(),
      transactionTime: (json['bidTime'] ?? 'Unknown Time').toString(),
      bidId: (json['bidId'] ?? 'N/A').toString(),
      winAmount: (json['winAmount'] ?? '0').toString(),
      status: (json['statusText'] ?? 'Pending').toString(),
    );
  }
}
