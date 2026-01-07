import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/constant/show_toast_dialog.dart';
import 'package:restaurant/models/vendor_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class SpecialDiscountController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<SpecialDiscount> specialDiscount = <SpecialDiscount>[].obs;
  RxBool hasUnsavedChanges = false.obs;
  late List<SpecialDiscount> originalDiscount;

  List<String> discountType =
      ['Dine-In Discount'.tr, 'Delivery Discount'.tr].obs;
  List<String> type = [Constant.currencyModel!.symbol!, '%'];

  @override
  void onInit() {
    getVendor();
    super.onInit();
  }

  Rx<VendorModel> vendorModel = VendorModel().obs;
  RxBool isSpecialSwitched = false.obs;

  getVendor() async {
    await FireStoreUtils.getVendorById(Constant.userModel!.vendorID.toString())
        .then(
      (value) {
        if (value != null) {
          vendorModel.value = value;

          if (vendorModel.value.specialDiscount == null ||
              vendorModel.value.specialDiscount!.isEmpty) {
            specialDiscount.value = [
              SpecialDiscount(day: 'Monday'.tr, timeslot: []),
              SpecialDiscount(day: 'Tuesday'.tr, timeslot: []),
              SpecialDiscount(day: 'Wednesday'.tr, timeslot: []),
              SpecialDiscount(day: 'Thursday'.tr, timeslot: []),
              SpecialDiscount(day: 'Friday'.tr, timeslot: []),
              SpecialDiscount(day: 'Saturday'.tr, timeslot: []),
              SpecialDiscount(day: 'Sunday'.tr, timeslot: []),
            ];
          } else {
            specialDiscount.value = vendorModel.value.specialDiscount!;
          }

          isSpecialSwitched.value =
              vendorModel.value.specialDiscountEnable ?? false;

          _storeOriginalState();
          hasUnsavedChanges.value = false;
        }
      },
    );

    isLoading.value = false;
  }

  /// Store original state for change detection
  void _storeOriginalState() {
    originalDiscount = specialDiscount.map((discount) {
      return SpecialDiscount(
        day: discount.day,
        timeslot: discount.timeslot?.map((slot) {
          return SpecialDiscountTimeslot(
            from: slot.from,
            to: slot.to,
            discount: slot.discount,
            type: slot.type,
            discountType: slot.discountType,
          );
        }).toList(),
      );
    }).toList();
  }

  /// Validates time slots for overlaps AND identical start/end times
  String _validateNoOverlaps() {
    for (var day in specialDiscount) {
      if (day.timeslot == null || day.timeslot!.isEmpty) continue;

      for (int i = 0; i < day.timeslot!.length; i++) {
        final slot = day.timeslot![i];

        // ✅ NEW: Reject identical start & end inside the slot itself
        if (slot.from != null &&
            slot.to != null &&
            slot.from!.isNotEmpty &&
            slot.to!.isNotEmpty) {
          try {
            final start = DateFormat("HH:mm").parse(slot.from!);
            final end = DateFormat("HH:mm").parse(slot.to!);

            if (start.isAtSameMomentAs(end)) {
              return 'Start and End time cannot be identical on ${day.day}.'.tr;
            }
          } catch (e) {}
        }

        // Existing pair overlap check
        for (int j = i + 1; j < day.timeslot!.length; j++) {
          final slot2 = day.timeslot![j];

          if (slot2.from!.isEmpty || slot2.to!.isEmpty) continue;

          try {
            final time1Start = DateFormat("HH:mm").parse(slot.from.toString());
            final time1End = DateFormat("HH:mm").parse(slot.to.toString());
            final time2Start = DateFormat("HH:mm").parse(slot2.from.toString());
            final time2End = DateFormat("HH:mm").parse(slot2.to.toString());

            if (time1Start.isBefore(time2End) &&
                time2Start.isBefore(time1End)) {
              return 'Time slots overlap on ${day.day}. Please set non-overlapping times.'
                  .tr;
            }
          } catch (e) {}
        }
      }
    }
    return '';
  }

  saveSpecialOffer() async {
    // Validate no overlapping or invalid time slots
    String overlapError = _validateNoOverlaps();
    if (overlapError.isNotEmpty) {
      ShowToastDialog.showToast(overlapError);
      return;
    }

    ShowToastDialog.showLoader("Please wait".tr);

    FocusScope.of(Get.context!).requestFocus(FocusNode());
    vendorModel.value.specialDiscount = specialDiscount;
    vendorModel.value.specialDiscountEnable = isSpecialSwitched.value;

    await FireStoreUtils.updateVendor(vendorModel.value).then((value) async {
      ShowToastDialog.showToast("Special discount update successfully".tr);
      ShowToastDialog.closeLoader();
      hasUnsavedChanges.value = false;
      _storeOriginalState();
    });
  }

  addValue(int index) {
    SpecialDiscount specialDiscountModel = specialDiscount[index];
    specialDiscountModel.timeslot!.add(SpecialDiscountTimeslot(
      from: '',
      to: '',
      discount: '',
      type: 'percentage',
      discountType: 'delivery',
    ));
    specialDiscount[index] = specialDiscountModel;
    hasUnsavedChanges.value = true;
    update();
  }

  changeValue(int index, int indexTimeSlot, String value) {
    SpecialDiscount specialDiscountModel = specialDiscount[index];
    List<SpecialDiscountTimeslot>? list = specialDiscountModel.timeslot!;

    SpecialDiscountTimeslot discountTimeslot = list[indexTimeSlot];
    discountTimeslot.type = value;

    list[indexTimeSlot] = discountTimeslot;
    specialDiscountModel.timeslot = list;

    specialDiscount[index] = specialDiscountModel;
    hasUnsavedChanges.value = true;
    update();
  }

  remove(int index, int timeSlotIndex) {
    SpecialDiscount specialDiscountModel = specialDiscount[index];
    specialDiscountModel.timeslot!.removeAt(timeSlotIndex);
    specialDiscount[index] = specialDiscountModel;
    hasUnsavedChanges.value = true;
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
* OR OTHERWISE, ARISING FROM, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Aman Bhandari 
*******************************************************************************************/
