import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/constant/show_toast_dialog.dart';
import 'package:restaurant/models/coupon_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class AddEditCouponController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<TextEditingController> titleController = TextEditingController().obs;
  Rx<TextEditingController> couponCodeController = TextEditingController().obs;
  Rx<TextEditingController> priceController = TextEditingController().obs;
  Rx<TextEditingController> selectDateController = TextEditingController().obs;
  RxBool isActive = true.obs;
  RxBool isPublic = true.obs;
  RxString selectCouponType = "Fix Price".obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  Rx<CouponModel> couponModel = CouponModel().obs;
  RxList images = <dynamic>[].obs;

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      couponModel.value = argumentData['couponModel'];
      titleController.value.text = couponModel.value.description.toString();
      couponCodeController.value.text = couponModel.value.code.toString();
      priceController.value.text = couponModel.value.discount.toString();
      selectDateController.value.text =
          Constant.timestampToDate(couponModel.value.expiresAt!);
      isActive.value = couponModel.value.isEnabled ?? false;
      isPublic.value = couponModel.value.isPublic ?? false;
      selectCouponType.value = couponModel.value.discountType == "Percentage" ||
              couponModel.value.discountType == "Percent"
          ? "Percentage"
          : couponModel.value.discountType.toString();
      if (couponModel.value.image != null ||
          couponModel.value.image!.isNotEmpty) {
        images.add(couponModel.value.image);
      }
    }
    isLoading.value = false;
  }

  String _sanitizeCouponCode(String code) {
    String sanitized = code.replaceAll(RegExp(r'\s+'), '');

    sanitized = sanitized.toUpperCase();
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '');
    return sanitized.trim();
  }

  bool _isValidCouponCodeFormat(String code) {
    // Check for spaces
    if (code.contains(' ')) {
      return false;
    }
    // Allow alphanumeric, hyphens, and underscores only
    return RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(code);
  }

  /// Checks if coupon code already exists (excluding current coupon if editing)
  Future<bool> _doesCouponCodeExist(String code) async {
    try {
      final query = await FireStoreUtils.fireStore
          .collection('coupons')
          .where('code', isEqualTo: code)
          .where('resturant_id',
              isEqualTo: Constant.userModel!.vendorID.toString())
          .get();

      // If editing, exclude the current coupon
      if (couponModel.value.id != null && couponModel.value.id!.isNotEmpty) {
        return query.docs.any((doc) => doc.id != couponModel.value.id);
      }

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking coupon uniqueness: $e');
      return false;
    }
  }

  /// Checks if coupon name/description already exists (excluding current coupon if editing)
  Future<bool> _doesCouponNameExist(String name) async {
    try {
      final query = await FireStoreUtils.fireStore
          .collection('coupons')
          .where('description', isEqualTo: name)
          .where('resturant_id',
              isEqualTo: Constant.userModel!.vendorID.toString())
          .get();

      // If editing, exclude the current coupon
      if (couponModel.value.id != null && couponModel.value.id!.isNotEmpty) {
        return query.docs.any((doc) => doc.id != couponModel.value.id);
      }

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking coupon name uniqueness: $e');
      return false;
    }
  }

  /// Validates expiry date is not in the past
  bool _isValidExpiryDate(String dateString) {
    try {
      DateTime expiryDate = DateFormat("MMM dd,yyyy").parse(dateString);
      DateTime now = DateTime.now();
      // Set time to end of day for fair comparison
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return expiryDate.isAfter(endOfDay);
    } catch (e) {
      print('Error parsing expiry date: $e');
      return false;
    }
  }

  saveCoupon() async {
    if (titleController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter coupon name".tr);
    } else if (couponCodeController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter coupon code".tr);
    } else if (!_isValidCouponCodeFormat(
        couponCodeController.value.text.trim())) {
      ShowToastDialog.showToast(
          "Coupon code cannot contain spaces. Use only letters, numbers, hyphens, and underscores."
              .tr);
    } else if (selectDateController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please select expire date".tr);
    } else if (!_isValidExpiryDate(selectDateController.value.text)) {
      ShowToastDialog.showToast(
          "Expiry date must be today or in the future. Please select a valid date."
              .tr);
    } else if (priceController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter discount value".tr);
    } else {
      // Check for duplicate coupon name
      ShowToastDialog.showLoader("Checking coupon name...".tr);
      bool nameExists =
          await _doesCouponNameExist(titleController.value.text.trim());

      if (nameExists) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "A coupon with this name already exists. Please use a different name."
                .tr);
        return;
      }

      // Check for duplicate coupon code
      ShowToastDialog.showLoader("Checking coupon code...".tr);
      bool codeExists = await _doesCouponCodeExist(
          _sanitizeCouponCode(couponCodeController.value.text));

      if (codeExists) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "This coupon code already exists. Please use a different code.".tr);
        return;
      }

      ShowToastDialog.showLoader("Please wait...".tr);
      for (int i = 0; i < images.length; i++) {
        if (images[i].runtimeType == XFile) {
          String url = await Constant.uploadUserImageToFireStorage(
            File(images[i].path),
            "profileImage/${DateTime.now().toIso8601String()}",
            File(images[i].path).path.split('/').last,
          );
          images.removeAt(i);
          images.insert(i, url);
        }
      }

      couponModel.value.id = couponModel.value.id ?? Constant.getUuid();
      couponModel.value.code =
          _sanitizeCouponCode(couponCodeController.value.text);
      couponModel.value.discount = priceController.value.text.trim();
      couponModel.value.discountType = selectCouponType.value;
      couponModel.value.image = images.isEmpty ? "" : images.first;
      couponModel.value.expiresAt = Timestamp.fromDate(
          DateFormat("MMM dd,yyyy").parse(selectDateController.value.text));
      couponModel.value.isEnabled = isActive.value;
      couponModel.value.isPublic = isPublic.value;
      couponModel.value.resturantId = Constant.userModel!.vendorID.toString();
      couponModel.value.description = titleController.value.text;
      await FireStoreUtils.setCoupon(couponModel.value).then(
        (value) {
          ShowToastDialog.closeLoader();
          Get.back(result: true);
        },
      );
    }
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      images.clear();
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
