import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/constant/show_toast_dialog.dart';
import 'package:restaurant/models/vendor_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class WorkingHoursController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<WorkingHours> workingHours = <WorkingHours>[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getVendor();
    super.onInit();
  }

  Rx<VendorModel> vendorModel = VendorModel().obs;

  getVendor() async {
    await FireStoreUtils.getVendorById(Constant.userModel!.vendorID.toString())
        .then(
      (value) {
        if (value != null) {
          vendorModel.value = value;
          if (vendorModel.value.workingHours == null ||
              vendorModel.value.workingHours!.isEmpty) {
            workingHours.value = [
              WorkingHours(day: 'Monday'.tr, timeslot: []),
              WorkingHours(day: 'Tuesday'.tr, timeslot: []),
              WorkingHours(day: 'Wednesday'.tr, timeslot: []),
              WorkingHours(day: 'Thursday'.tr, timeslot: []),
              WorkingHours(day: 'Friday'.tr, timeslot: []),
              WorkingHours(day: 'Saturday'.tr, timeslot: []),
              WorkingHours(day: 'Sunday'.tr, timeslot: [])
            ];
          } else {
            workingHours.value = vendorModel.value.workingHours!;
          }
        }
      },
    );
    isLoading.value = false;
  }

  /// Validates that all time slots have valid start and end times
  /// Returns error message if validation fails, empty string if valid
  String _validateTimeSlots() {
    for (int dayIndex = 0; dayIndex < workingHours.length; dayIndex++) {
      final day = workingHours[dayIndex];
      final timeslots = day.timeslot ?? [];

      for (int slotIndex = 0; slotIndex < timeslots.length; slotIndex++) {
        final slot = timeslots[slotIndex];
        final from = slot.from?.trim() ?? '';
        final to = slot.to?.trim() ?? '';

        // Check if both times are provided
        if (from.isEmpty || to.isEmpty) {
          return 'Please enter valid time for all slots'.tr;
        }

        // Check if start and end times are the same (0 duration)
        if (from == to) {
          return 'Start and end time cannot be the same for ${day.day}. Please set a valid time duration.'
              .tr;
        }
      }
    }
    return '';
  }

  /// Validates that at least one day has working hours
  /// Returns error message if validation fails, empty string if valid
  String _validateAtLeastOneDay() {
    bool hasAnyWorkingHours = false;

    for (final day in workingHours) {
      if (day.timeslot != null && day.timeslot!.isNotEmpty) {
        hasAnyWorkingHours = true;
        break;
      }
    }

    if (!hasAnyWorkingHours) {
      return 'Please add working hours for at least one day.'.tr;
    }
    return '';
  }

  saveWorkingHours() async {
    // Validate time slots
    String timeSlotError = _validateTimeSlots();
    if (timeSlotError.isNotEmpty) {
      ShowToastDialog.showToast(timeSlotError);
      return;
    }

    // Validate at least one day has working hours
    String dayError = _validateAtLeastOneDay();
    if (dayError.isNotEmpty) {
      ShowToastDialog.showToast(dayError);
      return;
    }

    ShowToastDialog.showLoader("Please wait".tr);

    FocusScope.of(Get.context!).requestFocus(FocusNode()); //remove focus
    vendorModel.value.workingHours = workingHours;

    await FireStoreUtils.updateVendor(vendorModel.value).then((value) async {
      ShowToastDialog.showToast("Working hours update successfully".tr);
      ShowToastDialog.closeLoader();
    });
  }

  addValue(int index) {
    WorkingHours specialDiscountModel = workingHours[index];
    specialDiscountModel.timeslot!.add(Timeslot(from: '', to: ''));
    workingHours.removeAt(index);
    workingHours.insert(index, specialDiscountModel);
    update();
  }

  remove(int index, int timeSlotIndex) {
    WorkingHours specialDiscountModel = workingHours[index];
    specialDiscountModel.timeslot!.removeAt(timeSlotIndex);
    workingHours.removeAt(index);
    workingHours.insert(index, specialDiscountModel);
    update();
    update();
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
