import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/constant/show_toast_dialog.dart';

class OtpController extends GetxController {
  Rx<TextEditingController> otpController = TextEditingController().obs;

  RxString countryCode = "".obs;
  RxString phoneNumber = "".obs;
  RxString verificationId = "".obs;
  Rx<int?> resendToken = Rx<int?>(null);
  RxBool isLoading = true.obs;

  // OTP attempt tracking
  RxInt invalidAttempts = 0.obs;
  RxBool isLocked = false.obs;
  RxInt lockoutTimeRemaining = 0.obs;
  RxBool showCaptcha = false.obs;

  static const int MAX_ATTEMPTS = 5;
  static const int LOCKOUT_DURATION_SECONDS = 300; // 5 minutes

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      countryCode.value = argumentData['countryCode'];
      phoneNumber.value = argumentData['phoneNumber'];
      verificationId.value = argumentData['verificationId'];
    }
    isLoading.value = false;
    update();
  }

  Future<bool> sendOTP() async {
    // Reset attempt counter on resend
    invalidAttempts.value = 0;
    isLocked.value = false;
    showCaptcha.value = false;
    otpController.value.clear();

    ShowToastDialog.showLoader("Sending OTP...".tr);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: countryCode.value + phoneNumber.value,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to send OTP: ${e.message}".tr);
      },
      codeSent: (String verificationId0, int? resendToken0) async {
        verificationId.value = verificationId0;
        resendToken.value = resendToken0;
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("OTP sent successfully".tr);
      },
      timeout: const Duration(seconds: 25),
      forceResendingToken: resendToken.value,
      codeAutoRetrievalTimeout: (String verificationId0) {
        verificationId0 = verificationId.value;
      },
    );
    return true;
  }

  /// Handles invalid OTP attempts and triggers lockout/captcha
  void handleInvalidOtpAttempt() {
    invalidAttempts.value++;

    if (invalidAttempts.value >= MAX_ATTEMPTS) {
      // Trigger lockout
      isLocked.value = true;
      showCaptcha.value = true;
      lockoutTimeRemaining.value = LOCKOUT_DURATION_SECONDS;

      ShowToastDialog.showToast(
        "Too many invalid attempts. Please try again after $LOCKOUT_DURATION_SECONDS seconds."
            .tr,
      );

      // Start lockout timer
      _startLockoutTimer();
    } else {
      int remainingAttempts = MAX_ATTEMPTS - invalidAttempts.value;
      ShowToastDialog.showToast(
        "Invalid OTP. Attempts remaining: $remainingAttempts".tr,
      );
    }
  }

  /// Starts a countdown timer for account lockout
  void _startLockoutTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (lockoutTimeRemaining.value > 0) {
        lockoutTimeRemaining.value--;
        _startLockoutTimer();
      } else {
        // Reset after lockout expires
        isLocked.value = false;
        showCaptcha.value = false;
        invalidAttempts.value = 0;
        ShowToastDialog.showToast("You can try again now".tr);
      }
    });
  }

  /// Resets invalid attempts on successful verification
  void resetAttempts() {
    invalidAttempts.value = 0;
    isLocked.value = false;
    showCaptcha.value = false;
    lockoutTimeRemaining.value = 0;
  }
}
/*******************************************************************************************
* Copyright (c) 2025 Movenetics Digital. All rights reserved.
*
* This software and associated documentation files are the property of 
* Movenetics Digital. Unauthorized copying, modification, distribution, or use of this 
* Software, via any medium, is strictly prohibited without prior written permission.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Aman Bhandari 
*******************************************************************************************/
