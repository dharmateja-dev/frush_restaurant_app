import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/constant/show_toast_dialog.dart';
import 'package:restaurant/models/user_model.dart';
import 'package:restaurant/models/vendor_category_model.dart';
import 'package:restaurant/models/vendor_model.dart';
import 'package:restaurant/models/zone_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';
import 'package:restaurant/widget/geoflutterfire/src/geoflutterfire.dart';

class AddRestaurantController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool isAddressEnable = false.obs;
  RxBool isEnableDeliverySettings = false.obs;
  final myKey1 = GlobalKey<DropdownSearchState<VendorCategoryModel>>();

  Rx<TextEditingController> restaurantNameController =
      TextEditingController().obs;
  Rx<TextEditingController> restaurantDescriptionController =
      TextEditingController().obs;
  Rx<TextEditingController> mobileNumberController =
      TextEditingController().obs;
  Rx<TextEditingController> countryCodeEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> addressController = TextEditingController().obs;

  Rx<TextEditingController> chargePerKmController = TextEditingController().obs;
  Rx<TextEditingController> minDeliveryChargesController =
      TextEditingController().obs;
  Rx<TextEditingController> minDeliveryChargesWithinKMController =
      TextEditingController().obs;

  LatLng? selectedLocation;

  RxList images = <dynamic>[].obs;

  RxList<VendorCategoryModel> vendorCategoryList = <VendorCategoryModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;

  // Rx<VendorCategoryModel> selectedCategory = VendorCategoryModel().obs;
  RxList selectedService = [].obs;

  RxList<VendorCategoryModel> selectedCategories = <VendorCategoryModel>[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getRestaurant();
    super.onInit();
  }

  Rx<UserModel> userModel = UserModel().obs;
  Rx<VendorModel> vendorModel = VendorModel().obs;
  Rx<DeliveryCharge> deliveryChargeModel = DeliveryCharge().obs;
  RxBool isSelfDelivery = false.obs;

  getRestaurant() async {
    try {
      // Load user profile
      await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
          .then((model) {
        if (model != null) {
          userModel.value = model;
          print('👤 User profile loaded');
        }
      });

      // Load vendor categories
      await FireStoreUtils.getVendorCategoryById().then((value) {
        if (value != null) {
          vendorCategoryList.value = value;
          print('📂 Vendor categories loaded: ${value.length}');
        }
      });

      // Load zones
      await FireStoreUtils.getZone().then((value) {
        if (value != null) {
          zoneList.value = value;
          print('🗺️ Zones loaded: ${value.length}');
        }
      });

      // Load vendor data if exists
      if (Constant.userModel?.vendorID != null &&
          Constant.userModel?.vendorID?.isNotEmpty == true) {
        print('🏪 Loading vendor data for ID: ${Constant.userModel!.vendorID}');

        await FireStoreUtils.getVendorById(
                Constant.userModel!.vendorID.toString())
            .then((value) {
          if (value != null) {
            print('✅ Vendor data loaded successfully');
            vendorModel.value = value;

            // Load basic vendor info
            restaurantNameController.value.text = vendorModel.value.title ?? '';
            restaurantDescriptionController.value.text =
                vendorModel.value.description ?? '';
            mobileNumberController.value.text =
                vendorModel.value.phonenumber ?? '';
            addressController.value.text = vendorModel.value.location ?? '';
            isSelfDelivery.value = vendorModel.value.isSelfDelivery ?? false;

            print('📍 Vendor basic info loaded:');
            print('  - Name: ${vendorModel.value.title}');
            print(
                '  - Has delivery charge: ${vendorModel.value.deliveryCharge != null}');

            if (vendorModel.value.deliveryCharge != null) {
              print('💰 Vendor delivery charges:');
              print(
                  '  - Per KM: ${vendorModel.value.deliveryCharge!.deliveryChargesPerKm}');
              print(
                  '  - Min charges: ${vendorModel.value.deliveryCharge!.minimumDeliveryCharges}');
              print(
                  '  - Min within KM: ${vendorModel.value.deliveryCharge!.minimumDeliveryChargesWithinKm}');
            }

            if (addressController.value.text.isNotEmpty) {
              isAddressEnable.value = true;
            }

            if (vendorModel.value.latitude != null &&
                vendorModel.value.longitude != null) {
              selectedLocation = LatLng(
                  vendorModel.value.latitude!, vendorModel.value.longitude!);
            }

            // Load images
            if (vendorModel.value.photos != null) {
              images.clear();
              for (var element in vendorModel.value.photos!) {
                images.add(element);
              }
            }

            // Load selected zone
            for (var element in zoneList) {
              if (element.id == vendorModel.value.zoneId) {
                selectedZone.value = element;
                break;
              }
            }

            // Load selected categories
            if (vendorModel.value.categoryID != null &&
                vendorModel.value.categoryID!.isNotEmpty) {
              selectedCategories.value = vendorCategoryList
                  .where((category) =>
                      vendorModel.value.categoryID!.contains(category.id))
                  .toList();
            }

            // Load filters
            if (vendorModel.value.filters != null) {
              selectedService.clear();
              vendorModel.value.filters!.toJson().forEach((key, value) {
                if (value.toString().contains("Yes")) {
                  selectedService.add(key);
                }
              });
            }
          } else {
            print('❌ Vendor data is null');
          }
        });
      } else {
        print('🆕 No existing vendor ID found - creating new vendor');
      }

      await FireStoreUtils.getDelivery().then((value) {
        if (value != null) {
          print('✅ Delivery charge settings loaded');
          deliveryChargeModel.value = value;

          // Get the global setting for vendor modification
          bool globalCanModify =
              deliveryChargeModel.value.vendorCanModify ?? false;

          // Check if vendor has existing custom delivery charges
          bool hasCustomCharges = vendorModel.value.id != null &&
              vendorModel.value.deliveryCharge != null;

          // Allow modification if:
          // 1. Global setting allows it, OR
          // 2. Vendor already has custom charges (grandfather existing settings)
          bool canModify = globalCanModify || hasCustomCharges;

          print('🔧 Global vendor can modify: $globalCanModify');
          print('🏪 Vendor has custom charges: $hasCustomCharges');
          print('✅ Final can modify decision: $canModify');

          // Set the switch state
          isEnableDeliverySettings.value = canModify;

          // Load the appropriate delivery charges
          if (hasCustomCharges) {
            // Use vendor's custom delivery charges
            var vendorDelivery = vendorModel.value.deliveryCharge!;
            chargePerKmController.value.text =
                vendorDelivery.deliveryChargesPerKm?.toString() ?? '0';
            minDeliveryChargesController.value.text =
                vendorDelivery.minimumDeliveryCharges?.toString() ?? '0';
            minDeliveryChargesWithinKMController.value.text =
                vendorDelivery.minimumDeliveryChargesWithinKm?.toString() ??
                    '0';

            print('💰 Loaded vendor custom delivery charges:');
            print('  - Per KM: ${chargePerKmController.value.text}');
            print(
                '  - Min charges: ${minDeliveryChargesController.value.text}');
            print(
                '  - Min within KM: ${minDeliveryChargesWithinKMController.value.text}');
          } else {
            // Use default delivery charges
            chargePerKmController.value.text =
                deliveryChargeModel.value.deliveryChargesPerKm?.toString() ??
                    '0';
            minDeliveryChargesController.value.text =
                deliveryChargeModel.value.minimumDeliveryCharges?.toString() ??
                    '0';
            minDeliveryChargesWithinKMController.value.text =
                deliveryChargeModel.value.minimumDeliveryChargesWithinKm
                        ?.toString() ??
                    '0';

            print('🏢 Loaded default delivery charges:');
            print('  - Per KM: ${chargePerKmController.value.text}');
            print(
                '  - Min charges: ${minDeliveryChargesController.value.text}');
            print(
                '  - Min within KM: ${minDeliveryChargesWithinKMController.value.text}');
          }

          // Force UI update
          update();
          print('🔄 UI update triggered');
        } else {
          print('❌ Delivery charge settings is null');
        }
      });
      print('✅ getRestaurant() completed successfully');
    } catch (e) {
      print('❌ Error in getRestaurant(): $e');
      print('Stack trace: ${StackTrace.current}');
    }

    isLoading.value = false;
    print('🏁 Loading completed');
  }

  // Add this method to manually refresh delivery settings
  Future<void> refreshDeliverySettings() async {
    print('🔄 Refreshing delivery settings...');

    try {
      if (vendorModel.value.id != null) {
        var updatedVendor =
            await FireStoreUtils.getVendorById(vendorModel.value.id!);
        if (updatedVendor != null) {
          vendorModel.value = updatedVendor;

          if (updatedVendor.deliveryCharge != null) {
            chargePerKmController.value.text = updatedVendor
                    .deliveryCharge!.deliveryChargesPerKm
                    ?.toString() ??
                '0';
            minDeliveryChargesController.value.text = updatedVendor
                    .deliveryCharge!.minimumDeliveryCharges
                    ?.toString() ??
                '0';
            minDeliveryChargesWithinKMController.value.text = updatedVendor
                    .deliveryCharge!.minimumDeliveryChargesWithinKm
                    ?.toString() ??
                '0';

            print('✅ Delivery settings refreshed from database');

            update();
          }
        }
      }
    } catch (e) {
      print('❌ Error refreshing delivery settings: $e');
    }
  }

  /// Validates delivery charge values are within realistic limits
  bool _validateDeliveryCharges() {
    const maxDeliveryCharge = 99999.99;

    try {
      double chargePerKm = double.parse(chargePerKmController.value.text.isEmpty
          ? '0'
          : chargePerKmController.value.text);
      double minCharges = double.parse(
          minDeliveryChargesController.value.text.isEmpty
              ? '0'
              : minDeliveryChargesController.value.text);
      double minWithinKm = double.parse(
          minDeliveryChargesWithinKMController.value.text.isEmpty
              ? '0'
              : minDeliveryChargesWithinKMController.value.text);

      if (chargePerKm < 0 || chargePerKm > maxDeliveryCharge) {
        ShowToastDialog.showToast(
            "Delivery charge per KM cannot exceed $maxDeliveryCharge".tr);
        return false;
      }

      if (minCharges < 0 || minCharges > maxDeliveryCharge) {
        ShowToastDialog.showToast(
            "Min delivery charges cannot exceed $maxDeliveryCharge".tr);
        return false;
      }

      if (minWithinKm < 0 || minWithinKm > maxDeliveryCharge) {
        ShowToastDialog.showToast(
            "Min delivery charges within distance cannot exceed $maxDeliveryCharge"
                .tr);
        return false;
      }

      return true;
    } catch (e) {
      ShowToastDialog.showToast("Invalid delivery charge values".tr);
      return false;
    }
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    // Phone number must be between 7-15 digits (international standard)
    return phoneNumber.length >= 7 && phoneNumber.length <= 15;
  }

  saveDetails() async {
    if (restaurantNameController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter restaurant name".tr);
    } else if (restaurantDescriptionController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter Description".tr);
    } else if (mobileNumberController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number".tr);
    } else if (!_isValidPhoneNumber(mobileNumberController.value.text)) {
      ShowToastDialog.showToast(
          "Please enter a valid phone number (minimum 7 digits)".tr);
    } else if (addressController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter address".tr);
    } else if (selectedZone.value.id == null) {
      ShowToastDialog.showToast("Please select zone".tr);
    } else if (selectedCategories.isEmpty) {
      ShowToastDialog.showToast("Please select category".tr);
    } else if (!_validateDeliveryCharges()) {
      // Validation message already shown by _validateDeliveryCharges()
      return;
    } else {
      if (Constant.isPointInPolygon(
          selectedLocation!, selectedZone.value.area!)) {
        ShowToastDialog.showLoader("Please wait".tr);
        filter();
        DeliveryCharge deliveryChargeModel = DeliveryCharge(
            vendorCanModify: true,
            deliveryChargesPerKm: num.parse(chargePerKmController.value.text),
            minimumDeliveryCharges:
                num.parse(minDeliveryChargesController.value.text),
            minimumDeliveryChargesWithinKm:
                num.parse(minDeliveryChargesWithinKMController.value.text));

        if (vendorModel.value.id == null) {
          vendorModel.value = VendorModel();
          vendorModel.value.createdAt = Timestamp.now();
        }
        for (int i = 0; i < images.length; i++) {
          if (images[i].runtimeType == XFile) {
            String url = await Constant.uploadUserImageToFireStorage(
              File(images[i].path),
              "profileImage/${FireStoreUtils.getCurrentUid()}",
              File(images[i].path).path.split('/').last,
            );
            images.removeAt(i);
            images.insert(i, url);
          }
        }

        vendorModel.value.id = Constant.userModel?.vendorID;
        vendorModel.value.author = Constant.userModel!.id;
        vendorModel.value.authorName = Constant.userModel!.firstName;
        vendorModel.value.authorProfilePic =
            Constant.userModel!.profilePictureURL;

        vendorModel.value.categoryID =
            selectedCategories.map((e) => e.id ?? '').toList();
        vendorModel.value.categoryTitle =
            selectedCategories.map((e) => e.title ?? '').toList();
        vendorModel.value.g = G(
            geohash: Geoflutterfire()
                .point(
                    latitude: selectedLocation!.latitude,
                    longitude: selectedLocation!.longitude)
                .hash,
            geopoint: GeoPoint(
                selectedLocation!.latitude, selectedLocation!.longitude));
        vendorModel.value.description =
            restaurantDescriptionController.value.text;
        vendorModel.value.phonenumber = mobileNumberController.value.text;
        vendorModel.value.filters = Filters.fromJson(filters);
        vendorModel.value.location = addressController.value.text;
        vendorModel.value.latitude = selectedLocation!.latitude;
        vendorModel.value.longitude = selectedLocation!.longitude;
        vendorModel.value.photos = images;
        if (images.isNotEmpty) {
          vendorModel.value.photo = images.first;
        } else {
          vendorModel.value.photo = null;
        }

        vendorModel.value.deliveryCharge = deliveryChargeModel;
        vendorModel.value.title = restaurantNameController.value.text;
        vendorModel.value.zoneId = selectedZone.value.id;
        vendorModel.value.isSelfDelivery = isSelfDelivery.value;

        if (Constant.adminCommission!.isEnabled == true ||
            Constant.isSubscriptionModelApplied == true) {
          vendorModel.value.subscriptionPlanId =
              userModel.value.subscriptionPlanId;
          vendorModel.value.subscriptionPlan = userModel.value.subscriptionPlan;
          vendorModel.value.subscriptionExpiryDate =
              userModel.value.subscriptionExpiryDate;
          vendorModel.value.subscriptionTotalOrders =
              userModel.value.subscriptionPlan?.orderLimit;
        }

        if (Constant.userModel!.vendorID!.isNotEmpty) {
          await FireStoreUtils.updateVendor(vendorModel.value).then((value) {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
                "Restaurant details save successfully".tr);
          });
        } else {
          vendorModel.value.adminCommission = Constant.adminCommission;
          vendorModel.value.workingHours = [
            WorkingHours(
                day: 'Monday'.tr,
                timeslot: [Timeslot(from: '00:00', to: '23:59')]),
            WorkingHours(
                day: 'Tuesday'.tr,
                timeslot: [Timeslot(from: '00:00', to: '23:59')]),
            WorkingHours(
                day: 'Wednesday'.tr,
                timeslot: [Timeslot(from: '00:00', to: '23:59')]),
            WorkingHours(
                day: 'Thursday'.tr,
                timeslot: [Timeslot(from: '00:00', to: '23:59')]),
            WorkingHours(
                day: 'Friday'.tr,
                timeslot: [Timeslot(from: '00:00', to: '23:59')]),
            WorkingHours(
                day: 'Saturday'.tr,
                timeslot: [Timeslot(from: '00:00', to: '23:59')]),
            WorkingHours(
                day: 'Sunday'.tr,
                timeslot: [Timeslot(from: '00:00', to: '23:59')])
          ];

          await FireStoreUtils.firebaseCreateNewVendor(vendorModel.value)
              .then((value) {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
                "Restaurant details save successfully".tr);
          });
        }
      } else {
        ShowToastDialog.showToast(
            "The chosen area is outside the selected zone.".tr);
      }
    }
  }

  Map<String, dynamic> filters = {};

  filter() {
    if (selectedService.contains('Good for Breakfast')) {
      filters['Good for Breakfast'] = 'Yes';
    } else {
      filters['Good for Breakfast'] = 'No';
    }
    if (selectedService.contains('Good for Lunch')) {
      filters['Good for Lunch'] = 'Yes';
    } else {
      filters['Good for Lunch'] = 'No';
    }

    if (selectedService.contains('Good for Dinner')) {
      filters['Good for Dinner'] = 'Yes';
    } else {
      filters['Good for Dinner'] = 'No';
    }

    if (selectedService.contains('Takes Reservations')) {
      filters['Takes Reservations'] = 'Yes';
    } else {
      filters['Takes Reservations'] = 'No';
    }

    if (selectedService.contains('Vegetarian Friendly')) {
      filters['Vegetarian Friendly'] = 'Yes';
    } else {
      filters['Vegetarian Friendly'] = 'No';
    }

    if (selectedService.contains('Live Music')) {
      filters['Live Music'] = 'Yes';
    } else {
      filters['Live Music'] = 'No';
    }

    if (selectedService.contains('Outdoor Seating')) {
      filters['Outdoor Seating'] = 'Yes';
    } else {
      filters['Outdoor Seating'] = 'No';
    }

    if (selectedService.contains('Free Wi-Fi')) {
      filters['Free Wi-Fi'] = 'Yes';
    } else {
      filters['Free Wi-Fi'] = 'No';
    }
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      images.add(image);
      Get.back();
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick :".tr} \n $e");
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
