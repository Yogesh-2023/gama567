import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:new_sara/components/AppNameBold.dart';
import 'package:new_sara/ulits/Constents.dart';

import '../ulits/curved_appbar.dart';

class BankDetailsFragment extends StatefulWidget {
  const BankDetailsFragment({super.key});

  @override
  State<BankDetailsFragment> createState() => _BankDetailsFragmentState();
}

class _BankDetailsFragmentState extends State<BankDetailsFragment> {
  final nameController = TextEditingController();
  final accNumberController = TextEditingController();
  final ifscController = TextEditingController();
  final bankNameController = TextEditingController();
  final branchController = TextEditingController();

  final String token = GetStorage().read(
    "accessToken",
  ); // ideally store securely

  Future<void> submitBankDetails() async {
    final String url = '${Constant.apiEndpoint}user-bank-details';
    final String registerId = GetStorage().read("registerId");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'deviceId': 'qwert',
          'deviceName': 'sm2233',
          'accessStatus': '1',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "registerId": registerId,
          // optionally send form data here if backend requires
          // "accountName": nameController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Success: $data");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bank details submitted successfully")),
        );

        // Clear fields on success
        nameController.clear();
        accNumberController.clear();
        ifscController.clear();
        bankNameController.clear();
        branchController.clear();

        Navigator.pop(context);
      } else {
        print("Error: ${response.statusCode} ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      //  backgroundColor: Colors.grey.shade200,
      backgroundColor: Colors.white,

      appBar: CurvedAppBar(title: 'Add Bank Details'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              const SizedBox(
                height: 30,
              ), // Increased from 20 to 30 to push content further down
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Bank Details",
                  style: TextStyle(
                    fontSize: 18,
                    // fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: 15),
              // const SizedBox(height: 40),
              inputCardField(
                "Account Holder Name",
                "Enter account holder name",
                nameController,
              ),
              inputCardField(
                "Account Number",
                "Enter account number",
                accNumberController,
              ),
              inputCardField(
                "Bank Name",
                "Enter bank name",
                bankNameController,
              ),
              inputCardField(
                "Branch Name",
                "Enter branch name",
                branchController,
              ),
              inputCardField("IFSC Code", "Enter IFSC code", ifscController),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: submitBankDetails,
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: Color(0xffFF2600),
                    //  padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "SAVE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputCardField(
    String label,
    String hintText,
    TextEditingController controller,
  ) {
    return Card(
      elevation: 1,

      ///   shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        height: 45,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFFF5F5F5), // ← Your border color
            width: 1, // border thickness
          ),
        ),
        alignment: Alignment.center,
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
