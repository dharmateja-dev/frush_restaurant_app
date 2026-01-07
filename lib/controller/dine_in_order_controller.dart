import 'package:get/get.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/models/dine_in_booking_model.dart';
import 'package:restaurant/models/user_model.dart';
import 'package:restaurant/models/vendor_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class DineInOrderController extends GetxController {
  RxBool isLoading = true.obs;
  RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getUserProfile();
    super.onInit();
  }

  Rx<UserModel> userModel = UserModel().obs;
  Rx<VendorModel> vendorModel = VendorModel().obs;

  RxList<DineInBookingModel> featureList = <DineInBookingModel>[].obs;
  RxList<DineInBookingModel> historyList = <DineInBookingModel>[].obs;

  getUserProfile() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then(
      (value) {
        if (value != null) {
          userModel.value = value;
        }
      },
    );

    if (Constant.userModel!.vendorID != null &&
        Constant.userModel!.vendorID!.isNotEmpty) {
      await FireStoreUtils.getVendorById(
              Constant.userModel!.vendorID.toString())
          .then(
        (value) {
          if (value != null) {
            vendorModel.value = value;
          }
        },
      );

      await getDineBooking();
    }

    isLoading.value = false;
  }

  getDineBooking() async {
    await FireStoreUtils.getDineInBooking(true).then(
      (value) {
        featureList.value = value;
      },
    );
    await FireStoreUtils.getDineInBooking(false).then(
      (value) {
        historyList.value = value;
      },
    );
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
