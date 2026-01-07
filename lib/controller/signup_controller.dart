import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant/app/auth_screen/login_screen.dart';
import 'package:restaurant/app/dash_board_screens/app_not_access_screen.dart';
import 'package:restaurant/app/dash_board_screens/dash_board_screen.dart';
import 'package:restaurant/app/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/constant/show_toast_dialog.dart';
import 'package:restaurant/models/user_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';
import 'package:restaurant/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  Rx<TextEditingController> firstNameEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> lastNameEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> emailEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> phoneNUmberEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> countryCodeEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> passwordEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> conformPasswordEditingController =
      TextEditingController().obs;

  RxBool passwordVisible = true.obs;
  RxBool conformPasswordVisible = true.obs;

  RxString type = "".obs;

  Rx<UserModel> userModel = UserModel().obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      type.value = argumentData['type'];
      userModel.value = argumentData['userModel'];
      if (type.value == "mobileNumber") {
        phoneNUmberEditingController.value.text =
            userModel.value.phoneNumber.toString();
        countryCodeEditingController.value.text =
            userModel.value.countryCode.toString();
      } else if (type.value == "google" || type.value == "apple") {
        emailEditingController.value.text = userModel.value.email ?? "";
        firstNameEditingController.value.text = userModel.value.firstName ?? "";
        lastNameEditingController.value.text = userModel.value.lastName ?? "";
      }
    }
  }

  /// Sends verification email to user
  Future<void> _sendEmailVerification(User firebaseUser) async {
    try {
      await firebaseUser.sendEmailVerification();
      ShowToastDialog.showToast(
          "Verification email sent. Please check your inbox.".tr);
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }

  /// Validates email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }

  /// Checks if phone number already exists in the system
  Future<bool> _doesPhoneNumberExist(String phone) async {
    try {
      final query = await FireStoreUtils.fireStore
          .collection('users')
          .where('phoneNumber', isEqualTo: phone)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone number: $e');
      return false;
    }
  }

  /// Checks if email already exists in the system
  Future<bool> _doesEmailExist(String email) async {
    try {
      final query = await FireStoreUtils.fireStore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  signUpWithEmailAndPassword() async {
    signUp();
  }

  signUp() async {
    ShowToastDialog.showLoader("Please wait");
    if (type.value == "google" ||
        type.value == "apple" ||
        type.value == "mobileNumber") {
      // Validate email format
      if (!_isValidEmail(emailEditingController.value.text)) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Please enter a valid email address".tr);
        return;
      }

      // Check if phone number already exists
      bool phoneExists = await _doesPhoneNumberExist(
          phoneNUmberEditingController.value.text.trim());
      if (phoneExists) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "This phone number is already registered. Please use a different number or login."
                .tr);
        return;
      }

      // Check if email already exists
      bool emailExists =
          await _doesEmailExist(emailEditingController.value.text.trim());
      if (emailExists) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "This email is already registered. Please use a different email or login."
                .tr);
        return;
      }

      ShowToastDialog.showLoader("Creating account...".tr);
      userModel.value.firstName =
          firstNameEditingController.value.text.toString();
      userModel.value.lastName =
          lastNameEditingController.value.text.toString();
      userModel.value.email =
          emailEditingController.value.text.toString().toLowerCase();
      userModel.value.phoneNumber =
          phoneNUmberEditingController.value.text.toString();
      userModel.value.role = Constant.userRoleVendor;
      userModel.value.fcmToken = await NotificationService.getToken();
      userModel.value.active =
          Constant.autoApproveRestaurant == true ? true : false;
      userModel.value.countryCode = countryCodeEditingController.value.text;
      userModel.value.isDocumentVerify =
          Constant.isRestaurantVerification == true ? false : true;
      userModel.value.createdAt = Timestamp.now();
      userModel.value.appIdentifier = Platform.isAndroid ? 'android' : 'ios';

      await FireStoreUtils.updateUser(userModel.value).then(
        (value) async {
          if (Constant.autoApproveRestaurant == true) {
            bool isPlanExpire = false;
            if (userModel.value.subscriptionPlan?.id != null) {
              if (userModel.value.subscriptionExpiryDate == null) {
                if (userModel.value.subscriptionPlan?.expiryDay == '-1') {
                  isPlanExpire = false;
                } else {
                  isPlanExpire = true;
                }
              } else {
                DateTime expiryDate =
                    userModel.value.subscriptionExpiryDate!.toDate();
                isPlanExpire = expiryDate.isBefore(DateTime.now());
              }
            } else {
              isPlanExpire = true;
            }
            if (userModel.value.subscriptionPlanId == null ||
                isPlanExpire == true) {
              if (Constant.adminCommission?.isEnabled == false &&
                  Constant.isSubscriptionModelApplied == false) {
                Get.offAll(const DashBoardScreen());
              } else {
                Get.offAll(const SubscriptionPlanScreen());
              }
            } else if (userModel.value.subscriptionPlan?.features
                        ?.restaurantMobileApp !=
                    false ||
                userModel.value.subscriptionPlan?.type == 'free') {
              Get.offAll(const DashBoardScreen());
            } else {
              Get.offAll(const AppNotAccessScreen());
            }
          } else {
            ShowToastDialog.showToast(
                "Thank you for sign up, your application is under approval so please wait till that approve."
                    .tr);
            Get.offAll(const LoginScreen());
          }
        },
      );
    } else {
      // Email/password signup
      // Validate email format
      if (!_isValidEmail(emailEditingController.value.text)) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Please enter a valid email address".tr);
        return;
      }

      // Check if phone number already exists
      bool phoneExists = await _doesPhoneNumberExist(
          phoneNUmberEditingController.value.text.trim());
      if (phoneExists) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "This phone number is already registered. Please use a different number or login."
                .tr);
        return;
      }

      // Check if email already exists
      bool emailExists =
          await _doesEmailExist(emailEditingController.value.text.trim());
      if (emailExists) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "This email is already registered. Please use a different email or login."
                .tr);
        return;
      }

      ShowToastDialog.showLoader("Creating account...".tr);
      try {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailEditingController.value.text.trim(),
          password: passwordEditingController.value.text.trim(),
        );
        if (credential.user != null) {
          userModel.value.id = credential.user!.uid;
          userModel.value.firstName =
              firstNameEditingController.value.text.toString();
          userModel.value.lastName =
              lastNameEditingController.value.text.toString();
          userModel.value.email =
              emailEditingController.value.text.toString().toLowerCase();
          userModel.value.phoneNumber =
              phoneNUmberEditingController.value.text.toString();
          userModel.value.role = Constant.userRoleVendor;
          userModel.value.fcmToken = await NotificationService.getToken();
          userModel.value.active =
              Constant.autoApproveRestaurant == true ? true : false;
          userModel.value.isDocumentVerify =
              Constant.isRestaurantVerification == true ? false : true;
          userModel.value.countryCode = countryCodeEditingController.value.text;
          userModel.value.appIdentifier =
              Platform.isAndroid ? 'android' : 'ios';
          userModel.value.createdAt = Timestamp.now();
          userModel.value.provider = 'email';

          // Send email verification
          if (credential.user != null) {
            await _sendEmailVerification(credential.user!);
          }

          await FireStoreUtils.updateUser(userModel.value).then(
            (value) async {
              if (Constant.autoApproveRestaurant == true) {
                bool isPlanExpire = false;
                if (userModel.value.subscriptionPlan?.id != null) {
                  if (userModel.value.subscriptionExpiryDate == null) {
                    if (userModel.value.subscriptionPlan?.expiryDay == '-1') {
                      isPlanExpire = false;
                    } else {
                      isPlanExpire = true;
                    }
                  } else {
                    DateTime expiryDate =
                        userModel.value.subscriptionExpiryDate!.toDate();
                    isPlanExpire = expiryDate.isBefore(DateTime.now());
                  }
                } else {
                  isPlanExpire = true;
                }
                if (userModel.value.subscriptionPlanId == null ||
                    isPlanExpire == true) {
                  if (Constant.adminCommission?.isEnabled == false &&
                      Constant.isSubscriptionModelApplied == false) {
                    Get.offAll(const DashBoardScreen());
                  } else {
                    Get.offAll(const SubscriptionPlanScreen());
                  }
                } else if (userModel.value.subscriptionPlan?.features
                            ?.restaurantMobileApp !=
                        false ||
                    userModel.value.subscriptionPlan?.type == 'free') {
                  Get.offAll(const DashBoardScreen());
                } else {
                  Get.offAll(const AppNotAccessScreen());
                }
              } else {
                ShowToastDialog.showToast(
                    "Thank you for sign up, your application is under approval so please wait till that approve."
                        .tr);
                Get.offAll(const LoginScreen());
              }
            },
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ShowToastDialog.showToast("The password provided is too weak.".tr);
        } else if (e.code == 'email-already-in-use') {
          ShowToastDialog.showToast(
              "The account already exists for that email.".tr);
        } else if (e.code == 'invalid-email') {
          ShowToastDialog.showToast("Enter email is Invalid".tr);
        }
      } catch (e) {
        ShowToastDialog.showToast(e.toString());
      }
    }

    ShowToastDialog.closeLoader();
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
