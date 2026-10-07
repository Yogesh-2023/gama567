import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../../BidService.dart';
import '../../Helper/UserController.dart';
import '../../components/AnimatedMessageBar.dart';
import '../../components/BidConfirmationDialog.dart';
import '../../components/BidFailureDialog.dart';
import '../../components/BidSuccessDialog.dart';
import '../../ulits/curved_appbar.dart';

class JodiBidScreen extends StatefulWidget {
  final String title;
  final String gameType;
  final int gameId;
  final String gameName;

  const JodiBidScreen({
    Key? key,
    required this.title,
    required this.gameType,
    required this.gameId,
    required this.gameName,
  }) : super(key: key);

  @override
  State<JodiBidScreen> createState() => _JodiBidScreenState();
}

class _JodiBidScreenState extends State<JodiBidScreen> {
  final TextEditingController digitController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  List<Map<String, String>> bids = [];
  late GetStorage storage;
  late BidService _bidService;

  late String accessToken;
  late String registerId;
  String walletBalance = '0'; // Changed to String
  bool accountStatus = false;
  bool _isSubmitting = false;

  final String _deviceId = 'test_device_id_flutter';
  final String _deviceName = 'test_device_name_flutter';

  String? _messageToShow;
  bool _isErrorForMessage = false;
  Key _messageBarKey = UniqueKey();
  final UserController userController = Get.put(UserController());

  final List<String> allJodiOptions = List.generate(
    100,
    (i) => i.toString().padLeft(2, '0'),
  );

