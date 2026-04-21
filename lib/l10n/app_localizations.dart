import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginTitle;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginBtn;

  /// No description provided for @dashboard_text.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard_text;

  /// No description provided for @password_text.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_text;

  /// No description provided for @en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get en;

  /// No description provided for @vi.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vi;

  /// No description provided for @language_text.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_text;

  /// No description provided for @theme_text.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme_text;

  /// No description provided for @logout_text.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout_text;

  /// No description provided for @login_success.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get login_success;

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get login_failed;

  /// No description provided for @logout_success.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logout_success;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get common_update;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get common_detail;

  /// No description provided for @common_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get common_warning;

  /// No description provided for @action_success.
  ///
  /// In en, this message translates to:
  /// **'{action} {item} successfully'**
  String action_success(Object action, Object item);

  /// No description provided for @action_failed.
  ///
  /// In en, this message translates to:
  /// **'{action} {item} failed'**
  String action_failed(Object action, Object item);

  /// Confirm delete with item name
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {item}?'**
  String confirmDeleteItem(String item);

  /// Generic success message
  ///
  /// In en, this message translates to:
  /// **'{action} {item} successfully'**
  String actionSuccess(String action, String item);

  /// Generic failed message
  ///
  /// In en, this message translates to:
  /// **'{action} {item} failed'**
  String actionFailed(String action, String item);

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get confirm_delete;

  /// No description provided for @confirm_logout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirm_logout;

  /// No description provided for @quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// No description provided for @recent_actions.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recent_actions;

  /// No description provided for @view_all.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get view_all;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @customer_list.
  ///
  /// In en, this message translates to:
  /// **'Customer List'**
  String get customer_list;

  /// No description provided for @customer_add.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get customer_add;

  /// No description provided for @customer_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get customer_edit;

  /// No description provided for @customer_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get customer_delete;

  /// No description provided for @customer_save.
  ///
  /// In en, this message translates to:
  /// **'Save Customer'**
  String get customer_save;

  /// No description provided for @customer_detail.
  ///
  /// In en, this message translates to:
  /// **'Customer Detail'**
  String get customer_detail;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @category_list.
  ///
  /// In en, this message translates to:
  /// **'Category List'**
  String get category_list;

  /// No description provided for @category_add.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get category_add;

  /// No description provided for @category_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get category_edit;

  /// No description provided for @category_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get category_delete;

  /// No description provided for @category_save.
  ///
  /// In en, this message translates to:
  /// **'Save Category'**
  String get category_save;

  /// No description provided for @category_detail.
  ///
  /// In en, this message translates to:
  /// **'Category Detail'**
  String get category_detail;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @product_list.
  ///
  /// In en, this message translates to:
  /// **'Product List'**
  String get product_list;

  /// No description provided for @product_add.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get product_add;

  /// No description provided for @product_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get product_edit;

  /// No description provided for @product_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get product_delete;

  /// No description provided for @product_save.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get product_save;

  /// No description provided for @product_detail.
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get product_detail;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @invoice_list.
  ///
  /// In en, this message translates to:
  /// **'Invoice List'**
  String get invoice_list;

  /// No description provided for @invoice_add.
  ///
  /// In en, this message translates to:
  /// **'Add Invoice'**
  String get invoice_add;

  /// No description provided for @invoice_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Invoice'**
  String get invoice_edit;

  /// No description provided for @invoice_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice'**
  String get invoice_delete;

  /// No description provided for @invoice_save.
  ///
  /// In en, this message translates to:
  /// **'Save Invoice'**
  String get invoice_save;

  /// No description provided for @invoice_detail.
  ///
  /// In en, this message translates to:
  /// **'Invoice Detail'**
  String get invoice_detail;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @supplier_list.
  ///
  /// In en, this message translates to:
  /// **'Supplier List'**
  String get supplier_list;

  /// No description provided for @supplier_add.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get supplier_add;

  /// No description provided for @supplier_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get supplier_edit;

  /// No description provided for @supplier_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete Supplier'**
  String get supplier_delete;

  /// No description provided for @supplier_save.
  ///
  /// In en, this message translates to:
  /// **'Save Supplier'**
  String get supplier_save;

  /// No description provided for @supplier_detail.
  ///
  /// In en, this message translates to:
  /// **'Supplier Detail'**
  String get supplier_detail;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt / Receivables'**
  String get debt;

  /// No description provided for @sales_create.
  ///
  /// In en, this message translates to:
  /// **'Create Sale'**
  String get sales_create;

  /// No description provided for @purchase_create.
  ///
  /// In en, this message translates to:
  /// **'Create Purchase'**
  String get purchase_create;

  /// No description provided for @inventory_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage Inventory'**
  String get inventory_manage;

  /// No description provided for @debt_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage Debt'**
  String get debt_manage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @message_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get message_success;

  /// No description provided for @message_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get message_error;

  /// No description provided for @no_data.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get no_data;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
