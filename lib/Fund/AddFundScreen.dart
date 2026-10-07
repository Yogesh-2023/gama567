import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter_pay_upi/flutter_pay_upi_manager.dart';
import 'package:flutter_pay_upi/model/upi_app_model.dart';
import 'package:flutter_pay_upi/model/upi_response.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:new_sara/Fund/QRPaymentScreen.dart';
import 'package:new_sara/ulits/Constents.dart';

import '../Helper/TranslationHelper.dart';
import '../Helper/UserController.dart';
import '../ulits/curved_appbar.dart';

class CreateTransactionLinkResponse {
  final String msg;
  final bool status;
  final String? paymentLink;

  CreateTransactionLinkResponse({
    required this.msg,
    required this.status,
    this.paymentLink,
  });

  factory CreateTransactionLinkResponse.fromJson(Map<String, dynamic> json) {
    return CreateTransactionLinkResponse(
      msg: (json['msg'] ?? '').toString(),
      status: json['status'] == true,
      paymentLink: json['payment_link']?.toString(),
    );
  }
}

class AddFundScreen extends StatefulWidget {
  const AddFundScreen({super.key});
  @override
  State<AddFundScreen> createState() => _AddFundScreenState();
}

class _AddFundScreenState extends State<AddFundScreen>
    with WidgetsBindingObserver {
  final UserController userController = Get.find<UserController>();

  final TextEditingController amountController = TextEditingController();
  final Random _random = Random();
  final Map<String, String> _translationCache = {};
  final String currentLangCode =
  (GetStorage().read('language') ?? 'en').toString();

  final String _apiBaseUrl = Constant.apiEndpoint;

  String _upiPayeeVPA = '';
  String _upiPayeeName = '';
  late bool QRShow;
  late bool UPIShow;
  static const String _merchantCode = "";

  bool _isProcessingPayment = false;
  int _currentTransactionAmount = 0;
  String _currentTransactionId = '';
  String _currentPaymentMethodType = '';

  List<UpiApp> _apps = [];
  Timer? _walletTimer;
  Worker? _qrWorker;
  Worker? _upiWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    userController.fetchAndUpdateUserDetails();
    userController.fetchAndUpdateFeeSettings();

    QRShow = userController.qrStatus.value;
    UPIShow = userController.upiStatus.value;

    _qrWorker = ever<bool>(userController.qrStatus, (v) {
      if (mounted) setState(() => QRShow = v);
    });
    _upiWorker = ever<bool>(userController.upiStatus, (v) {
      if (mounted) setState(() => UPIShow = v);
    });

    validateAndAssignUPIorMobile();
    _upiPayeeName = userController.accountHolderName.value;
    _fetchUpiApps();
    _startWalletAutoRefresh();
  }

  @override
  void dispose() {
    amountController.dispose();
    _stopWalletAutoRefresh();
    _qrWorker?.dispose();
    _upiWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      userController.fetchAndUpdateUserDetails();
      _startWalletAutoRefresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopWalletAutoRefresh();
    }
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _startWalletAutoRefresh({Duration interval = const Duration(seconds: 3)}) {
    _walletTimer?.cancel();
    _walletTimer = Timer.periodic(interval, (_) async {
      await userController.fetchAndUpdateUserDetails();
    });
  }

  void _stopWalletAutoRefresh() {
    _walletTimer?.cancel();
    _walletTimer = null;
  }

  String _url(String path) {
    final base = _apiBaseUrl.endsWith('/') ? _apiBaseUrl : '$_apiBaseUrl/';
    final p = path.startsWith('/') ? path.substring(1) : path;
    return '$base$p';
  }

  Future<String> _t(String text) async {
    if (_translationCache.containsKey(text)) return _translationCache[text]!;
    final t = await TranslationHelper.translate(text, currentLangCode);
    if (mounted) _translationCache[text] = t;
    return t;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, String> _buildHeaders() {
    final deviceId = (GetStorage().read('deviceId') ?? '').toString();
    final deviceName = (GetStorage().read('deviceName') ?? '').toString();
    final accessTok = userController.accessToken.value.toString();
    return {
      'Authorization': 'Bearer $accessTok',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'deviceId': deviceId,
      'deviceName': deviceName,
      'accessStatus': '1',
    };
  }

  String _mapDepositType(String appName) {
    final name = appName.toLowerCase();
    if (name.contains('google') || name.contains('gpay')) return 'googlePay';
    if (name.contains('phonepe')) return 'phonePe';
    if (name.contains('paytm')) return 'paytm';
    return 'bank';
  }

  Future<Map<String, dynamic>> _postJsonSafe(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse(_url(path));
    final res = await http.post(uri,
        headers: _buildHeaders(), body: json.encode(body));

    Map<String, dynamic> out;
    try {
      final decoded = json.decode(res.body);
      out = decoded is Map<String, dynamic>
          ? decoded
          : {'status': false, 'msg': 'Invalid response format'};
    } catch (_) {
      out = {'status': false, 'msg': res.body.trim()};
    }
    out['_statusCode'] = res.statusCode;
    return out;
  }

  void _fetchUpiApps() async {
    try {
      final apps = await FlutterPayUpiManager.getListOfAndroidUpiApps();
      if (mounted) setState(() => _apps = apps);
    } catch (e) {
      log('Failed to load UPI apps: $e');
    }
  }

  void validateAndAssignUPIorMobile() {
    final gpayUpiId = userController.gpayUpiId.value;
    final phonepeUpiId = userController.phonepeUpiId.value;
    final paytmUpiId = userController.paytmUpiId.value;

    if (gpayUpiId.isNotEmpty && validateUpiId(gpayUpiId) == null) {
      _upiPayeeVPA = gpayUpiId;
    } else if (phonepeUpiId.isNotEmpty &&
        validateUpiId(phonepeUpiId) == null) {
      _upiPayeeVPA = phonepeUpiId;
    } else if (paytmUpiId.isNotEmpty && validateUpiId(paytmUpiId) == null) {
      _upiPayeeVPA = paytmUpiId;
    }

    if (_upiPayeeVPA.isEmpty) {
      _showSnackBar('UPI payee details not configured.');
    }
  }

  String? validateUpiId(String upiId) => upiId.isEmpty ? 'Invalid' : null;

  Future<void> _validateAndPreparePayment() async {
    _hideKeyboard();
    if (mounted) setState(() => _isProcessingPayment = true);

    final text = amountController.text.trim();
    final int? amt = int.tryParse(text);
    final minAmount =
        (double.tryParse(userController.minDeposit.value)?.toInt()) ?? 0;

    if (amt == null || amt < minAmount) {
      _showSnackBar(
          "Please enter a valid amount (min ₹${userController.minDeposit.value}).");
      if (mounted) setState(() => _isProcessingPayment = false);
      return;
    }

    setState(() {
      _currentTransactionAmount = amt;
      _currentTransactionId =
      '${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(9999).toString().padLeft(4, '0')}';
    });

    if (_apps.isEmpty) {
      _showSnackBar("No UPI apps found. Please install a UPI app.");
      setState(() => _isProcessingPayment = false);
      return;
    }

    _showUpiAppSelectionSheet();
  }

  void _showUpiAppSelectionSheet() {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      backgroundColor: Colors.white,
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select UPI App',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: _apps.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: .9,
                ),
                itemBuilder: (_, i) {
                  final app = _apps[i];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _currentPaymentMethodType = app.name ?? '';
                      _launchUpiWithApp(app);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: 48,
                            width: 48,
                            child: app.icon != null
                                ? Image.memory(app.icon!)
                                : const Icon(Icons.payment, size: 48)),
                        const SizedBox(height: 6),
                        Text(app.name ?? 'UPI',
                            textAlign: TextAlign.center, maxLines: 2),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (_isProcessingPayment && _currentPaymentMethodType.isEmpty) {
        setState(() => _isProcessingPayment = false);
      }
    });
  }

  Future<void> _launchUpiWithApp(UpiApp app) async {
    setState(() {
      _isProcessingPayment = true;
      _currentPaymentMethodType = app.name ?? '';
    });

    _upiPayeeName = userController.accountHolderName.value;
    if (_upiPayeeVPA.isEmpty || _upiPayeeName.isEmpty) {
      setState(() {
        _isProcessingPayment = false;
        _currentPaymentMethodType = '';
      });
      _showSnackBar('UPI payee details not configured.');
      return;
    }

    try {
      FlutterPayUpiManager.startPayment(
        paymentApp: app.app!,
        payeeVpa: _upiPayeeVPA,
        payeeName: _upiPayeeName,
        transactionId: _currentTransactionId,
        payeeMerchantCode: _merchantCode,
        description: "Add funds",
        amount: amountController.text.trim(),
        response: (UpiResponse upiResponse, String rawResponse) {
          log('UPI status: ${upiResponse.status} | $rawResponse');
          if (!mounted) return;
          setState(() => _isProcessingPayment = false);

          if ((upiResponse.status ?? '').toLowerCase() == 'success') {
            _reportPaymentStatusToBackend(upiResponse);
          } else {
            _showSnackBar('Payment failed or cancelled.');
          }
        },
        error: (String errorMessage) {
          setState(() {
            _isProcessingPayment = false;
            _currentPaymentMethodType = '';
          });
          _showSnackBar('UPI Error: $errorMessage');
        },
      );
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
        _currentPaymentMethodType = '';
      });
      _showSnackBar('Failed to launch UPI app.');
    }
  }

  Future<void> _reportPaymentStatusToBackend(UpiResponse upiResponse) async {
    final paymentHashKey =
        upiResponse.transactionReferenceId ??
            upiResponse.transactionID ??
            'default_hash_key';

    final depositType = _mapDepositType(_currentPaymentMethodType);

    final createBody = {
      "registerId": userController.registerId.value,
      "depositType": depositType,
      "amount": _currentTransactionAmount,
      "hashKey": paymentHashKey,
    };

    try {
      final createJson = await _postJsonSafe(
        'deposit-create-upi-fund-request',
        createBody,
      );

      if (createJson['status'] == true) {
        final infoRaw = createJson['info'];
        final Map<String, dynamic> info = (infoRaw is Map)
            ? Map<String, dynamic>.from(infoRaw as Map)
            : <String, dynamic>{};

        final String paymentHash = (info['paymentHash'] ?? '').toString();
        final int remark = (info['remark'] is num)
            ? (info['remark'] as num).toInt()
            : int.tryParse((info['remark'] ?? '0').toString()) ?? 0;
        final int timestamp = (info['timestamp'] is num)
            ? (info['timestamp'] as num).toInt()
            : int.tryParse((info['timestamp'] ?? '0').toString()) ?? 0;

        if (paymentHash.isEmpty || timestamp == 0) {
          _showSnackBar(
            'Invalid server response (missing paymentHash/timestamp).',
          );
          return;
        }

        final addBody = {
          "registerId": userController.registerId.value,
          "depositType": depositType,
          "amount": _currentTransactionAmount,
          "hashKey": paymentHashKey,
          "timestamp": timestamp,
          "paymentHash": paymentHash,
          "remark": remark,
        };

        final addJson = await _postJsonSafe(
          'add-upi-deposit-fund-request',
          addBody,
        );

        if (addJson['status'] == true) {
          if (mounted) {
            setState(() {
              _isProcessingPayment = false;
              _currentPaymentMethodType = '';
            });
          }
          await userController.fetchAndUpdateUserDetails();
          _softPollBalance(times: 3);

          amountController.clear();
          _showSnackBar(
            addJson['msg']?.toString() ?? 'Deposit successful and updated',
          );
        } else {
          _showSnackBar(
            addJson['msg']?.toString() ?? 'Failed to add deposit fund',
          );
        }
      } else {
        final code = createJson['_statusCode'];
        _showSnackBar(
          createJson['msg']?.toString() ??
              'Failed to create fund request (HTTP $code)',
        );
      }
    } catch (e) {
      _showSnackBar("Failed to complete payment process: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _currentPaymentMethodType = '';
        });
      }
    }
  }


  Future<void> _softPollBalance({int times = 3}) async {
    for (var i = 0; i < times; i++) {
      await Future.delayed(const Duration(seconds: 2));
      await userController.fetchAndUpdateUserDetails();
    }
  }
  Widget _quickBtn(int amount) => Expanded(
    child: GestureDetector(
      onTap: () {
        amountController.text = amount.toString();
        amountController.selection = TextSelection.fromPosition(
            TextPosition(offset: amountController.text.length));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFFF2600), width: 0.8),
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            "₹$amount",
            style: GoogleFonts.poppins(
                fontSize: 16,
                //fontWeight: FontWeight.w600,
                color: Colors.black),
          ),
        ),
      ),
    ),
  );
  // UI
  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFFF2600);
    final currentBalance = userController.walletBalance.value;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: CurvedAppBar(title: 'Funds'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Gama567",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Image.asset("assets/images/ic_wallet.png",
                              height: 30,
                              width: 30,
                              color: Colors.black,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_balance_wallet,
                                  size: 30)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("₹$currentBalance",
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              FutureBuilder<String>(
                                  future: _t("Current Balance"),
                                  builder: (context, snapshot) => Text(
                                      snapshot.data ?? "Current Balance",
                                      style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                          const Spacer(),
                          Image.asset('assets/images/mastercard.png',
                              height: 60,
                              width: 60,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.credit_card, size: 60)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              //
              // Text("Add Fund (Min ₹${userController.minDeposit.value})",
              //     textAlign: TextAlign.center,
              //     style: GoogleFonts.poppins(
              //         fontSize: 18, fontWeight: FontWeight.w400)),
              //
              // const SizedBox(height: 16),

              // Amount Input + Icon
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.grey.shade600,   // Border color
                    width: 0.5,           // Border thickness
                  ),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 4))
                  ],
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.account_balance,
                            color: Colors.black)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        cursorColor: orange,
                        style: GoogleFonts.poppins(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Add Fund (Min 500.00)',
                          hintStyle:
                          GoogleFonts.poppins(color: Colors.grey.shade600),

                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),


              Row(children: [_quickBtn(500), _quickBtn(1000)], mainAxisAlignment: MainAxisAlignment.spaceEvenly),
              const SizedBox(height: 10),
              Row(children: [_quickBtn(1500), _quickBtn(2000)], mainAxisAlignment: MainAxisAlignment.spaceEvenly),
              const SizedBox(height: 10),
              Row(children: [_quickBtn(5000), _quickBtn(10000)], mainAxisAlignment: MainAxisAlignment.spaceEvenly),

              const Spacer(),

              // UPI Button
              Visibility(
                visible: UPIShow,
                child: _WideBtn(
                  text: "ADD POINTS - UPI",
                  onPressed:
                  _isProcessingPayment ? null : _validateAndPreparePayment,
                  orange: orange,
                ),
              ),

              const SizedBox(height: 12),

              _WideBtn(
                text: "HOW TO ADD POINT",
                onPressed: _isProcessingPayment
                    ? null
                    : () => _showSnackBar(
                    "Please contact support to know how to add point."),
                orange: orange,
              ),

              if (_isProcessingPayment) ...[
                const SizedBox(height: 20),
                const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF2600))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Quick Amount Grid Widget
class _QuickAmountGrid extends StatelessWidget {
  final Function(int amount) onAmountSelected;

  const _QuickAmountGrid({required this.onAmountSelected});

  final List<int> amounts = const [500, 1000, 1500, 2000, 5000, 10000];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: amounts.length,
      itemBuilder: (context, index) {
        final amount = amounts[index];
        return GestureDetector(
          onTap: () => onAmountSelected(amount),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFF2600), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              "₹$amount",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF2600),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WideBtn extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color orange;

  const _WideBtn({required this.text, this.onPressed, required this.orange});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text,
            style:
            GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}