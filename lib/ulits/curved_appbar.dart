import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../Helper/UserController.dart';

class CurvedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;

  CurvedAppBar({super.key, required this.title, this.onBack});

  // Safely access UserController with fallback
  UserController? get _userController {
    try {
      return Get.isRegistered<UserController>() ? Get.find<UserController>() : null;
    } catch (e) {
      // If there's any error accessing the controller, return null
      return null;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final userController = _userController;

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
              onTap: onBack ?? () {
                // Check if we can pop the current route
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // If we can't pop, we still want to trigger the back action
                  // This is especially important in tabbed interfaces
                  Navigator.maybePop(context);
                }
              },
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
                  fontSize: 18.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ⭐ Wallet - only show if UserController is available and account is active
            if (userController != null)
              Obx(
                () => userController.accountStatus.value
                    ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                      child: Row(
                          children: [
                            Image.asset(
                              "assets/icons/walletCard.png",  // yaha apna icon ka path
                              width: 24,
                              height: 24,
                              color: Colors.white, // optional: agar aap icon ko color dena chahte ho
                            ),

                            const SizedBox(width: 9),
                            Text(
                              "₹${userController.walletBalance.value}",
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    )
                    : const SizedBox.shrink(),
              )
            else
              const SizedBox.shrink(), // Show nothing if UserController is not available
          ],
        ),
      ),
    );
  }
}