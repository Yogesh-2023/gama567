import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../HomeScreen/HomeScreen.dart';
import '../ulits/Constents.dart';
import '../Helper/UserController.dart';
import '../ulits/curved_appbar.dart';

class PassbookPage extends StatefulWidget {
  const PassbookPage({Key? key}) : super(key: key);
  @override
  State<PassbookPage> createState() => _PassbookPageState();
}

class _PassbookPageState extends State<PassbookPage> {
  int pageIndex = 1;
  final int recordLimit = 20; // Updated recordLimit to match API request
  List<PassbookEntry> entries = [];
  bool isLandscape = false;
  bool loading = false;
  int _totalPages = 1; // New state variable for total pages
  GetStorage storage = GetStorage();
  String deviceId = '';
  String deviceName = '';
  String registerId = '';
  late String token = '';
  final url = '${Constant.apiEndpoint}passbook-history';

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
    // Corrected API URL to match the domain used in other API calls
    token = storage.read("accessToken") ?? '';
    registerId = storage.read("registerId") ?? ''; // New static registerId
    deviceId = storage.read('deviceId') ?? '';
    deviceName = storage.read('deviceName') ?? '';

    log("Fetching Passbook entries...");
    log("Register Id: $registerId");
    log("Access Token: $token"); // Log the access token being used

    final requestBody = jsonEncode({
      'registerId': registerId,
      'pageIndex': pageIndex,
      'recordLimit': recordLimit,
    });

    log("Request Body: $requestBody"); // Log the request body

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'deviceId': deviceId,
          'deviceName': deviceName,
          'accessStatus': '1',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      log("Response Status Code: ${res.statusCode}");
      log("Response Body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final info = data['info'] as Map<String, dynamic>?;

        if (info != null) {
          final list = info['list'] as List<dynamic>? ?? [];
          final totalPages = info['totalPages'] as int? ?? 1;

          setState(() {
            entries = list.map((e) => PassbookEntry.fromJson(e)).toList();
            _totalPages = totalPages;
          });
          log(
            "Parsed entries count: ${entries.length}",
          ); // Log parsed entries count
        } else {
          setState(() {
            entries = [];
            _totalPages = 1;
          });
          debugPrint('Info field is null in API response');
        }
      } else {
        debugPrint('Error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('Exception: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _toggleOrientation() {
    isLandscape = !isLandscape;
    SystemChrome.setPreferredOrientations(
      isLandscape
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    setState(() {});
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CurvedAppBar(
        title: "Passbook",
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF2600)
),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildHeader(),
                            if (entries.isEmpty)
                              Container(
                                width: isLandscape
                                    ? 900
                                    : MediaQuery.of(context)
                                          .size
                                          .width, // Adjust width for landscape
                                height: 100,
                                alignment: Alignment.center,
                                color: Colors.white,
                                child: const Text("No entries found."),
                              )
                            else
                              ...entries.map((e) => _buildRow(e)),
                          ],
                        ),
                      ),
                    ),
            ),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Color(0xffFF2600),
      child: Row(
        children: const [
          _HeaderCell("Date & Time", width: 150),
          _HeaderCell("Description", width: 250), // Changed to "Description"
          _HeaderCell("Prev Amt", width: 150), // Shortened for space
          _HeaderCell("Txn Amt", width: 150), // Shortened for space
          _HeaderCell("Cur Amt", width: 150), // Shortened for space
          // Removed "Remark" column
        ],
      ),
    );
  }

  Widget _buildRow(PassbookEntry e) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _DataCell("${e.date}\n${e.time}", width: 150),
          // Use e.time
          _DataCell(e.description, width: 250), // Use e.description
          _DataCell("₹ ${e.previousAmount}", width: 150),
          _DataCell(
            "${e.type == 'credit' ? '₹' : '₹'}${e.transactionAmount}", // Use e.type for sign
            width: 150,
            isCredit: e.isCredit,
          ),
          _DataCell("₹${e.currentAmount}", width: 150),
          // Removed _DataCell for remark
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _navButton("PREVIOUS", pageIndex > 1, () {
            setState(() {
              pageIndex--;
            });
            fetchEntries();
          }),
          const SizedBox(width: 10),
          TextButton(
            onPressed: null,
            child: Text(
              "($pageIndex/$_totalPages)", // Use _totalPages
            ),
          ),
          const SizedBox(width: 10),
          _navButton("NEXT", pageIndex < _totalPages, () {
            // Enable NEXT if current page < total pages
            setState(() {
              pageIndex++;
            });
            fetchEntries();
          }),
        ],
      ),
    );
  }

  Widget _navButton(String label, bool enabled, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: enabled ? Color(0xffFF2600) : Color(0xffFF2600),
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

// Updated PassbookEntry class to match new API response
class PassbookEntry {
  final String date;
  final String time;
  final String description;
  final String previousAmount;
  final String transactionAmount;
  final String currentAmount;
  final String type; // "credit" or "debit"

  PassbookEntry.fromJson(Map<String, dynamic> json)
    : date = json['date'] ?? '',
      time = json['time'] ?? '',
      description = json['description'] ?? '',
      previousAmount = json['previousAmount']?.toString() ?? '',
      transactionAmount = json['transactionAmount']?.toString() ?? '',
      currentAmount = json['currentAmount']?.toString() ?? '',
      type = json['type'] ?? '';

  // Helper to determine if it's a credit transaction
  bool get isCredit => type.toLowerCase() == 'credit';
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  const _HeaderCell(this.text, {required this.width});
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(10),
    decoration: const BoxDecoration(
      border: Border(right: BorderSide(color: Colors.white, width: 1)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    ),
  );
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool isCredit;
  final double width;

  const _DataCell(this.text, {this.isCredit = false, required this.width});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 55,
    padding: const EdgeInsets.all(10),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: Colors.grey)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              height: 1.2,
              color: isCredit ? Colors.green : Colors.black,
            ),
          ),
        ),
      ],
    ),
  );
}
