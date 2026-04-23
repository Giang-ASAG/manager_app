import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/views/screens/dashboard/dashboard_screen.dart';
import 'package:manager/views/screens/invoice/invoice_list_screen.dart';
import 'package:manager/views/widgets/app_bottom_nav.dart';

import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const DashboardScreen(),
    const InvoiceListScreen(),
    const Center(child: Text("Inventory")),
    // const Center(child: Text("Orders")),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        onFabPressed: () {
          context.push(AppRoutes.invoiceAdd);
        },
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
