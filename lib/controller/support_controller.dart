import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/constant/collection_name.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class SupportController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> feedbackController = TextEditingController().obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getContactUsInformation();
    super.onInit();
  }

  RxString email = "".obs;
  RxString phone = "".obs;
  RxString address = "".obs;
  RxString subject = "".obs;

  getContactUsInformation() async {
    await FireStoreUtils.fireStore
        .collection(CollectionName.settings)
        .doc("ContactUs")
        .get()
        .then((value) {
      if (value.exists) {
        email.value = value.data()!["Email"];
        phone.value = value.data()!["Phone"];
        address.value = value.data()!["Address"];
        subject.value = value.data()!["Subject"];
        isLoading.value = false;
      }
    });
  }
}
