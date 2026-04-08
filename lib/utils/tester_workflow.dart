import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/remote_config_controller.dart';
import '../widgets/custom_text.dart';
import '../widgets/CustomPressButton.dart';

class TesterWorkflow {
  // String constants used in the dialog
  static const String heyTester = "Hey Tester";
  static const String enterCredentials = "Enter Credentials to gain access";
  static const String enterEmail = "Email Identifier";
  static const String enterPassword = "Access Key";
  static const String emailCannotBe = "Email cannot be empty";
  static const String passwordCannotBe = "Password cannot be empty";
  static const String cancel = "Cancel";
  static const String testIt = "Test It";
  static const String enteredDetails = "Invalid credentials. Please try again.";

  /// Shows the tester login dialog using the specific design provided.
  static void show(BuildContext context, {required VoidCallback onSuccess}) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passController = TextEditingController();
    final RxString errorText = ''.obs;

    showDialog(
      barrierColor: Colors.black.withOpacity(0.75),
      context: context,
      builder: (context) {
        return PopScope(
          canPop: true,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Center(
              child: Container(
                width: Get.width * 0.9,
                padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 60.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80.r),
                  gradient: const LinearGradient(
                    colors: [Color(0xff1C1C1E), Color(0xff2C2C2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 30.h),

                      /// Title
                      CustomText(
                        text: heyTester,
                        fontSize: 60.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),

                      SizedBox(height: 15.h),

                      /// Subtitle
                      CustomText(
                        text: enterCredentials,
                        fontSize: 40.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade400,
                      ),

                      SizedBox(height: 40.h),

                      /// Email
                      _buildDarkInputField(
                        controller: emailController,
                        icon: Icons.email_rounded,
                        hintText: enterEmail,
                      ),

                      SizedBox(height: 25.h),

                      /// Password
                      _buildDarkInputField(
                        controller: passController,
                        icon: Icons.lock_rounded,
                        hintText: enterPassword,
                        obscure: true,
                      ),

                      SizedBox(height: 15.h),

                      /// Error
                      Obx(
                        () => AnimatedOpacity(
                          opacity: errorText.value.isEmpty ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            errorText.value,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 34.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      /// Buttons
                      Row(
                        children: [
                          /// Cancel
                          Expanded(
                            child: CustomPressButton(
                              onTap: () => Get.back(),
                              child: Container(
                                height: 120.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xff3A3A3C),
                                  borderRadius: BorderRadius.circular(48.r),
                                ),
                                child: Center(
                                  child: CustomText(
                                    text: cancel,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 40.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 40.w),

                          /// ✅ Test It button
                          Expanded(
                            child: CustomPressButton(
                                onTap: () {
                                final email = emailController.text.trim();
                                final pass = passController.text.trim();
                                
                                debugPrint("🛠️ Tester Login Attempt:");
                                debugPrint("   Entered: Email='$email', Pass='$pass'");
                                //debugPrint("   Expected: Email='${AdsVariable.testEmail}', Pass='${AdsVariable.testPassword}'");

                                if (email.isEmpty) {
                                  errorText.value = emailCannotBe;
                                } else if (pass.isEmpty) {
                                  errorText.value = passwordCannotBe;
                                } else if (email == AdsVariable.testEmail &&
                                    pass == AdsVariable.testPassword) {
                                  Navigator.of(context).pop(); // Close Dialog
                                  Navigator.of(context).pop(true); // Close ProScreen with Success
                                  onSuccess(); // Execute bypass logic
                                } else {
                                  errorText.value = enteredDetails;
                                }
                              },
                              child: Container(
                                height: 120.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(48.r),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CustomText(
                                    text: testIt,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildDarkInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(48.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: Colors.white, fontSize: 40.sp),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 36.sp),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 50.w),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
        ),
      ),
    );
  }
}
