import 'dart:async';
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

  // Auto-reassignment properties
  Timer? _driverResponseTimer;
  Timer? _driverArrivalTimer;
  final List<String> triedDriverIds = [];

  // Track orders with arrival timers
  final Map<String, Timer> _activeArrivalTimers = {};

  @override
  void onInit() {
    getUserProfile();
    super.onInit();
  }

  @override
  void onClose() {
    _driverResponseTimer?.cancel();
    _driverArrivalTimer?.cancel();
    // Cancel all active arrival timers
    for (var timer in _activeArrivalTimers.values) {
      timer.cancel();
    }
    _activeArrivalTimers.clear();
    super.onClose();
  }

  RxList<OrderModel> allOrderList = <OrderModel>[].obs;
  RxList<OrderModel> newOrderList = <OrderModel>[].obs;
  RxList<OrderModel> acceptedOrderList = <OrderModel>[].obs;
  RxList<OrderModel> completedOrderList = <OrderModel>[].obs;
  RxList<OrderModel> rejectedOrderList = <OrderModel>[].obs;
  RxList<OrderModel> cancelledOrderList = <OrderModel>[].obs;

  // Track estimated arrival times for display
  final Map<String, int> estimatedArrivalTimes = {};

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

          // Check if driver accepted and hasn't reached restaurant yet
          // Using "Driver Accepted" as that's the actual status from Firebase
          if (orderModel.status == "Driver Accepted" &&
              orderModel.driverID != null &&
              !_activeArrivalTimers.containsKey(orderModel.id)) {
            _startDriverArrivalTimer(orderModel);
          }

          // Also check for Constant.orderAccepted in case it's used elsewhere
          if (orderModel.status == Constant.orderAccepted &&
              orderModel.driverID != null &&
              !_activeArrivalTimers.containsKey(orderModel.id)) {
            _startDriverArrivalTimer(orderModel);
          }

          // Cancel timer if order status changes
          if (orderModel.status == Constant.orderShipped ||
              orderModel.status == Constant.orderInTransit ||
              orderModel.status == Constant.orderCompleted ||
              orderModel.status == Constant.orderCancelled) {
            _cancelArrivalTimer(orderModel.id ?? '');
          }

          newOrderList.value = allOrderList
              .where((p0) => p0.status == Constant.orderPlaced)
              .toList();
          acceptedOrderList.value = allOrderList
              .where((p0) =>
                  p0.status == Constant.orderAccepted ||
                  p0.status == "Driver Accepted" ||
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

  // NEW: Calculate estimated time for driver to reach restaurant
  int _calculateEstimatedArrivalTime(OrderModel orderModel, UserModel driver) {
    String pickupLat = orderModel.vendor?.latitude?.toString() ?? "0.0";
    String pickupLng = orderModel.vendor?.longitude?.toString() ?? "0.0";
    String driverLat = driver.location?.latitude?.toString() ?? "0.0";
    String driverLng = driver.location?.longitude?.toString() ?? "0.0";

    if (pickupLat != "0.0" &&
        pickupLng != "0.0" &&
        driverLat != "0.0" &&
        driverLng != "0.0") {
      String distanceStr = Constant.getDistance(
        lat1: pickupLat,
        lng1: pickupLng,
        lat2: driverLat,
        lng2: driverLng,
      );

      double distanceKm = double.parse(distanceStr);

      // Assume average speed of 30 km/h in city traffic
      // Convert to minutes and round up
      int estimatedMinutes = ((distanceKm / 30.0) * 60).ceil();

      // Minimum 5 minutes, maximum 60 minutes
      estimatedMinutes = estimatedMinutes.clamp(5, 60);

      debugPrint("=== ARRIVAL TIME CALCULATION ===");
      debugPrint("Distance: ${distanceKm.toStringAsFixed(2)} km");
      debugPrint("Estimated arrival time: $estimatedMinutes minutes");

      return estimatedMinutes;
    }

    // Default to 20 minutes if location data unavailable
    return 20;
  }

  // NEW: Start timer to track driver arrival at restaurant
  void _startDriverArrivalTimer(OrderModel orderModel) {
    if (orderModel.driver == null || orderModel.id == null) return;

    // Cancel existing timer for this order if any
    _cancelArrivalTimer(orderModel.id!);

    int estimatedMinutes =
        _calculateEstimatedArrivalTime(orderModel, orderModel.driver!);

    // Store estimated time for UI display
    estimatedArrivalTimes[orderModel.id!] = estimatedMinutes;

    // Add 10 minute buffer
    int totalMinutes = estimatedMinutes + 10;

    debugPrint("=== DRIVER ARRIVAL TRACKING STARTED ===");
    debugPrint("Order ID: ${orderModel.id}");
    debugPrint("Driver: ${orderModel.driver?.fullName}");
    debugPrint("Estimated arrival: $estimatedMinutes minutes");
    debugPrint("Total allowed time (with buffer): $totalMinutes minutes");

    Timer arrivalTimer = Timer(
      Duration(minutes: totalMinutes),
      () async {
        debugPrint("=== DRIVER ARRIVAL TIMEOUT ===");
        debugPrint("Order ID: ${orderModel.id}");

        // Fetch latest order status
        OrderModel? latestOrder =
            await FireStoreUtils.getOrderById(orderModel.id ?? '');

        if (latestOrder == null) {
          debugPrint("Order not found in database");
          _cancelArrivalTimer(orderModel.id!);
          return;
        }

        // Check if driver has reached restaurant (status changed to shipped/in-transit)
        if (latestOrder.status == Constant.orderShipped ||
            latestOrder.status == Constant.orderInTransit ||
            latestOrder.status == "Order Shipped" ||
            latestOrder.status == "In Transit" ||
            latestOrder.status == Constant.orderCompleted) {
          debugPrint(
              "Driver has picked up the order. Status: ${latestOrder.status}");
          _cancelArrivalTimer(orderModel.id!);
          return;
        }

        // Check if order was cancelled or completed
        if (latestOrder.status == Constant.orderCancelled ||
            latestOrder.status == Constant.orderCompleted) {
          debugPrint("Order was cancelled or completed");
          _cancelArrivalTimer(orderModel.id!);
          return;
        }

        debugPrint(
            "Driver ${orderModel.driver?.fullName} did not reach restaurant in time");
        debugPrint("Reassigning order...");

        // Remove order from driver's in-progress list
        if (latestOrder.driver != null) {
          latestOrder.driver!.inProgressOrderID?.remove(orderModel.id);
          await FireStoreUtils.updateDriverUser(latestOrder.driver!);
        }

        // Add current driver to rejected list
        latestOrder.rejectedByDrivers ??= [];
        if (!latestOrder.rejectedByDrivers!.contains(latestOrder.driverID)) {
          latestOrder.rejectedByDrivers!.add(latestOrder.driverID);
        }

        // Send notification to driver about removal
        if (latestOrder.driver?.fcmToken != null) {
          SendNotification.sendFcmMessage(
              "Order Removed", latestOrder.driver!.fcmToken!, {
            'message':
                'Order was reassigned due to delayed arrival at restaurant'
          });
        }

        // Show notification
        ShowToastDialog.showToast(
            "Driver didn't reach restaurant in time. Reassigning order...".tr);

        // Cancel this timer
        _cancelArrivalTimer(orderModel.id!);

        // Wait a moment before reassigning
        await Future.delayed(const Duration(seconds: 1));

        // Reassign to another driver
        await reassignOrder(latestOrder);
      },
    );

    // Store the timer
    _activeArrivalTimers[orderModel.id!] = arrivalTimer;
  }

  // NEW: Cancel arrival timer for an order
  void _cancelArrivalTimer(String orderId) {
    if (_activeArrivalTimers.containsKey(orderId)) {
      _activeArrivalTimers[orderId]?.cancel();
      _activeArrivalTimers.remove(orderId);
      estimatedArrivalTimes.remove(orderId);
      debugPrint("Arrival timer cancelled for order: $orderId");
    }
  }

  // Main assignment method with auto-reassignment
  Future<void> assignDriverWithAutoReassignment(OrderModel orderModel) async {
    try {
      List<UserModel> availableDrivers = driverUserListFromDriver
          .where((driver) =>
              (driver.inProgressOrderID?.isEmpty ?? true) &&
              !triedDriverIds.contains(driver.id))
          .toList();

      if (availableDrivers.isEmpty) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("No available delivery man found.".tr);
        triedDriverIds.clear();
        return;
      }

      // Get restaurant/pickup location
      String pickupLat = orderModel.vendor?.latitude?.toString() ?? "0.0";
      String pickupLng = orderModel.vendor?.longitude?.toString() ?? "0.0";

      UserModel selectedDriver =
          _selectClosestDriver(availableDrivers, pickupLat, pickupLng);

      // Add to tried drivers list
      triedDriverIds.add(selectedDriver.id ?? '');

      debugPrint("=== DRIVER ASSIGNMENT ATTEMPT ===");
      debugPrint("Assigned to: ${selectedDriver.fullName}");
      debugPrint(
          "Waiting for acceptance (${Constant.driverOrderAcceptRejectDuration} seconds)...");
      debugPrint("Tried drivers so far: ${triedDriverIds.length}");

      // Update observable
      selectDriverUserFromDriver.value = selectedDriver;

      await AudioPlayerService.playSound(false);

      // Handle subscription deduction (only on first assignment)
      if (triedDriverIds.length == 1) {
        await _handleSubscriptionDeduction();
      }

      // Update order and driver info
      orderModel.notes = "";
      orderModel.driverID = selectedDriver.id;
      orderModel.driver = selectedDriver;
      orderModel.status = Constant.driverPending;

      selectedDriver.inProgressOrderID ??= [];
      selectedDriver.inProgressOrderID!.add(orderModel.id);

      // Save to Firebase
      await FireStoreUtils.updateOrder(orderModel);
      await FireStoreUtils.updateDriverUser(selectedDriver);
      await FireStoreUtils.restaurantVendorWalletSet(orderModel);

      // Notifications
      await AudioPlayerService.playSound(false);
      SendNotification.sendFcmMessage(
          Constant.driverAccepted, orderModel.author!.fcmToken ?? '', {});
      SendNotification.sendFcmMessage(
          Constant.newDeliveryOrder, selectedDriver.fcmToken ?? '', {});

      ShowToastDialog.closeLoader();

      // Start timer to check for driver acceptance
      _startDriverResponseTimer(orderModel, selectedDriver);
    } catch (e) {
      ShowToastDialog.closeLoader();
      debugPrint("Error in driver assignment: $e");
      ShowToastDialog.showToast("Failed to assign driver.".tr);
    }
  }

  // Timer to monitor driver response
  void _startDriverResponseTimer(
      OrderModel orderModel, UserModel assignedDriver) {
    // Cancel any existing timer
    _driverResponseTimer?.cancel();

    _driverResponseTimer = Timer(
      Duration(seconds: Constant.driverOrderAcceptRejectDuration),
      () async {
        debugPrint("=== DRIVER RESPONSE TIMEOUT ===");

        // Fetch latest order status from Firebase
        OrderModel? latestOrder =
            await FireStoreUtils.getOrderById(orderModel.id ?? '');

        if (latestOrder == null) {
          debugPrint("Order not found in database");
          return;
        }

        // Check if driver accepted (status changed from driverPending)
        if (latestOrder.status != Constant.driverPending) {
          debugPrint(
              "Driver accepted the order. Status: ${latestOrder.status}");
          triedDriverIds.clear();

          // Start arrival tracking timer when driver accepts
          // Using "Driver Accepted" as that's the actual status from Firebase
          if (latestOrder.status == "Driver Accepted") {
            debugPrint("=== STARTING ARRIVAL TIMER ===");
            debugPrint("Order ID: ${latestOrder.id}");
            debugPrint("Driver: ${latestOrder.driver?.fullName}");
            _startDriverArrivalTimer(latestOrder);
          } else {
            debugPrint(
                "⚠️ Unexpected status for arrival tracking: '${latestOrder.status}'");
          }
          return;
        }

        debugPrint("Driver ${assignedDriver.fullName} did not respond in time");

        // Remove order from driver's in-progress list
        assignedDriver.inProgressOrderID?.remove(orderModel.id);
        await FireStoreUtils.updateDriverUser(assignedDriver);

        // Show notification that we're reassigning
        ShowToastDialog.showToast(
            "Driver didn't respond. Assigning to next available driver...".tr);

        // Wait a moment before reassigning
        await Future.delayed(const Duration(seconds: 1));

        // Recursively assign to next closest driver
        ShowToastDialog.showLoader('Reassigning driver...'.tr);
        await assignDriverWithAutoReassignment(orderModel);
      },
    );
  }

  // Helper method to select closest driver with randomization
  UserModel _selectClosestDriver(
      List<UserModel> availableDrivers, String pickupLat, String pickupLng) {
    UserModel selectedDriver;

    if (pickupLat != "0.0" && pickupLng != "0.0") {
      List<Map<String, dynamic>> driversWithDistance = [];

      // Calculate distance for each driver
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
          driversWithDistance.add({'driver': driver, 'distance': distance});
        }
      }

      if (driversWithDistance.isNotEmpty) {
        // Sort by distance
        driversWithDistance
            .sort((a, b) => a['distance'].compareTo(b['distance']));

        double minDistance = driversWithDistance.first['distance'];
        double tolerance = 0.5;

        List<UserModel> closestDrivers = driversWithDistance
            .where((item) => item['distance'] <= minDistance + tolerance)
            .map<UserModel>((item) => item['driver'])
            .toList();

        // Randomly select from closest drivers
        closestDrivers.shuffle();
        selectedDriver = closestDrivers.first;

        debugPrint("Total available drivers: ${availableDrivers.length}");
        debugPrint("Drivers within tolerance: ${closestDrivers.length}");
        debugPrint(
            "Closest distance: ${minDistance.toStringAsFixed(2)} ${Constant.distanceType}");
        debugPrint("Selected driver: ${selectedDriver.fullName}");
      } else {
        // Fallback to random
        availableDrivers.shuffle();
        selectedDriver = availableDrivers.first;
        debugPrint(
            "Selected Driver (Random - no location data): ${selectedDriver.fullName}");
      }
    } else {
      // Fallback to random
      availableDrivers.shuffle();
      selectedDriver = availableDrivers.first;
      debugPrint(
          "Selected Driver (Random - no pickup location): ${selectedDriver.fullName}");
    }

    return selectedDriver;
  }

  // Helper method to handle subscription deduction
  Future<void> _handleSubscriptionDeduction() async {
    if ((Constant.isSubscriptionModelApplied == true ||
            Constant.adminCommission?.isEnabled == true) &&
        vendermodel.value.subscriptionPlan != null) {
      if (vendermodel.value.subscriptionTotalOrders != '-1' &&
          vendermodel.value.subscriptionTotalOrders != null) {
        vendermodel.value.subscriptionTotalOrders =
            (int.parse(vendermodel.value.subscriptionTotalOrders!) - 1)
                .toString();
        await FireStoreUtils.updateVendor(vendermodel.value);
      }
    }
  }

  // NEW: Get estimated arrival time for an order (for UI display)
  String getEstimatedArrivalTimeText(String orderId) {
    if (estimatedArrivalTimes.containsKey(orderId)) {
      int minutes = estimatedArrivalTimes[orderId]!;
      if (minutes < 60) {
        return "$minutes min";
      } else {
        int hours = minutes ~/ 60;
        int mins = minutes % 60;
        return mins > 0 ? "${hours}h ${mins}m" : "${hours}h";
      }
    }
    return "";
  }

  Future<void> reassignOrder(OrderModel rejectedOrder) async {
    try {
      ShowToastDialog.showLoader('Reassigning order...'.tr);

      // Cancel arrival timer for this order
      _cancelArrivalTimer(rejectedOrder.id ?? '');

      // Get available drivers (excluding those who already rejected this order)
      List<UserModel> availableDrivers =
          driverUserListFromDriver.where((driver) {
        // Driver must be available (no orders in progress)
        bool isAvailable = driver.inProgressOrderID?.isEmpty ?? true;

        // Driver must not have rejected this order before
        List<String> rejectedDriverIds =
            rejectedOrder.rejectedByDrivers?.cast<String>() ?? [];
        bool hasNotRejected = !rejectedDriverIds.contains(driver.id);

        return isAvailable && hasNotRejected;
      }).toList();

      if (availableDrivers.isEmpty) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "No available drivers found for reassignment. Order marked as unassigned."
                .tr);

        // Mark order as unassigned if no drivers available
        rejectedOrder.status = Constant.orderAccepted;
        rejectedOrder.driverID = null;
        rejectedOrder.driver = null;
        await FireStoreUtils.updateOrder(rejectedOrder);
        await getOrder(); // Refresh order list
        return;
      }

      // Get restaurant/pickup location from orderModel
      String pickupLat = rejectedOrder.vendor?.latitude?.toString() ?? "0.0";
      String pickupLng = rejectedOrder.vendor?.longitude?.toString() ?? "0.0";

      UserModel selectedDriver =
          _selectClosestDriver(availableDrivers, pickupLat, pickupLng);

      debugPrint("=== ORDER REASSIGNMENT ===");
      debugPrint("Order ID: ${rejectedOrder.id}");
      debugPrint(
          "Rejected by: ${rejectedOrder.rejectedByDrivers?.length ?? 0} drivers");
      debugPrint("Available drivers: ${availableDrivers.length}");
      debugPrint("Reassigned to: ${selectedDriver.fullName}");

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
          Constant.newDeliveryOrder, selectedDriver.fcmToken ?? '', {});

      // Refresh the order list
      await getOrder();

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Order successfully reassigned".tr);
    } catch (e) {
      ShowToastDialog.closeLoader();
      debugPrint("Error reassigning order: $e");
      ShowToastDialog.showToast(
          "Failed to reassign order. Please try again.".tr);
    }
  }
}
