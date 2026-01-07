import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Support".tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 📞 Contact Support
            ListTile(
              leading: const Icon(Icons.headset_mic),
              title: Text("Contact Support".tr),
              subtitle: Text("Talk to our support team".tr),
              onTap: () {
                // phone / whatsapp / email
              },
            ),

            const Divider(),

            /// ❓ FAQs
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text("FAQs".tr),
              subtitle: Text("Frequently asked questions".tr),
              onTap: () {
                // Navigate to FAQ page (optional)
              },
            ),

            const Divider(),

            /// 📨 Email Support
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text("Email Us".tr),
              subtitle: Text("support@yourapp.com".tr),
              onTap: () {
                // launch email intent
              },
            ),

          ],
        ),
      ),
    );
  }
}