  @override
  void initState() {
    super.initState();
    storage = GetStorage();
    _bidService = BidService(storage);
    // Initialize walletBalance from storage as String
    double _walletBalance = double.parse(userController.walletBalance.value);
    int _walletBalanceInt = _walletBalance.toInt();
    walletBalance = _walletBalanceInt.toString();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    accessToken = storage.read('accessToken') ?? '';
    registerId = storage.read('registerId') ?? '';
    accountStatus = userController.accountStatus.value;
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _messageToShow = msg;
      _isErrorForMessage = isError;
      _messageBarKey = UniqueKey();
    });
  }

  void _clearMessage() {
    if (mounted) setState(() => _messageToShow = null);
  }

  void _addBid() {
    _clearMessage();
    if (_isSubmitting) return;

    final jodi = digitController.text.trim();
    final amount = amountController.text.trim();

    if (jodi.length != 2 || int.tryParse(jodi) == null) {
      _showMessage('Please enter a valid 2-digit Jodi.', isError: true);
      return;
    }
    final amt = int.tryParse(amount);
    if (amt == null || amt < 10 || amt > 1000) {
      _showMessage('Amount must be between 10 and 1000.', isError: true);
      return;
    }
    if (bids.any((b) => b['digit'] == jodi)) {
      _showMessage('Jodi $jodi already exists.', isError: true);
      return;
    }

    setState(() {
      bids.add({'digit': jodi, 'amount': amount});
      digitController.clear();
      amountController.clear();
      _showMessage('Bid for Jodi $jodi added successfully!', isError: false);
    });
  }

  void _removeBid(int idx) {
    if (_isSubmitting) return;
    setState(() {
      final removed = bids[idx]['digit'];
      bids.removeAt(idx);
      _showMessage('Removed Jodi $removed.', isError: false);
    });
  }

  int _getTotalPoints() {
    return bids.fold(0, (sum, b) => sum + (int.tryParse(b['amount']!) ?? 0));
  }

  Future<void> _submitBidViaService(int total) async {
    setState(() => _isSubmitting = true);
    final bidMap = {for (var b in bids) b['digit']!: b['amount']!};

    final result = await _bidService.placeFinalBids(
      gameName: widget.gameName,
      accessToken: accessToken,
      registerId: registerId,
      deviceId: _deviceId,
      deviceName: _deviceName,
      accountStatus: accountStatus,
      bidAmounts: bidMap,
      selectedGameType: "OPEN",
      gameId: widget.gameId,
      gameType: widget.gameType,
      totalBidAmount: total,
    );

    if (result['status'] == true) {
      // Parse current walletBalance to int for calculation
      final currentWalletBalanceInt = int.tryParse(walletBalance) ?? 0;
      final newBalInt = currentWalletBalanceInt - total;
      await _bidService.updateWalletBalance(
        newBalInt,
      ); // update GetStorage with int
      setState(() {
        bids.clear();
        walletBalance = newBalInt
            .toString(); // Convert back to String for state
      });
      showDialog(context: context, builder: (_) => const BidSuccessDialog());
      _showMessage("Bid placed successfully!");
    } else {
      showDialog(
        context: context,
        builder: (_) =>
            BidFailureDialog(errorMessage: result['msg'] ?? "Error"),
      );
      _showMessage(result['msg'] ?? "Bid failed.", isError: true);
    }

    setState(() => _isSubmitting = false);
  }

  void _showConfirmationDialog(int total) {
    if (bids.isEmpty) {
      _showMessage('No bids added yet.', isError: true);
      return;
    }
    // Parse walletBalance to int for comparison
    if (total > (int.tryParse(walletBalance) ?? 0)) {
      _showMessage('Insufficient wallet balance.', isError: true);
      return;
    }

    final date = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    // No change here, walletBalance is already a String,
    // (int.tryParse(walletBalance) ?? 0) - total) is calculated as int then converted to string
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BidConfirmationDialog(
        gameTitle: "${widget.gameName}, ${widget.gameType}",
        gameDate: date,
        bids: bids,
        totalBids: bids.length,
        totalBidsAmount: total,
        walletBalanceBeforeDeduction:
            int.tryParse(walletBalance) ??
            0, // walletBalance, // Already a String
        walletBalanceAfterDeduction:
            ((int.tryParse(walletBalance) ?? 0) - total).toString(),
        gameId: widget.gameId.toString(),
        gameType: widget.gameType,
        onConfirm: () => _placeFinalBids(),
      ),
    );
  }

  Future<bool> _placeFinalBids() async {
    final result = await _bidService.placeFinalBids(
      gameName: widget.gameName,
      accessToken: accessToken,
      registerId: registerId,
      deviceId: _deviceId,
      deviceName: _deviceName,
      accountStatus: accountStatus,
      bidAmounts: _bidService.getBidAmounts(bids),
      selectedGameType: "OPEN",
      gameId: widget.gameId,
      gameType: widget.gameType,
      totalBidAmount: _getTotalPoints(),
    );

    if (!mounted) return false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => result['status']
            ? const BidSuccessDialog()
            : BidFailureDialog(errorMessage: result['msg']),
      );

      bids.clear();

      if (result['status'] && context.mounted) {
        // Parse current walletBalance to int for calculation
        final currentWalletBalanceInt = int.tryParse(walletBalance) ?? 0;
        final newBalanceInt = currentWalletBalanceInt - _getTotalPoints();
        setState(() {
          walletBalance = newBalanceInt
              .toString(); // Convert back to String for state
        });
        await _bidService.updateWalletBalance(
          newBalanceInt,
        ); // Update GetStorage with int
      }
    });

    return result['status'] == true;
  }

  @override
  void dispose() {
    digitController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _getTotalPoints();
    return Scaffold(
  //    backgroundColor: const Color(0xfff2f2f2),
      backgroundColor: Colors.white,
      appBar: CurvedAppBar(title: widget.title),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                   // vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputRow(
                        "Enter Jodi:",
                        _buildInputField(
                          controller: digitController,
                          hint: "Enter Jodi",
                          borderColor: Colors.grey,
                          selected: 'digit',
                        ),
                      ),
                      _inputRow(
                        "Enter Points:",
                        _buildInputField(
                          controller: amountController,
                          hint: "Enter Amount",
                          borderColor: Colors.grey,
                          selected: 'amount',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSubmitting
                                  ? Colors.grey
                                  : Color(0xffFF2600),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _addBid,
                            child: _isSubmitting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'ADD BID',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
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
                const Divider(),
                _buildTableHeader(),
                const Divider(),
                Expanded(
                  child: bids.isEmpty
                      ? Center(
                          child: Text(
                            'No bids yet. Add some data!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: bids.length,
                          itemBuilder: (_, idx) =>
                              _buildBidItem(bids[idx], idx),
                        ),
                ),
                if (bids.isNotEmpty) _buildBottomBar(),
              ],
            ),
            if (_messageToShow != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedMessageBar(
                  key: _messageBarKey,
                  message: _messageToShow!,
                  isError: _isErrorForMessage,
                  onDismissed: _clearMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required Color borderColor,
    required String selected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: selected == 'digit' ? 2 : 4,
        cursorColor: Color(0xFFFF2600),
        onTap: _clearMessage,
        decoration: InputDecoration(
          counterText: "",
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }


  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              'Digit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Points',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Game Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBidItem(Map<String, String> bid, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                bid['digit'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                bid['amount'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.gameType.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFFF2600)),
              onPressed: () => _removeBid(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = _getTotalPoints();
    final totalBids = bids.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bids',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '$totalBids',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Points',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '$total',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () => _showConfirmationDialog(total),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubmitting ? Colors.grey : Color(0xffFF2600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'SUBMIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
