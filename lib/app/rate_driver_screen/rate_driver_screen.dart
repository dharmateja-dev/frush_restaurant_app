import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/controller/rate_driver_controller.dart';
import 'package:restaurant/themes/app_them_data.dart';
import 'package:restaurant/themes/responsive.dart';
import 'package:restaurant/utils/dark_theme_provider.dart';
import 'package:restaurant/utils/network_image_widget.dart';
import 'package:restaurant/widget/rating_star_widget.dart';

class RateDriverScreen extends StatelessWidget {
  const RateDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: RateDriverController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppThemeData.surfaceDark
              : AppThemeData.surface,
          appBar: AppBar(
            backgroundColor: AppThemeData.secondary300,
            centerTitle: false,
            titleSpacing: 0,
            iconTheme:
                const IconThemeData(color: AppThemeData.grey50, size: 20),
            title: Text(
              "Rate Driver".tr,
              style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey50
                    : AppThemeData.grey900,
                fontSize: 18,
                fontFamily: AppThemeData.medium,
              ),
            ),
          ),
          body: controller.isLoading.value
              ? Constant.loader()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Driver Profile Card
                        Container(
                          width: Responsive.width(100, context),
                          decoration: ShapeDecoration(
                            color: themeChange.getThem()
                                ? AppThemeData.grey900
                                : AppThemeData.grey50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Rate for text
                                Text(
                                  "Rate for".tr,
                                  style: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey400
                                        : AppThemeData.grey500,
                                    fontSize: 16,
                                    fontFamily: AppThemeData.medium,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Driver Name
                                Text(
                                  "${controller.driverModel.value.firstName ?? ''} ${controller.driverModel.value.lastName ?? ''}"
                                      .trim(),
                                  style: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey100
                                        : AppThemeData.grey800,
                                    fontSize: 22,
                                    fontFamily: AppThemeData.semiBold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Driver Profile Picture
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: NetworkImageWidget(
                                    imageUrl: controller.driverModel.value
                                            .profilePictureURL ??
                                        '',
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Rating Stars
                                Center(
                                  child: RatingStarWidget(
                                    initialRating: controller.rating.value,
                                    itemCount: 5,
                                    itemSize: 40,
                                    itemPadding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    onRatingUpdate: (rating) {
                                      controller.updateRating(rating);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Rating label
                                Obx(() => Text(
                                      _getRatingLabel(controller.rating.value),
                                      style: TextStyle(
                                        color: AppThemeData.secondary300,
                                        fontSize: 16,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    )),
                                const SizedBox(height: 24),

                                // Comment TextField
                                TextField(
                                  controller: controller.commentController,
                                  maxLines: 4,
                                  style: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey50
                                        : AppThemeData.grey900,
                                    fontSize: 14,
                                    fontFamily: AppThemeData.regular,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Add a comment (optional)'.tr,
                                    hintStyle: TextStyle(
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey600
                                          : AppThemeData.grey400,
                                      fontSize: 14,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppThemeData.secondary300,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: controller.isSubmitting.value
                                ? null
                                : () async {
                                    bool success =
                                        await controller.submitRating();
                                    if (success) {
                                      Get.back();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemeData.secondary300,
                              disabledBackgroundColor: AppThemeData.grey400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isSubmitting.value
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    controller.hasExistingRating.value
                                        ? 'Update Rating'.tr
                                        : 'Submit Rating'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: AppThemeData.semiBold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  String _getRatingLabel(double rating) {
    if (rating <= 0) return '';
    if (rating <= 1) return 'Poor'.tr;
    if (rating <= 2) return 'Fair'.tr;
    if (rating <= 3) return 'Good'.tr;
    if (rating <= 4) return 'Very Good'.tr;
    return 'Excellent'.tr;
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
