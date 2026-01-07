import 'dart:async';
import 'package:restaurant/app/auth_screen/login_screen.dart';
import 'package:restaurant/app/dash_board_screens/app_not_access_screen.dart';
import 'package:restaurant/app/dash_board_screens/dash_board_screen.dart';
import 'package:restaurant/app/on_boarding_screen.dart';
import 'package:restaurant/app/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/utils/fire_store_utils.dart';
import 'package:restaurant/utils/notification_service.dart';
import 'package:restaurant/utils/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    Timer(const Duration(seconds: 3), () => redirectScreen());
    super.onInit();
  }

  redirectScreen() async {
    if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
      Get.offAll(const OnBoardingScreen());
    } else {
      bool isLogin = await FireStoreUtils.isLogin();
      if (isLogin == true) {
        await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
            .then((value) async {
          if (value != null) {
            Constant.userModel = value;
            if (Constant.userModel?.role == Constant.userRoleVendor) {
              if (Constant.userModel?.active == true) {
                Constant.userModel?.fcmToken =
                    await NotificationService.getToken();
                await FireStoreUtils.updateUser(Constant.userModel!);
                bool isPlanExpire = false;
                if (Constant.userModel?.subscriptionPlan?.id != null) {
                  if (Constant.userModel?.subscriptionExpiryDate == null) {
                    if (Constant.userModel?.subscriptionPlan?.expiryDay ==
                        '-1') {
                      isPlanExpire = false;
                    } else {
                      isPlanExpire = true;
                    }
                  } else {
                    DateTime expiryDate =
                        Constant.userModel!.subscriptionExpiryDate!.toDate();
                    isPlanExpire = expiryDate.isBefore(DateTime.now());
                  }
                } else {
                  isPlanExpire = true;
                }
                if (Constant.userModel?.subscriptionPlanId == null ||
                    isPlanExpire == true) {
                  if (Constant.adminCommission?.isEnabled == false &&
                      Constant.isSubscriptionModelApplied == false) {
                    Get.offAll(const DashBoardScreen());
                  } else {
                    Get.offAll(const SubscriptionPlanScreen());
                  }
                } else if (Constant.userModel!.subscriptionPlan?.features
                        ?.restaurantMobileApp ==
                    true) {
                  Get.offAll(const DashBoardScreen());
                } else {
                  Get.offAll(const AppNotAccessScreen());
                }
              } else {
                await FirebaseAuth.instance.signOut();
                Get.offAll(const LoginScreen());
              }
            } else {
              await FirebaseAuth.instance.signOut();
              Get.offAll(const LoginScreen());
            }
          }
        });
      } else {
        await FirebaseAuth.instance.signOut();
        Get.offAll(const LoginScreen());
      }
    }
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
