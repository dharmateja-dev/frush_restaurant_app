import 'package:get/get.dart';
import 'package:restaurant/app/Home_screen/home_screen.dart';
import 'package:restaurant/app/dine_in_order_screen/dine_in_order_screen.dart';
import 'package:restaurant/app/product_screens/product_list_screen.dart';
import 'package:restaurant/app/profile_screen/profile_screen.dart';
import 'package:restaurant/app/wallet_screen/wallet_screen.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class DashBoardController extends GetxController {
  RxInt selectedIndex = 0.obs;
  RxList pageList = [].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getVendor();
    setPage();
    super.onInit();
  }

  setPage() {
    pageList.value = Constant.isDineInEnable &&
            Constant.userModel?.subscriptionPlan?.features?.dineIn != false
        ? [
            const HomeScreen(),
            const DineInOrderScreen(),
            const ProductListScreen(),
            const WalletScreen(),
            const ProfileScreen(),
          ]
        : [
            const HomeScreen(),
            const ProductListScreen(),
            const WalletScreen(),
            const ProfileScreen(),
          ];
  }

  getVendor() async {
    if (Constant.userModel?.vendorID != null) {
      await FireStoreUtils.getVendorById(
              Constant.userModel!.vendorID.toString())
          .then(
        (value) {
          if (value != null) {
            Constant.vendorAdminCommission = value.adminCommission;
          }
        },
      );
    }
  }

  DateTime? currentBackPressTime;
  RxBool canPopNow = false.obs;
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
