import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/constant/collection_name.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/constant/send_notification.dart';
import 'package:restaurant/constant/show_toast_dialog.dart';
import 'package:restaurant/models/order_model.dart';
import 'package:restaurant/models/user_model.dart';
import 'package:restaurant/models/vendor_model.dart';
import 'package:restaurant/service/audio_player_service.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class HomeController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> estimatedTimeController =
      TextEditingController().obs;

  RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getUserProfile();
    super.onInit();
  }

  RxList<OrderModel> allOrderList = <OrderModel>[].obs;
  RxList<OrderModel> newOrderList = <OrderModel>[].obs;
  RxList<OrderModel> acceptedOrderList = <OrderModel>[].obs;
  RxList<OrderModel> completedOrderList = <OrderModel>[].obs;
  RxList<OrderModel> rejectedOrderList = <OrderModel>[].obs;
  RxList<OrderModel> cancelledOrderList = <OrderModel>[].obs;

  Rx<UserModel> userModel = UserModel().obs;
  Rx<VendorModel> vendermodel = VendorModel().obs;

  getUserProfile() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then(
      (value) {
        if (value != null) {
          userModel.value = value;
          Constant.userModel = userModel.value;
        }
      },
    );
    if (userModel.value.vendorID != null ||
        userModel.value.vendorID!.isNotEmpty) {
      await FireStoreUtils.getVendorById(userModel.value.vendorID!).then(
        (vender) {
          if (vender?.id != null) {
            vendermodel.value = vender!;
          }
        },
      );
    }
    await getOrder();
    isLoading.value = false;
  }

  RxList<UserModel> driverUserList = <UserModel>[].obs;
  Rx<UserModel> selectDriverUser = UserModel().obs;

  RxList<UserModel> driverUserListFromDriver = <UserModel>[].obs;
  Rx<UserModel> selectDriverUserFromDriver = UserModel().obs;
  getAllDriverList() async {
    await FireStoreUtils.getAvalibleDrivers().then(
      (value) {
        if (value.isNotEmpty == true) {
          driverUserList.value = value;
        }
      },
    );
    isLoading.value = false;
  }

    getAllDriverListFromDriver() async {
    await FireStoreUtils.getAvalibleDriversFromDriver().then(
      (value) {
        if (value.isNotEmpty == true) {
          driverUserListFromDriver.value = value;
        }
      },
    );
    isLoading.value = false;
  }


  getOrder() async {
    FireStoreUtils.fireStore
        .collection(CollectionName.restaurantOrders)
        .where('vendorID', isEqualTo: Constant.userModel!.vendorID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (event) async {
        allOrderList.clear();
        for (var element in event.docs) {
          OrderModel orderModel = OrderModel.fromJson(element.data());
          allOrderList.add(orderModel);
          newOrderList.value = allOrderList
              .where((p0) => p0.status == Constant.orderPlaced)
              .toList();
          acceptedOrderList.value = allOrderList
              .where((p0) =>
                  p0.status == Constant.orderAccepted ||
                  p0.status == Constant.driverPending ||
                  p0.status == Constant.driverRejected ||
                  p0.status == Constant.orderShipped ||
                  p0.status == Constant.orderInTransit)
              .toList();
          completedOrderList.value = allOrderList
              .where((p0) => p0.status == Constant.orderCompleted)
              .toList();
          rejectedOrderList.value = allOrderList
              .where((p0) => p0.status == Constant.orderRejected)
              .toList();
          cancelledOrderList.value = allOrderList
              .where((p0) => p0.status == Constant.orderCancelled)
              .toList();
        }
        update();
        if (newOrderList.isNotEmpty == true) {
          await AudioPlayerService.playSound(true);
        }
      },
    );
  }
 

 Future<void> reassignOrder(OrderModel rejectedOrder) async {
  try {
    ShowToastDialog.showLoader('Reassigning order...'.tr);
    
    // Get available drivers (excluding those who already rejected this order)
    List<UserModel> availableDrivers = driverUserListFromDriver
        .where((driver) {
          // Driver must be available (no orders in progress)
          bool isAvailable = driver.inProgressOrderID?.isEmpty ?? true;
          
          // Driver must not have rejected this order before
          List<String> rejectedDriverIds = rejectedOrder.rejectedByDrivers?.cast<String>() ?? [];
          bool hasNotRejected = !rejectedDriverIds.contains(driver.id);
          
          return isAvailable && hasNotRejected;
        })
        .toList();

    if (availableDrivers.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("No available drivers found for reassignment. Order marked as unassigned.".tr);
      
      // Mark order as unassigned if no drivers available
      rejectedOrder.status = Constant.orderAccepted; // or create a new status like Constant.noDriverAvailable
      rejectedOrder.driverID = null;
      rejectedOrder.driver = null;
      await FireStoreUtils.updateOrder(rejectedOrder);
      await getOrder(); // Refresh order list
      return;
    }

    // Get restaurant/pickup location from orderModel
    String pickupLat = rejectedOrder.vendor?.latitude?.toString() ?? "0.0";
    String pickupLng = rejectedOrder.vendor?.longitude?.toString() ?? "0.0";

    UserModel selectedDriver;
    
    if (pickupLat != "0.0" && pickupLng != "0.0") {
      // Create a list to store drivers with their distances
      List<Map<String, dynamic>> driversWithDistance = [];
      
      // Calculate distance for each available driver
      for (UserModel driver in availableDrivers) {
        String driverLat = driver.location?.latitude?.toString() ?? "0.0";
        String driverLng = driver.location?.longitude?.toString() ?? "0.0";
        
        if (driverLat != "0.0" && driverLng != "0.0") {
          String distanceStr = Constant.getDistance(
            lat1: pickupLat,
            lng1: pickupLng,
            lat2: driverLat,
            lng2: driverLng,
          );
          
          double distance = double.parse(distanceStr);
          driversWithDistance.add({
            'driver': driver,
            'distance': distance
          });
        }
      }
      
      if (driversWithDistance.isNotEmpty) {
        // Sort by distance (closest first)
        driversWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));
        
        // Find the minimum distance
        double minDistance = driversWithDistance.first['distance'];
        
        // Get all drivers within a small range of the closest
        double tolerance = 0.5;
        List<UserModel> closestDrivers = driversWithDistance
            .where((item) => item['distance'] <= minDistance + tolerance)
            .map<UserModel>((item) => item['driver'])
            .toList();
        
        // Randomly select from the closest drivers
        closestDrivers.shuffle();
        selectedDriver = closestDrivers.first;
        
        // DEBUG: Show reassignment info
        debugPrint("=== ORDER REASSIGNMENT ===");
        debugPrint("Order ID: ${rejectedOrder.id}");
        debugPrint("Rejected by: ${rejectedOrder.rejectedByDrivers?.length ?? 0} drivers");
        debugPrint("Available drivers: ${availableDrivers.length}");
        debugPrint("Reassigned to: ${selectedDriver.fullName}");
        String selectedDistance = Constant.getDistance(
          lat1: pickupLat,
          lng1: pickupLng,
          lat2: selectedDriver.location?.latitude?.toString() ?? "0.0",
          lng2: selectedDriver.location?.longitude?.toString() ?? "0.0",
        );
      } else {
        // Fallback to random if no location data
        availableDrivers.shuffle();
        selectedDriver = availableDrivers.first;
        debugPrint("Reassigned Driver (Random - no location data)");
      }
    } else {
      // Fallback to random if no pickup location
      availableDrivers.shuffle();
      selectedDriver = availableDrivers.first;
      debugPrint("Reassigned Driver (Random - no pickup location)");
    }

    // Update order with new driver
    rejectedOrder.driverID = selectedDriver.id;
    rejectedOrder.driver = selectedDriver;
    rejectedOrder.status = Constant.driverPending;

    // Add order to new driver's queue
    selectedDriver.inProgressOrderID ??= [];
    selectedDriver.inProgressOrderID!.add(rejectedOrder.id);

    // Save to Firebase
    await FireStoreUtils.updateOrder(rejectedOrder);
    await FireStoreUtils.updateDriverUser(selectedDriver);

    // Send notifications
    await AudioPlayerService.playSound(false);
    SendNotification.sendFcmMessage(
        Constant.newDeliveryOrder,
        selectedDriver.fcmToken ?? '',
        {});

    // Refresh the order list
    await getOrder();
    
    ShowToastDialog.closeLoader();
    ShowToastDialog.showToast("Order successfully reassigned".tr);
    
  } catch (e) {
    ShowToastDialog.closeLoader();
    debugPrint("Error reassigning order: $e");
    ShowToastDialog.showToast("Failed to reassign order. Please try again.".tr);
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
