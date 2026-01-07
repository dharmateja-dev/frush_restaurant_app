import 'package:get/get.dart';
import 'package:restaurant/models/order_model.dart';
import 'package:restaurant/models/product_model.dart';
import 'package:restaurant/models/rating_model.dart';
import 'package:restaurant/models/review_attribute_model.dart';
import 'package:restaurant/models/vendor_category_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class ProductRatingViewController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;
  RxString productId = "".obs;
  Rx<RatingModel> ratingModel = RatingModel().obs;
  Rx<ProductModel> productModel = ProductModel().obs;
  Rx<VendorCategoryModel> vendorCategoryModel = VendorCategoryModel().obs;

  RxList<ReviewAttributeModel> reviewAttributeList =
      <ReviewAttributeModel>[].obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
      productId.value = argumentData['productId'];

      await FireStoreUtils.getOrderReviewsByID(
              orderModel.value.id.toString(), productId.value)
          .then(
        (value) {
          if (value != null) {
            ratingModel.value = value;
          }
        },
      );

      await FireStoreUtils.getProductById(productId.value.split('~').first)
          .then(
        (value) {
          if (value != null) {
            productModel.value = value;
          }
        },
      );

      await FireStoreUtils.getVendorCategoryByCategoryId(
              productModel.value.categoryID.toString())
          .then((value) async {
        if (value != null) {
          vendorCategoryModel.value = value;
          for (var element in vendorCategoryModel.value.reviewAttributes!) {
            await FireStoreUtils.getVendorReviewAttribute(element)
                .then((value) {
              reviewAttributeList.add(value!);
            });
          }
        }
      });
    }

    isLoading.value = false;
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
