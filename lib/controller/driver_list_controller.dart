import 'package:get/get.dart';
import 'package:restaurant/models/user_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class DriverListController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    getAllDriverList();
    super.onInit();
  }

  RxBool isLoading = true.obs;
  RxList<UserModel> driverUserList = <UserModel>[].obs;

  getAllDriverList() async {
    await FireStoreUtils.getAllDrivers().then(
      (value) {
        if (value.isNotEmpty == true) {
          driverUserList.value = value;
        }
      },
    );
    isLoading.value = false;
  }

  updateDriver(UserModel user) async {
    await FireStoreUtils.updateDriverUser(user);
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
