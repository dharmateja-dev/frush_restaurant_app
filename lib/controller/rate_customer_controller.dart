import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/models/order_model.dart';
import 'package:restaurant/models/rating_model.dart';
import 'package:restaurant/models/user_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';
import 'package:uuid/uuid.dart';

class RateCustomerController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool isSubmitting = false.obs;

  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<UserModel> customerModel = UserModel().obs;
  Rx<RatingModel> existingRating = RatingModel().obs;

  RxDouble rating = 0.0.obs;
  TextEditingController commentController = TextEditingController();

  RxBool hasExistingRating = false.obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];

      // Get customer info
      if (orderModel.value.authorID != null &&
          orderModel.value.authorID!.isNotEmpty) {
        await FireStoreUtils.getUserById(orderModel.value.authorID!)
            .then((value) {
          if (value != null) {
            customerModel.value = value;
          }
        });
      }

      // Check for existing rating
      await FireStoreUtils.getCustomerRatingByOrderId(
        orderModel.value.id.toString(),
        orderModel.value.authorID ?? '',
      ).then((value) {
        if (value != null) {
          existingRating.value = value;
          hasExistingRating.value = true;
          rating.value = value.rating ?? 0.0;
          commentController.text = value.comment ?? '';
        }
      });
    }

    isLoading.value = false;
  }

  void updateRating(double newRating) {
    rating.value = newRating;
  }

  Future<bool> submitRating() async {
    if (rating.value <= 0) {
      Get.snackbar(
        'Error'.tr,
        'Please select a rating'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    }

    isSubmitting.value = true;

    try {
      RatingModel ratingModel = RatingModel(
        id: hasExistingRating.value
            ? existingRating.value.id
            : const Uuid().v4(),
        rating: rating.value,
        comment: commentController.text.trim(),
        orderId: orderModel.value.id,
        customerId: orderModel.value.authorID,
        vendorId: orderModel.value.vendorID,
        uname: Constant.userModel?.firstName ?? '',
        profile: Constant.userModel?.profilePictureURL ?? '',
        createdAt: hasExistingRating.value
            ? existingRating.value.createdAt
            : Timestamp.now(),
      );

      bool success = await FireStoreUtils.saveCustomerRating(ratingModel);

      if (success) {
        // Update customer's average rating
        await FireStoreUtils.updateCustomerAverageRating(
            orderModel.value.authorID!);

        Get.snackbar(
          'Success'.tr,
          'Rating submitted successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );

        isSubmitting.value = false;
        return true;
      } else {
        Get.snackbar(
          'Error'.tr,
          'Failed to submit rating. Please try again.'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        isSubmitting.value = false;
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'An error occurred. Please try again.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      isSubmitting.value = false;
      return false;
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
* Author: Kasa Pogu Dharma Teja
*******************************************************************************************/
