import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:manager/core/di/injector.dart';
import 'package:manager/core/router/app_router.dart';
import 'package:manager/data/repositories/product_repository.dart';
import 'package:manager/l10n/app_localizations.dart';
import 'package:manager/viewmodels/auth_viewmodel.dart';
import 'package:manager/viewmodels/categories_viewmodel.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:manager/viewmodels/dashboard_viewmodel.dart';
import 'package:manager/viewmodels/invoice_viewmodel.dart';
import 'package:manager/viewmodels/language_viewmodel.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/viewmodels/supplier_viewmodel.dart';
import 'package:manager/viewmodels/theme_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await dotenv.load(fileName: ".env");
//
//   setupLocator();
//
//   runApp(const MyApp());
// }
// main.dart

Future<void> main() async {
  // 1. Đảm bảo Flutter framework đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load các cấu hình cơ bản (DotEnv, DI)
  await dotenv.load(fileName: ".env");
  setupLocator();

  // 3. Load SharedPreferences ngay tại đây để dùng cho Theme và Language
  final prefs = await SharedPreferences.getInstance();
  final bool? isDark = prefs.getBool("theme_mode");
  final String? languageCode =
      prefs.getString("language_code"); // Giả sử bạn có key này

  runApp(
    MyApp(
      initialIsDark: isDark,
      initialLanguageCode: languageCode,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool? initialIsDark;
  final String? initialLanguageCode;

  const MyApp({
    super.key,
    this.initialIsDark,
    this.initialLanguageCode,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          // Truyền giá trị đã load từ main vào ViewModel constructor
          create: (_) => ThemeViewModel(initialIsDark),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageViewModel(initialLanguageCode),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<AuthViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<ProductViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<CategoriesViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<InvoiceViewmodel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<CustomerViewmodel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<SupplierViewmodel>(),
        ),
      ],
      // providers: [
      //   ChangeNotifierProvider(create: (_) => ThemeViewModel()..loadTheme()),
      //   ChangeNotifierProvider(
      //       create: (_) => LanguageViewModel()..loadLanguage()),
      //   ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
      //   ChangeNotifierProvider(create: (_) => DashboardViewModel()),
      //   ChangeNotifierProvider(
      //     create: (_) => getIt<InvoiceViewmodel>(),
      //   ),
      //   // bỏ loadDashboard
      // ],
      child: const RootApp(),
    );
  }
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final langVM = context.watch<LanguageViewModel>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      locale: langVM.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeVM.themeMode,
    );
  }
}
