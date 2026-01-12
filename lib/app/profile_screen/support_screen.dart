import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/constant/show_toast_dialog.dart';
import 'package:restaurant/controller/support_controller.dart';
import 'package:restaurant/themes/app_them_data.dart';
import 'package:restaurant/themes/button_them.dart';
import 'package:restaurant/themes/responsive.dart';
import 'package:restaurant/themes/text_field_them.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GetX<SupportController>(
      init: SupportController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppThemeData.primary300,
            title: Text(
              "Support".tr,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          backgroundColor: AppThemeData.primary300,
          body: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                  ),
                  child: controller.isLoading.value
                      ? Constant.loader()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: DefaultTabController(
                              length: 2,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Support".tr,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      "Let us know your issue & feedback".tr,
                                      style: GoogleFonts.poppins(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TabBar(
                                      indicatorWeight: 3,
                                      indicatorColor: AppThemeData.primary300,
                                      labelColor: AppThemeData.primary300,
                                      unselectedLabelColor:
                                          const Color.fromARGB(255, 15, 14, 14),
                                      tabs: [
                                        Tab(
                                          child: Text("Call Us".tr,
                                              style: GoogleFonts.poppins()),
                                        ),
                                        Tab(
                                          child: Text("Email Us".tr,
                                              style: GoogleFonts.poppins()),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () {
                                                    Constant.makePhoneCall(
                                                        controller.phone.value);
                                                  },
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.call),
                                                      const SizedBox(width: 20),
                                                      Text(
                                                        controller.phone.value,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                const Divider(),
                                                const SizedBox(height: 12),
                                                InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    final Email email = Email(
                                                      recipients: const [
                                                        'support@frush.com'
                                                      ],
                                                      subject:
                                                          'Support Request - Frush',
                                                      body: '',
                                                    );
                                                    await FlutterEmailSender
                                                        .send(email);
                                                  },
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.email),
                                                      const SizedBox(width: 20),
                                                      Text(
                                                        'support@frush.com',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: AppThemeData
                                                              .primary300,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                const Divider(),
                                                const SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                        Icons.location_on),
                                                    const SizedBox(width: 20),
                                                    Expanded(
                                                      child: Text(
                                                        controller
                                                            .address.value,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Write us".tr,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Describe your issue".tr,
                                                    style: GoogleFonts.poppins(
                                                      color: isDark
                                                          ? Colors.white70
                                                          : Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  TextFieldThem.buildTextFiled(
                                                    context,
                                                    hintText: 'Email'.tr,
                                                    controller: controller
                                                        .emailController.value,
                                                  ),
                                                  const SizedBox(height: 20),
                                                  TextFieldThem.buildTextFiled(
                                                    context,
                                                    hintText:
                                                        'Describe your issue and feedback'
                                                            .tr,
                                                    controller: controller
                                                        .feedbackController
                                                        .value,
                                                    maxLine: 5,
                                                  ),
                                                  const SizedBox(height: 20),
                                                  ButtonThem.buildButton(
                                                    context,
                                                    title: "Submit".tr,
                                                    onPress: () async {
                                                      if (controller
                                                          .emailController
                                                          .value
                                                          .text
                                                          .isEmpty) {
                                                        ShowToastDialog
                                                            .showToast(
                                                          "Please enter email"
                                                              .tr,
                                                        );
                                                        return;
                                                      }

                                                      if (controller
                                                          .feedbackController
                                                          .value
                                                          .text
                                                          .isEmpty) {
                                                        ShowToastDialog
                                                            .showToast(
                                                          "Please enter feedback"
                                                              .tr,
                                                        );
                                                        return;
                                                      }

                                                      try {
                                                        final Email email =
                                                            Email(
                                                          body: controller
                                                              .feedbackController
                                                              .value
                                                              .text,
                                                          subject:
                                                              'Support Request - frush',
                                                          recipients: const [
                                                            'support@frush.com'
                                                          ],
                                                          cc: [
                                                            controller
                                                                .emailController
                                                                .value
                                                                .text
                                                          ],
                                                          isHTML: false,
                                                        );

                                                        await FlutterEmailSender
                                                            .send(email);

                                                        controller
                                                            .emailController
                                                            .value
                                                            .clear();
                                                        controller
                                                            .feedbackController
                                                            .value
                                                            .clear();

                                                        ShowToastDialog
                                                            .showToast(
                                                          "Support request sent successfully"
                                                              .tr,
                                                        );
                                                      } catch (e) {
                                                        ShowToastDialog
                                                            .showToast(
                                                          "Failed to send email. Please try again."
                                                              .tr,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
