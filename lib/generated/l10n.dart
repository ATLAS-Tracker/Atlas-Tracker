// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `AtlasTracker`
  String get appTitle {
    return Intl.message(
      'AtlasTracker',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Version {versionNumber}`
  String appVersionName(Object versionNumber) {
    return Intl.message(
      'Version $versionNumber',
      name: 'appVersionName',
      desc: '',
      args: [versionNumber],
    );
  }

  /// `AtlasTracker is a free and open-source calorie and nutrient tracker that respects your privacy.`
  String get appDescription {
    return Intl.message(
      'AtlasTracker is a free and open-source calorie and nutrient tracker that respects your privacy.',
      name: 'appDescription',
      desc: '',
      args: [],
    );
  }

  /// `[Alpha]`
  String get alphaVersionName {
    return Intl.message(
      '[Alpha]',
      name: 'alphaVersionName',
      desc: '',
      args: [],
    );
  }

  /// `Average Weight`
  String get averageWeightLabel {
    return Intl.message(
      'Average Weight',
      name: 'averageWeightLabel',
      desc: '',
      args: [],
    );
  }

  /// `Average user weight over the last seven days. The current day is not counted.`
  String get averageWeightBody {
    return Intl.message(
      'Average user weight over the last seven days. The current day is not counted.',
      name: 'averageWeightBody',
      desc:
          'Explains that the average weight is calculated from the 7 days preceding the currently selected date, which is not included in the average.',
      args: [],
    );
  }

  /// `[Beta]`
  String get betaVersionName {
    return Intl.message(
      '[Beta]',
      name: 'betaVersionName',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get addLabel {
    return Intl.message(
      'Add',
      name: 'addLabel',
      desc: '',
      args: [],
    );
  }

  /// `Create custom meal item?`
  String get createCustomDialogTitle {
    return Intl.message(
      'Create custom meal item?',
      name: 'createCustomDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do you want create a custom meal item?`
  String get createCustomDialogContent {
    return Intl.message(
      'Do you want create a custom meal item?',
      name: 'createCustomDialogContent',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settingsLabel {
    return Intl.message(
      'Settings',
      name: 'settingsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notificationsLabel {
    return Intl.message(
      'Notifications',
      name: 'notificationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Notification activation problem. Please try again later.`
  String get notificationActivationError {
    return Intl.message(
      'Notification activation problem. Please try again later.',
      name: 'notificationActivationError',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get homeLabel {
    return Intl.message(
      'Home',
      name: 'homeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Weight Delta`
  String get deltaWeightLabel {
    return Intl.message(
      'Weight Delta',
      name: 'deltaWeightLabel',
      desc: '',
      args: [],
    );
  }

  /// `The weight delta is the difference between the average weight and the current weight entered for this day.\nIf no weight is recorded for the current day, the last valid weight will be used.`
  String get deltaWeightBody {
    return Intl.message(
      'The weight delta is the difference between the average weight and the current weight entered for this day.\nIf no weight is recorded for the current day, the last valid weight will be used.',
      name: 'deltaWeightBody',
      desc: '',
      args: [],
    );
  }

  /// `Diary`
  String get diaryLabel {
    return Intl.message(
      'Diary',
      name: 'diaryLabel',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get profileLabel {
    return Intl.message(
      'Profile',
      name: 'profileLabel',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get searchLabel {
    return Intl.message(
      'Search',
      name: 'searchLabel',
      desc: '',
      args: [],
    );
  }

  /// `Products`
  String get searchProductsPage {
    return Intl.message(
      'Products',
      name: 'searchProductsPage',
      desc: '',
      args: [],
    );
  }

  /// `Food`
  String get searchFoodPage {
    return Intl.message(
      'Food',
      name: 'searchFoodPage',
      desc: '',
      args: [],
    );
  }

  /// `Search results`
  String get searchResultsLabel {
    return Intl.message(
      'Search results',
      name: 'searchResultsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a search word`
  String get searchDefaultLabel {
    return Intl.message(
      'Please enter a search word',
      name: 'searchDefaultLabel',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get allItemsLabel {
    return Intl.message(
      'All',
      name: 'allItemsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Recently`
  String get recentlyAddedLabel {
    return Intl.message(
      'Recently',
      name: 'recentlyAddedLabel',
      desc: '',
      args: [],
    );
  }

  /// `No meals recently added`
  String get noMealsRecentlyAddedLabel {
    return Intl.message(
      'No meals recently added',
      name: 'noMealsRecentlyAddedLabel',
      desc: '',
      args: [],
    );
  }

  /// `No activity recently added`
  String get noActivityRecentlyAddedLabel {
    return Intl.message(
      'No activity recently added',
      name: 'noActivityRecentlyAddedLabel',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get dialogOKLabel {
    return Intl.message(
      'OK',
      name: 'dialogOKLabel',
      desc: '',
      args: [],
    );
  }

  /// `CANCEL`
  String get dialogCancelLabel {
    return Intl.message(
      'CANCEL',
      name: 'dialogCancelLabel',
      desc: '',
      args: [],
    );
  }

  /// `START`
  String get buttonStartLabel {
    return Intl.message(
      'START',
      name: 'buttonStartLabel',
      desc: '',
      args: [],
    );
  }

  /// `NEXT`
  String get buttonNextLabel {
    return Intl.message(
      'NEXT',
      name: 'buttonNextLabel',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get buttonSaveLabel {
    return Intl.message(
      'Save',
      name: 'buttonSaveLabel',
      desc: '',
      args: [],
    );
  }

  /// `YES`
  String get buttonYesLabel {
    return Intl.message(
      'YES',
      name: 'buttonYesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get buttonResetLabel {
    return Intl.message(
      'Reset',
      name: 'buttonResetLabel',
      desc: '',
      args: [],
    );
  }

  /// `Units`
  String get settingsUnitsLabel {
    return Intl.message(
      'Units',
      name: 'settingsUnitsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Calculations`
  String get settingsCalculationsLabel {
    return Intl.message(
      'Calculations',
      name: 'settingsCalculationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get settingsThemeLabel {
    return Intl.message(
      'Theme',
      name: 'settingsThemeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get settingsThemeLightLabel {
    return Intl.message(
      'Light',
      name: 'settingsThemeLightLabel',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get settingsThemeDarkLabel {
    return Intl.message(
      'Dark',
      name: 'settingsThemeDarkLabel',
      desc: '',
      args: [],
    );
  }

  /// `System default`
  String get settingsThemeSystemDefaultLabel {
    return Intl.message(
      'System default',
      name: 'settingsThemeSystemDefaultLabel',
      desc: '',
      args: [],
    );
  }

  /// `Licenses`
  String get settingsLicensesLabel {
    return Intl.message(
      'Licenses',
      name: 'settingsLicensesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Report Error`
  String get settingsReportErrorLabel {
    return Intl.message(
      'Report Error',
      name: 'settingsReportErrorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Settings`
  String get settingsPrivacySettings {
    return Intl.message(
      'Privacy Settings',
      name: 'settingsPrivacySettings',
      desc: '',
      args: [],
    );
  }

  /// `Source Code`
  String get settingsSourceCodeLabel {
    return Intl.message(
      'Source Code',
      name: 'settingsSourceCodeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get settingFeedbackLabel {
    return Intl.message(
      'Feedback',
      name: 'settingFeedbackLabel',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get settingAboutLabel {
    return Intl.message(
      'About',
      name: 'settingAboutLabel',
      desc: '',
      args: [],
    );
  }

  /// `Mass`
  String get settingsMassLabel {
    return Intl.message(
      'Mass',
      name: 'settingsMassLabel',
      desc: '',
      args: [],
    );
  }

  /// `System`
  String get settingsSystemLabel {
    return Intl.message(
      'System',
      name: 'settingsSystemLabel',
      desc: '',
      args: [],
    );
  }

  /// `Metric (kg, cm, ml)`
  String get settingsMetricLabel {
    return Intl.message(
      'Metric (kg, cm, ml)',
      name: 'settingsMetricLabel',
      desc: '',
      args: [],
    );
  }

  /// `Imperial (lbs, ft, oz)`
  String get settingsImperialLabel {
    return Intl.message(
      'Imperial (lbs, ft, oz)',
      name: 'settingsImperialLabel',
      desc: '',
      args: [],
    );
  }

  /// `Distance`
  String get settingsDistanceLabel {
    return Intl.message(
      'Distance',
      name: 'settingsDistanceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Volume`
  String get settingsVolumeLabel {
    return Intl.message(
      'Volume',
      name: 'settingsVolumeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to report an error to the developer?`
  String get reportErrorDialogText {
    return Intl.message(
      'Do you want to report an error to the developer?',
      name: 'reportErrorDialogText',
      desc: '',
      args: [],
    );
  }

  /// `Send anonymous usage data`
  String get sendAnonymousUserData {
    return Intl.message(
      'Send anonymous usage data',
      name: 'sendAnonymousUserData',
      desc: '',
      args: [],
    );
  }

  /// `GPL-3.0 license`
  String get appLicenseLabel {
    return Intl.message(
      'GPL-3.0 license',
      name: 'appLicenseLabel',
      desc: '',
      args: [],
    );
  }

  /// `Password required`
  String get passwordRequired {
    return Intl.message(
      'Password required',
      name: 'passwordRequired',
      desc: '',
      args: [],
    );
  }

  /// `At least 8 characters`
  String get passwordMinLength {
    return Intl.message(
      'At least 8 characters',
      name: 'passwordMinLength',
      desc: '',
      args: [],
    );
  }

  /// `At least 1 uppercase letter`
  String get passwordUppercase {
    return Intl.message(
      'At least 1 uppercase letter',
      name: 'passwordUppercase',
      desc: '',
      args: [],
    );
  }

  /// `At least 1 lowercase letter`
  String get passwordLowercase {
    return Intl.message(
      'At least 1 lowercase letter',
      name: 'passwordLowercase',
      desc: '',
      args: [],
    );
  }

  /// `At least 1 digit`
  String get passwordDigit {
    return Intl.message(
      'At least 1 digit',
      name: 'passwordDigit',
      desc: '',
      args: [],
    );
  }

  /// `At least 1 special character`
  String get passwordSpecialChar {
    return Intl.message(
      'At least 1 special character',
      name: 'passwordSpecialChar',
      desc: '',
      args: [],
    );
  }

  /// `Sign In`
  String get loginTitle {
    return Intl.message(
      'Sign In',
      name: 'loginTitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get loginEmailLabel {
    return Intl.message(
      'Email',
      name: 'loginEmailLabel',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get loginPasswordLabel {
    return Intl.message(
      'Password',
      name: 'loginPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sign In`
  String get loginButton {
    return Intl.message(
      'Sign In',
      name: 'loginButton',
      desc: '',
      args: [],
    );
  }

  /// `Forgot password?`
  String get loginForgotPassword {
    return Intl.message(
      'Forgot password?',
      name: 'loginForgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Already signed in on another device. Please sign out first.`
  String get loginAlreadySignedIn {
    return Intl.message(
      'Already signed in on another device. Please sign out first.',
      name: 'loginAlreadySignedIn',
      desc: '',
      args: [],
    );
  }

  /// `Unknown error`
  String get loginUnknownError {
    return Intl.message(
      'Unknown error',
      name: 'loginUnknownError',
      desc: '',
      args: [],
    );
  }

  /// `Email required`
  String get loginEmailRequired {
    return Intl.message(
      'Email required',
      name: 'loginEmailRequired',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email address`
  String get loginEmailInvalid {
    return Intl.message(
      'Invalid email address',
      name: 'loginEmailInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Sign in error`
  String get loginError {
    return Intl.message(
      'Sign in error',
      name: 'loginError',
      desc: '',
      args: [],
    );
  }

  /// `Forgot your password?`
  String get forgotPasswordTitle {
    return Intl.message(
      'Forgot your password?',
      name: 'forgotPasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email`
  String get forgotPasswordEmailLabel {
    return Intl.message(
      'Enter your email',
      name: 'forgotPasswordEmailLabel',
      desc: '',
      args: [],
    );
  }

  /// `Send password reset email`
  String get forgotPasswordButton {
    return Intl.message(
      'Send password reset email',
      name: 'forgotPasswordButton',
      desc: '',
      args: [],
    );
  }

  /// `Back to sign in`
  String get forgotPasswordBackToLogin {
    return Intl.message(
      'Back to sign in',
      name: 'forgotPasswordBackToLogin',
      desc: '',
      args: [],
    );
  }

  /// `Email sent! Click the link in your email to choose a new password.`
  String get forgotPasswordEmailSent {
    return Intl.message(
      'Email sent! Click the link in your email to choose a new password.',
      name: 'forgotPasswordEmailSent',
      desc: '',
      args: [],
    );
  }

  /// `Error sending email:`
  String get forgotPasswordSendError {
    return Intl.message(
      'Error sending email:',
      name: 'forgotPasswordSendError',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get resetPasswordTitle {
    return Intl.message(
      'New password',
      name: 'resetPasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get resetPasswordNewLabel {
    return Intl.message(
      'New password',
      name: 'resetPasswordNewLabel',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password`
  String get resetPasswordConfirmLabel {
    return Intl.message(
      'Confirm password',
      name: 'resetPasswordConfirmLabel',
      desc: '',
      args: [],
    );
  }

  /// `Change password`
  String get resetPasswordButton {
    return Intl.message(
      'Change password',
      name: 'resetPasswordButton',
      desc: '',
      args: [],
    );
  }

  /// `Password changed! You can now sign in with your new password.`
  String get resetPasswordChanged {
    return Intl.message(
      'Password changed! You can now sign in with your new password.',
      name: 'resetPasswordChanged',
      desc: '',
      args: [],
    );
  }

  /// `Passwords do not match`
  String get resetPasswordNoMatch {
    return Intl.message(
      'Passwords do not match',
      name: 'resetPasswordNoMatch',
      desc: '',
      args: [],
    );
  }

  /// `• Use at least 8 characters\n• Mix numbers & special characters\n• Uppercase + lowercase`
  String get resetPasswordTips {
    return Intl.message(
      '• Use at least 8 characters\n• Mix numbers & special characters\n• Uppercase + lowercase',
      name: 'resetPasswordTips',
      desc: '',
      args: [],
    );
  }

  /// `TDEE equation`
  String get calculationsTDEELabel {
    return Intl.message(
      'TDEE equation',
      name: 'calculationsTDEELabel',
      desc: '',
      args: [],
    );
  }

  /// `Institute of Medicine Equation`
  String get calculationsTDEEIOM2006Label {
    return Intl.message(
      'Institute of Medicine Equation',
      name: 'calculationsTDEEIOM2006Label',
      desc: '',
      args: [],
    );
  }

  /// `(recommended)`
  String get calculationsRecommendedLabel {
    return Intl.message(
      '(recommended)',
      name: 'calculationsRecommendedLabel',
      desc: '',
      args: [],
    );
  }

  /// `Macros distribution`
  String get calculationsMacronutrientsDistributionLabel {
    return Intl.message(
      'Macros distribution',
      name: 'calculationsMacronutrientsDistributionLabel',
      desc: '',
      args: [],
    );
  }

  /// `{pctCarbs}% carbs, {pctFats}% fats, {pctProteins}% proteins`
  String calculationsMacrosDistribution(
      Object pctCarbs, Object pctFats, Object pctProteins) {
    return Intl.message(
      '$pctCarbs% carbs, $pctFats% fats, $pctProteins% proteins',
      name: 'calculationsMacrosDistribution',
      desc: '',
      args: [pctCarbs, pctFats, pctProteins],
    );
  }

  /// `Daily Kcal adjustment:`
  String get dailyKcalAdjustmentLabel {
    return Intl.message(
      'Daily Kcal adjustment:',
      name: 'dailyKcalAdjustmentLabel',
      desc: '',
      args: [],
    );
  }

  /// `Macronutrient Distribution:`
  String get macroDistributionLabel {
    return Intl.message(
      'Macronutrient Distribution:',
      name: 'macroDistributionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Export / Import data`
  String get exportImportLabel {
    return Intl.message(
      'Export / Import data',
      name: 'exportImportLabel',
      desc: '',
      args: [],
    );
  }

  /// `You can export the app data to a zip file and import it later. This is useful if you want to backup your data or transfer it to another device.\n\nThe app does not use any cloud service to store your data.`
  String get exportImportDescription {
    return Intl.message(
      'You can export the app data to a zip file and import it later. This is useful if you want to backup your data or transfer it to another device.\n\nThe app does not use any cloud service to store your data.',
      name: 'exportImportDescription',
      desc: '',
      args: [],
    );
  }

  /// `Export / Import successful`
  String get exportImportSuccessLabel {
    return Intl.message(
      'Export / Import successful',
      name: 'exportImportSuccessLabel',
      desc: '',
      args: [],
    );
  }

  /// `Export / Import error`
  String get exportImportErrorLabel {
    return Intl.message(
      'Export / Import error',
      name: 'exportImportErrorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Export`
  String get exportAction {
    return Intl.message(
      'Export',
      name: 'exportAction',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get importAction {
    return Intl.message(
      'Import',
      name: 'importAction',
      desc: '',
      args: [],
    );
  }

  /// `Export to Supabase`
  String get exportSupabaseLabel {
    return Intl.message(
      'Export to Supabase',
      name: 'exportSupabaseLabel',
      desc: '',
      args: [],
    );
  }

  /// `Backup your data to Supabase storage as a zip file.`
  String get exportSupabaseDescription {
    return Intl.message(
      'Backup your data to Supabase storage as a zip file.',
      name: 'exportSupabaseDescription',
      desc: '',
      args: [],
    );
  }

  /// `Import from Supabase`
  String get importSupabaseLabel {
    return Intl.message(
      'Import from Supabase',
      name: 'importSupabaseLabel',
      desc: '',
      args: [],
    );
  }

  /// `Restore your data from a backup stored in Supabase.`
  String get importSupabaseDescription {
    return Intl.message(
      'Restore your data from a backup stored in Supabase.',
      name: 'importSupabaseDescription',
      desc: '',
      args: [],
    );
  }

  /// `Export / Import with Supabase`
  String get exportImportSupabaseLabel {
    return Intl.message(
      'Export / Import with Supabase',
      name: 'exportImportSupabaseLabel',
      desc: '',
      args: [],
    );
  }

  /// `Backup your data to Supabase storage as a zip file or restore it from there.`
  String get exportImportSupabaseDescription {
    return Intl.message(
      'Backup your data to Supabase storage as a zip file or restore it from there.',
      name: 'exportImportSupabaseDescription',
      desc: '',
      args: [],
    );
  }

  /// `Add new Item:`
  String get addItemLabel {
    return Intl.message(
      'Add new Item:',
      name: 'addItemLabel',
      desc: '',
      args: [],
    );
  }

  /// `Activity`
  String get activityLabel {
    return Intl.message(
      'Activity',
      name: 'activityLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. running, biking, yoga ...`
  String get activityExample {
    return Intl.message(
      'e.g. running, biking, yoga ...',
      name: 'activityExample',
      desc: '',
      args: [],
    );
  }

  /// `Breakfast`
  String get breakfastLabel {
    return Intl.message(
      'Breakfast',
      name: 'breakfastLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. cereal, milk, coffee ...`
  String get breakfastExample {
    return Intl.message(
      'e.g. cereal, milk, coffee ...',
      name: 'breakfastExample',
      desc: '',
      args: [],
    );
  }

  /// `Lunch`
  String get lunchLabel {
    return Intl.message(
      'Lunch',
      name: 'lunchLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. pizza, salad, rice ...`
  String get lunchExample {
    return Intl.message(
      'e.g. pizza, salad, rice ...',
      name: 'lunchExample',
      desc: '',
      args: [],
    );
  }

  /// `Dinner`
  String get dinnerLabel {
    return Intl.message(
      'Dinner',
      name: 'dinnerLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. soup, chicken, wine ...`
  String get dinnerExample {
    return Intl.message(
      'e.g. soup, chicken, wine ...',
      name: 'dinnerExample',
      desc: '',
      args: [],
    );
  }

  /// `Snack`
  String get snackLabel {
    return Intl.message(
      'Snack',
      name: 'snackLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. apple, ice cream, chocolate ...`
  String get snackExample {
    return Intl.message(
      'e.g. apple, ice cream, chocolate ...',
      name: 'snackExample',
      desc: '',
      args: [],
    );
  }

  /// `Edit item`
  String get editItemDialogTitle {
    return Intl.message(
      'Edit item',
      name: 'editItemDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Item updated`
  String get itemUpdatedSnackbar {
    return Intl.message(
      'Item updated',
      name: 'itemUpdatedSnackbar',
      desc: '',
      args: [],
    );
  }

  /// `Delete Item?`
  String get deleteTimeDialogTitle {
    return Intl.message(
      'Delete Item?',
      name: 'deleteTimeDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do want to delete the selected item?`
  String get deleteTimeDialogContent {
    return Intl.message(
      'Do want to delete the selected item?',
      name: 'deleteTimeDialogContent',
      desc: '',
      args: [],
    );
  }

  /// `Delete Items?`
  String get deleteTimeDialogPluralTitle {
    return Intl.message(
      'Delete Items?',
      name: 'deleteTimeDialogPluralTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do want to delete all items of this meal?`
  String get deleteTimeDialogPluralContent {
    return Intl.message(
      'Do want to delete all items of this meal?',
      name: 'deleteTimeDialogPluralContent',
      desc: '',
      args: [],
    );
  }

  /// `Item deleted`
  String get itemDeletedSnackbar {
    return Intl.message(
      'Item deleted',
      name: 'itemDeletedSnackbar',
      desc: '',
      args: [],
    );
  }

  /// `Which meal type do you want to copy to?`
  String get copyDialogTitle {
    return Intl.message(
      'Which meal type do you want to copy to?',
      name: 'copyDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `What do you want to do?`
  String get copyOrDeleteTimeDialogTitle {
    return Intl.message(
      'What do you want to do?',
      name: 'copyOrDeleteTimeDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `With "Copy to today" you can copy the meal to today. With "Delete" you can delete the meal.`
  String get copyOrDeleteTimeDialogContent {
    return Intl.message(
      'With "Copy to today" you can copy the meal to today. With "Delete" you can delete the meal.',
      name: 'copyOrDeleteTimeDialogContent',
      desc: '',
      args: [],
    );
  }

  /// `Copy to today`
  String get dialogCopyLabel {
    return Intl.message(
      'Copy to today',
      name: 'dialogCopyLabel',
      desc: '',
      args: [],
    );
  }

  /// `DELETE`
  String get dialogDeleteLabel {
    return Intl.message(
      'DELETE',
      name: 'dialogDeleteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Delete all`
  String get deleteAllLabel {
    return Intl.message(
      'Delete all',
      name: 'deleteAllLabel',
      desc: '',
      args: [],
    );
  }

  /// `supplied`
  String get suppliedLabel {
    return Intl.message(
      'supplied',
      name: 'suppliedLabel',
      desc: '',
      args: [],
    );
  }

  /// `burned`
  String get burnedLabel {
    return Intl.message(
      'burned',
      name: 'burnedLabel',
      desc: '',
      args: [],
    );
  }

  /// `steps`
  String get stepsLabel {
    return Intl.message(
      'steps',
      name: 'stepsLabel',
      desc: '',
      args: [],
    );
  }

  /// `kcal left`
  String get kcalLeftLabel {
    return Intl.message(
      'kcal left',
      name: 'kcalLeftLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nutrition Information`
  String get nutritionInfoLabel {
    return Intl.message(
      'Nutrition Information',
      name: 'nutritionInfoLabel',
      desc: '',
      args: [],
    );
  }

  /// `kcal`
  String get kcalLabel {
    return Intl.message(
      'kcal',
      name: 'kcalLabel',
      desc: '',
      args: [],
    );
  }

  /// `carbs`
  String get carbsLabel {
    return Intl.message(
      'carbs',
      name: 'carbsLabel',
      desc: '',
      args: [],
    );
  }

  /// `fat`
  String get fatLabel {
    return Intl.message(
      'fat',
      name: 'fatLabel',
      desc: '',
      args: [],
    );
  }

  /// `protein`
  String get proteinLabel {
    return Intl.message(
      'protein',
      name: 'proteinLabel',
      desc: '',
      args: [],
    );
  }

  /// `Calories`
  String get caloriesLabel {
    return Intl.message(
      'Calories',
      name: 'caloriesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Carbohydrates`
  String get carbohydratesLabel {
    return Intl.message(
      'Carbohydrates',
      name: 'carbohydratesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Fats`
  String get fatsLabel {
    return Intl.message(
      'Fats',
      name: 'fatsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Proteins`
  String get proteinsLabel {
    return Intl.message(
      'Proteins',
      name: 'proteinsLabel',
      desc: '',
      args: [],
    );
  }

  /// `energy`
  String get energyLabel {
    return Intl.message(
      'energy',
      name: 'energyLabel',
      desc: '',
      args: [],
    );
  }

  /// `saturated fat`
  String get saturatedFatLabel {
    return Intl.message(
      'saturated fat',
      name: 'saturatedFatLabel',
      desc: '',
      args: [],
    );
  }

  /// `carbohydrate`
  String get carbohydrateLabel {
    return Intl.message(
      'carbohydrate',
      name: 'carbohydrateLabel',
      desc: '',
      args: [],
    );
  }

  /// `sugar`
  String get sugarLabel {
    return Intl.message(
      'sugar',
      name: 'sugarLabel',
      desc: '',
      args: [],
    );
  }

  /// `fiber`
  String get fiberLabel {
    return Intl.message(
      'fiber',
      name: 'fiberLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per 100g/ml`
  String get per100gmlLabel {
    return Intl.message(
      'Per 100g/ml',
      name: 'per100gmlLabel',
      desc: '',
      args: [],
    );
  }

  /// `More Information at\nOpenFoodFacts`
  String get additionalInfoLabelOFF {
    return Intl.message(
      'More Information at\nOpenFoodFacts',
      name: 'additionalInfoLabelOFF',
      desc: '',
      args: [],
    );
  }

  /// `More Information at\nFoodData Central`
  String get additionalInfoLabelFDC {
    return Intl.message(
      'More Information at\nFoodData Central',
      name: 'additionalInfoLabelFDC',
      desc: '',
      args: [],
    );
  }

  /// `Unknown Meal Item`
  String get additionalInfoLabelUnknown {
    return Intl.message(
      'Unknown Meal Item',
      name: 'additionalInfoLabelUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Custom Meal Item`
  String get additionalInfoLabelCustom {
    return Intl.message(
      'Custom Meal Item',
      name: 'additionalInfoLabelCustom',
      desc: '',
      args: [],
    );
  }

  /// `Information provided\n by the \n'2011 Compendium\n of Physical Activities'`
  String get additionalInfoLabelCompendium2011 {
    return Intl.message(
      'Information provided\n by the \n\'2011 Compendium\n of Physical Activities\'',
      name: 'additionalInfoLabelCompendium2011',
      desc: '',
      args: [],
    );
  }

  /// `Quantity`
  String get quantityLabel {
    return Intl.message(
      'Quantity',
      name: 'quantityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Base quantity (g/ml)`
  String get baseQuantityLabel {
    return Intl.message(
      'Base quantity (g/ml)',
      name: 'baseQuantityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Unit`
  String get unitLabel {
    return Intl.message(
      'Unit',
      name: 'unitLabel',
      desc: '',
      args: [],
    );
  }

  /// `Scan Product`
  String get scanProductLabel {
    return Intl.message(
      'Scan Product',
      name: 'scanProductLabel',
      desc: '',
      args: [],
    );
  }

  /// `g`
  String get gramUnit {
    return Intl.message(
      'g',
      name: 'gramUnit',
      desc: '',
      args: [],
    );
  }

  /// `ml`
  String get milliliterUnit {
    return Intl.message(
      'ml',
      name: 'milliliterUnit',
      desc: '',
      args: [],
    );
  }

  /// `g/ml`
  String get gramMilliliterUnit {
    return Intl.message(
      'g/ml',
      name: 'gramMilliliterUnit',
      desc: '',
      args: [],
    );
  }

  /// `oz`
  String get ozUnit {
    return Intl.message(
      'oz',
      name: 'ozUnit',
      desc: '',
      args: [],
    );
  }

  /// `fl.oz`
  String get flOzUnit {
    return Intl.message(
      'fl.oz',
      name: 'flOzUnit',
      desc: '',
      args: [],
    );
  }

  /// `N/A`
  String get notAvailableLabel {
    return Intl.message(
      'N/A',
      name: 'notAvailableLabel',
      desc: '',
      args: [],
    );
  }

  /// `Product missing required kcal or macronutrients information`
  String get missingProductInfo {
    return Intl.message(
      'Product missing required kcal or macronutrients information',
      name: 'missingProductInfo',
      desc: '',
      args: [],
    );
  }

  /// `Added new intake`
  String get infoAddedIntakeLabel {
    return Intl.message(
      'Added new intake',
      name: 'infoAddedIntakeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Added new activity`
  String get infoAddedActivityLabel {
    return Intl.message(
      'Added new activity',
      name: 'infoAddedActivityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Edit meal`
  String get editMealLabel {
    return Intl.message(
      'Edit meal',
      name: 'editMealLabel',
      desc: '',
      args: [],
    );
  }

  /// `Meal name`
  String get mealNameLabel {
    return Intl.message(
      'Meal name',
      name: 'mealNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Brands`
  String get mealBrandsLabel {
    return Intl.message(
      'Brands',
      name: 'mealBrandsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Meal size (g/ml)`
  String get mealSizeLabel {
    return Intl.message(
      'Meal size (g/ml)',
      name: 'mealSizeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Meal size (oz/fl oz)`
  String get mealSizeLabelImperial {
    return Intl.message(
      'Meal size (oz/fl oz)',
      name: 'mealSizeLabelImperial',
      desc: '',
      args: [],
    );
  }

  /// `Serving`
  String get servingLabel {
    return Intl.message(
      'Serving',
      name: 'servingLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per Serving`
  String get perServingLabel {
    return Intl.message(
      'Per Serving',
      name: 'perServingLabel',
      desc: '',
      args: [],
    );
  }

  /// `Serving size (g/ml)`
  String get servingSizeLabelMetric {
    return Intl.message(
      'Serving size (g/ml)',
      name: 'servingSizeLabelMetric',
      desc: '',
      args: [],
    );
  }

  /// `Serving size (oz/fl oz)`
  String get servingSizeLabelImperial {
    return Intl.message(
      'Serving size (oz/fl oz)',
      name: 'servingSizeLabelImperial',
      desc: '',
      args: [],
    );
  }

  /// `Meal unit`
  String get mealUnitLabel {
    return Intl.message(
      'Meal unit',
      name: 'mealUnitLabel',
      desc: '',
      args: [],
    );
  }

  /// `kcal per`
  String get mealKcalLabel {
    return Intl.message(
      'kcal per',
      name: 'mealKcalLabel',
      desc: '',
      args: [],
    );
  }

  /// `carbs per`
  String get mealCarbsLabel {
    return Intl.message(
      'carbs per',
      name: 'mealCarbsLabel',
      desc: '',
      args: [],
    );
  }

  /// `fat per`
  String get mealFatLabel {
    return Intl.message(
      'fat per',
      name: 'mealFatLabel',
      desc: '',
      args: [],
    );
  }

  /// `protein per 100 g/ml`
  String get mealProteinLabel {
    return Intl.message(
      'protein per 100 g/ml',
      name: 'mealProteinLabel',
      desc: '',
      args: [],
    );
  }

  /// `Error while saving meal. Did you input the correct meal information?`
  String get errorMealSave {
    return Intl.message(
      'Error while saving meal. Did you input the correct meal information?',
      name: 'errorMealSave',
      desc: '',
      args: [],
    );
  }

  /// `BMI`
  String get bmiLabel {
    return Intl.message(
      'BMI',
      name: 'bmiLabel',
      desc: '',
      args: [],
    );
  }

  /// `Body Mass Index (BMI) is a index to classify overweight and obesity in adults. It is defined as weight in kilograms divided by the square of height in meters (kg/m²).\n\nBMI does not differentiate between fat and muscle mass and can be misleading for some individuals.`
  String get bmiInfo {
    return Intl.message(
      'Body Mass Index (BMI) is a index to classify overweight and obesity in adults. It is defined as weight in kilograms divided by the square of height in meters (kg/m²).\n\nBMI does not differentiate between fat and muscle mass and can be misleading for some individuals.',
      name: 'bmiInfo',
      desc: '',
      args: [],
    );
  }

  /// `I have read and accept the privacy policy.`
  String get readLabel {
    return Intl.message(
      'I have read and accept the privacy policy.',
      name: 'readLabel',
      desc: '',
      args: [],
    );
  }

  /// `Privacy policy`
  String get privacyPolicyLabel {
    return Intl.message(
      'Privacy policy',
      name: 'privacyPolicyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Support development by providing anonymous usage data`
  String get dataCollectionLabel {
    return Intl.message(
      'Support development by providing anonymous usage data',
      name: 'dataCollectionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sedentary`
  String get palSedentaryLabel {
    return Intl.message(
      'Sedentary',
      name: 'palSedentaryLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. office job and mostly sitting free time activities`
  String get palSedentaryDescriptionLabel {
    return Intl.message(
      'e.g. office job and mostly sitting free time activities',
      name: 'palSedentaryDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Low Active`
  String get palLowLActiveLabel {
    return Intl.message(
      'Low Active',
      name: 'palLowLActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. sitting or standing in job and light free time activities`
  String get palLowActiveDescriptionLabel {
    return Intl.message(
      'e.g. sitting or standing in job and light free time activities',
      name: 'palLowActiveDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get palActiveLabel {
    return Intl.message(
      'Active',
      name: 'palActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Mostly standing or walking in job and active free time activities`
  String get palActiveDescriptionLabel {
    return Intl.message(
      'Mostly standing or walking in job and active free time activities',
      name: 'palActiveDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Very Active`
  String get palVeryActiveLabel {
    return Intl.message(
      'Very Active',
      name: 'palVeryActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Mostly walking, running or carrying weight in job and active free time activities`
  String get palVeryActiveDescriptionLabel {
    return Intl.message(
      'Mostly walking, running or carrying weight in job and active free time activities',
      name: 'palVeryActiveDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select Activity Level`
  String get selectPalCategoryLabel {
    return Intl.message(
      'Select Activity Level',
      name: 'selectPalCategoryLabel',
      desc: '',
      args: [],
    );
  }

  /// `Choose Weight Goal`
  String get chooseWeightGoalLabel {
    return Intl.message(
      'Choose Weight Goal',
      name: 'chooseWeightGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Lose Weight`
  String get goalLoseWeight {
    return Intl.message(
      'Lose Weight',
      name: 'goalLoseWeight',
      desc: '',
      args: [],
    );
  }

  /// `Maintain Weight`
  String get goalMaintainWeight {
    return Intl.message(
      'Maintain Weight',
      name: 'goalMaintainWeight',
      desc: '',
      args: [],
    );
  }

  /// `Gain Weight`
  String get goalGainWeight {
    return Intl.message(
      'Gain Weight',
      name: 'goalGainWeight',
      desc: '',
      args: [],
    );
  }

  /// `Goal`
  String get goalLabel {
    return Intl.message(
      'Goal',
      name: 'goalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select Height`
  String get selectHeightDialogLabel {
    return Intl.message(
      'Select Height',
      name: 'selectHeightDialogLabel',
      desc: '',
      args: [],
    );
  }

  /// `Height`
  String get heightLabel {
    return Intl.message(
      'Height',
      name: 'heightLabel',
      desc: '',
      args: [],
    );
  }

  /// `cm`
  String get cmLabel {
    return Intl.message(
      'cm',
      name: 'cmLabel',
      desc: '',
      args: [],
    );
  }

  /// `ft`
  String get ftLabel {
    return Intl.message(
      'ft',
      name: 'ftLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select Weight`
  String get selectWeightDialogLabel {
    return Intl.message(
      'Select Weight',
      name: 'selectWeightDialogLabel',
      desc: '',
      args: [],
    );
  }

  /// `Weight`
  String get weightLabel {
    return Intl.message(
      'Weight',
      name: 'weightLabel',
      desc: '',
      args: [],
    );
  }

  /// `kg`
  String get kgLabel {
    return Intl.message(
      'kg',
      name: 'kgLabel',
      desc: '',
      args: [],
    );
  }

  /// `lbs`
  String get lbsLabel {
    return Intl.message(
      'lbs',
      name: 'lbsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Age`
  String get ageLabel {
    return Intl.message(
      'Age',
      name: 'ageLabel',
      desc: '',
      args: [],
    );
  }

  /// `{age} years`
  String yearsLabel(Object age) {
    return Intl.message(
      '$age years',
      name: 'yearsLabel',
      desc: '',
      args: [age],
    );
  }

  /// `Select Gender`
  String get selectGenderDialogLabel {
    return Intl.message(
      'Select Gender',
      name: 'selectGenderDialogLabel',
      desc: '',
      args: [],
    );
  }

  /// `Gender`
  String get genderLabel {
    return Intl.message(
      'Gender',
      name: 'genderLabel',
      desc: '',
      args: [],
    );
  }

  /// `♂ male`
  String get genderMaleLabel {
    return Intl.message(
      '♂ male',
      name: 'genderMaleLabel',
      desc: '',
      args: [],
    );
  }

  /// `♀ female`
  String get genderFemaleLabel {
    return Intl.message(
      '♀ female',
      name: 'genderFemaleLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select Role`
  String get selectRoleDialogLabel {
    return Intl.message(
      'Select Role',
      name: 'selectRoleDialogLabel',
      desc: '',
      args: [],
    );
  }

  /// `Role`
  String get roleLabel {
    return Intl.message(
      'Role',
      name: 'roleLabel',
      desc: '',
      args: [],
    );
  }

  /// `Coach`
  String get roleCoachLabel {
    return Intl.message(
      'Coach',
      name: 'roleCoachLabel',
      desc: '',
      args: [],
    );
  }

  /// `Student`
  String get roleStudentLabel {
    return Intl.message(
      'Student',
      name: 'roleStudentLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nothing added`
  String get nothingAddedLabel {
    return Intl.message(
      'Nothing added',
      name: 'nothingAddedLabel',
      desc: '',
      args: [],
    );
  }

  /// `Underweight`
  String get nutritionalStatusUnderweight {
    return Intl.message(
      'Underweight',
      name: 'nutritionalStatusUnderweight',
      desc: '',
      args: [],
    );
  }

  /// `Normal Weight`
  String get nutritionalStatusNormalWeight {
    return Intl.message(
      'Normal Weight',
      name: 'nutritionalStatusNormalWeight',
      desc: '',
      args: [],
    );
  }

  /// `Pre-obesity`
  String get nutritionalStatusPreObesity {
    return Intl.message(
      'Pre-obesity',
      name: 'nutritionalStatusPreObesity',
      desc: '',
      args: [],
    );
  }

  /// `Obesity Class I`
  String get nutritionalStatusObeseClassI {
    return Intl.message(
      'Obesity Class I',
      name: 'nutritionalStatusObeseClassI',
      desc: '',
      args: [],
    );
  }

  /// `Obesity Class II`
  String get nutritionalStatusObeseClassII {
    return Intl.message(
      'Obesity Class II',
      name: 'nutritionalStatusObeseClassII',
      desc: '',
      args: [],
    );
  }

  /// `Obesity Class III`
  String get nutritionalStatusObeseClassIII {
    return Intl.message(
      'Obesity Class III',
      name: 'nutritionalStatusObeseClassIII',
      desc: '',
      args: [],
    );
  }

  /// `Risk of comorbidities: {riskValue}`
  String nutritionalStatusRiskLabel(Object riskValue) {
    return Intl.message(
      'Risk of comorbidities: $riskValue',
      name: 'nutritionalStatusRiskLabel',
      desc: '',
      args: [riskValue],
    );
  }

  /// `Low \n(but risk of other \nclinical problems increased)`
  String get nutritionalStatusRiskLow {
    return Intl.message(
      'Low \n(but risk of other \nclinical problems increased)',
      name: 'nutritionalStatusRiskLow',
      desc: '',
      args: [],
    );
  }

  /// `Average`
  String get nutritionalStatusRiskAverage {
    return Intl.message(
      'Average',
      name: 'nutritionalStatusRiskAverage',
      desc: '',
      args: [],
    );
  }

  /// `Increased`
  String get nutritionalStatusRiskIncreased {
    return Intl.message(
      'Increased',
      name: 'nutritionalStatusRiskIncreased',
      desc: '',
      args: [],
    );
  }

  /// `Moderate`
  String get nutritionalStatusRiskModerate {
    return Intl.message(
      'Moderate',
      name: 'nutritionalStatusRiskModerate',
      desc: '',
      args: [],
    );
  }

  /// `Severe`
  String get nutritionalStatusRiskSevere {
    return Intl.message(
      'Severe',
      name: 'nutritionalStatusRiskSevere',
      desc: '',
      args: [],
    );
  }

  /// `Very severe`
  String get nutritionalStatusRiskVerySevere {
    return Intl.message(
      'Very severe',
      name: 'nutritionalStatusRiskVerySevere',
      desc: '',
      args: [],
    );
  }

  /// `Error while opening email app`
  String get errorOpeningEmail {
    return Intl.message(
      'Error while opening email app',
      name: 'errorOpeningEmail',
      desc: '',
      args: [],
    );
  }

  /// `Error while opening browser app`
  String get errorOpeningBrowser {
    return Intl.message(
      'Error while opening browser app',
      name: 'errorOpeningBrowser',
      desc: '',
      args: [],
    );
  }

  /// `Error while fetching product data`
  String get errorFetchingProductData {
    return Intl.message(
      'Error while fetching product data',
      name: 'errorFetchingProductData',
      desc: '',
      args: [],
    );
  }

  /// `Product not found`
  String get errorProductNotFound {
    return Intl.message(
      'Product not found',
      name: 'errorProductNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Error while loading activities`
  String get errorLoadingActivities {
    return Intl.message(
      'Error while loading activities',
      name: 'errorLoadingActivities',
      desc: '',
      args: [],
    );
  }

  /// `No results found`
  String get noResultsFound {
    return Intl.message(
      'No results found',
      name: 'noResultsFound',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retryLabel {
    return Intl.message(
      'Retry',
      name: 'retryLabel',
      desc: '',
      args: [],
    );
  }

  /// `bicycling`
  String get paHeadingBicycling {
    return Intl.message(
      'bicycling',
      name: 'paHeadingBicycling',
      desc: '',
      args: [],
    );
  }

  /// `conditioning exercise`
  String get paHeadingConditionalExercise {
    return Intl.message(
      'conditioning exercise',
      name: 'paHeadingConditionalExercise',
      desc: '',
      args: [],
    );
  }

  /// `dancing`
  String get paHeadingDancing {
    return Intl.message(
      'dancing',
      name: 'paHeadingDancing',
      desc: '',
      args: [],
    );
  }

  /// `running`
  String get paHeadingRunning {
    return Intl.message(
      'running',
      name: 'paHeadingRunning',
      desc: '',
      args: [],
    );
  }

  /// `sports`
  String get paHeadingSports {
    return Intl.message(
      'sports',
      name: 'paHeadingSports',
      desc: '',
      args: [],
    );
  }

  /// `walking`
  String get paHeadingWalking {
    return Intl.message(
      'walking',
      name: 'paHeadingWalking',
      desc: '',
      args: [],
    );
  }

  /// `water activities`
  String get paHeadingWaterActivities {
    return Intl.message(
      'water activities',
      name: 'paHeadingWaterActivities',
      desc: '',
      args: [],
    );
  }

  /// `winter activities`
  String get paHeadingWinterActivities {
    return Intl.message(
      'winter activities',
      name: 'paHeadingWinterActivities',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paGeneralDesc {
    return Intl.message(
      'general',
      name: 'paGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `bicycling`
  String get paBicyclingGeneral {
    return Intl.message(
      'bicycling',
      name: 'paBicyclingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBicyclingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBicyclingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `bicycling, mountain`
  String get paBicyclingMountainGeneral {
    return Intl.message(
      'bicycling, mountain',
      name: 'paBicyclingMountainGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBicyclingMountainGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBicyclingMountainGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `unicycling`
  String get paUnicyclingGeneral {
    return Intl.message(
      'unicycling',
      name: 'paUnicyclingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paUnicyclingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paUnicyclingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `bicycling, stationary`
  String get paBicyclingStationaryGeneral {
    return Intl.message(
      'bicycling, stationary',
      name: 'paBicyclingStationaryGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBicyclingStationaryGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBicyclingStationaryGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `calisthenics`
  String get paCalisthenicsGeneral {
    return Intl.message(
      'calisthenics',
      name: 'paCalisthenicsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `light or moderate effort, general (e.g., back exercises)`
  String get paCalisthenicsGeneralDesc {
    return Intl.message(
      'light or moderate effort, general (e.g., back exercises)',
      name: 'paCalisthenicsGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `resistance training`
  String get paResistanceTraining {
    return Intl.message(
      'resistance training',
      name: 'paResistanceTraining',
      desc: '',
      args: [],
    );
  }

  /// `weight lifting, free weight, nautilus or universal`
  String get paResistanceTrainingDesc {
    return Intl.message(
      'weight lifting, free weight, nautilus or universal',
      name: 'paResistanceTrainingDesc',
      desc: '',
      args: [],
    );
  }

  /// `rope skipping`
  String get paRopeSkippingGeneral {
    return Intl.message(
      'rope skipping',
      name: 'paRopeSkippingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paRopeSkippingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paRopeSkippingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `water exercise`
  String get paWaterAerobics {
    return Intl.message(
      'water exercise',
      name: 'paWaterAerobics',
      desc: '',
      args: [],
    );
  }

  /// `water aerobics, water calisthenics`
  String get paWaterAerobicsDesc {
    return Intl.message(
      'water aerobics, water calisthenics',
      name: 'paWaterAerobicsDesc',
      desc: '',
      args: [],
    );
  }

  /// `aerobic`
  String get paDancingAerobicGeneral {
    return Intl.message(
      'aerobic',
      name: 'paDancingAerobicGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paDancingAerobicGeneralDesc {
    return Intl.message(
      'general',
      name: 'paDancingAerobicGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `general dancing`
  String get paDancingGeneral {
    return Intl.message(
      'general dancing',
      name: 'paDancingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `e.g. disco, folk, Irish step dancing, line dancing, polka, contra, country`
  String get paDancingGeneralDesc {
    return Intl.message(
      'e.g. disco, folk, Irish step dancing, line dancing, polka, contra, country',
      name: 'paDancingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `jogging`
  String get paJoggingGeneral {
    return Intl.message(
      'jogging',
      name: 'paJoggingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paJoggingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paJoggingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `running`
  String get paRunningGeneral {
    return Intl.message(
      'running',
      name: 'paRunningGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paRunningGeneralDesc {
    return Intl.message(
      'general',
      name: 'paRunningGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `archery`
  String get paArcheryGeneral {
    return Intl.message(
      'archery',
      name: 'paArcheryGeneral',
      desc: '',
      args: [],
    );
  }

  /// `non-hunting`
  String get paArcheryGeneralDesc {
    return Intl.message(
      'non-hunting',
      name: 'paArcheryGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `badminton`
  String get paBadmintonGeneral {
    return Intl.message(
      'badminton',
      name: 'paBadmintonGeneral',
      desc: '',
      args: [],
    );
  }

  /// `social singles and doubles, general`
  String get paBadmintonGeneralDesc {
    return Intl.message(
      'social singles and doubles, general',
      name: 'paBadmintonGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `basketball`
  String get paBasketballGeneral {
    return Intl.message(
      'basketball',
      name: 'paBasketballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBasketballGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBasketballGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `billiards`
  String get paBilliardsGeneral {
    return Intl.message(
      'billiards',
      name: 'paBilliardsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBilliardsGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBilliardsGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `bowling`
  String get paBowlingGeneral {
    return Intl.message(
      'bowling',
      name: 'paBowlingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBowlingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBowlingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `boxing`
  String get paBoxingBag {
    return Intl.message(
      'boxing',
      name: 'paBoxingBag',
      desc: '',
      args: [],
    );
  }

  /// `punching bag`
  String get paBoxingBagDesc {
    return Intl.message(
      'punching bag',
      name: 'paBoxingBagDesc',
      desc: '',
      args: [],
    );
  }

  /// `boxing`
  String get paBoxingGeneral {
    return Intl.message(
      'boxing',
      name: 'paBoxingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `in ring, general`
  String get paBoxingGeneralDesc {
    return Intl.message(
      'in ring, general',
      name: 'paBoxingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `broomball`
  String get paBroomball {
    return Intl.message(
      'broomball',
      name: 'paBroomball',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBroomballDesc {
    return Intl.message(
      'general',
      name: 'paBroomballDesc',
      desc: '',
      args: [],
    );
  }

  /// `children’s games`
  String get paChildrenGame {
    return Intl.message(
      'children’s games',
      name: 'paChildrenGame',
      desc: '',
      args: [],
    );
  }

  /// `(e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort`
  String get paChildrenGameDesc {
    return Intl.message(
      '(e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort',
      name: 'paChildrenGameDesc',
      desc: '',
      args: [],
    );
  }

  /// `cheerleading`
  String get paCheerleading {
    return Intl.message(
      'cheerleading',
      name: 'paCheerleading',
      desc: '',
      args: [],
    );
  }

  /// `gymnastic moves, competitive`
  String get paCheerleadingDesc {
    return Intl.message(
      'gymnastic moves, competitive',
      name: 'paCheerleadingDesc',
      desc: '',
      args: [],
    );
  }

  /// `cricket`
  String get paCricket {
    return Intl.message(
      'cricket',
      name: 'paCricket',
      desc: '',
      args: [],
    );
  }

  /// `batting, bowling, fielding`
  String get paCricketDesc {
    return Intl.message(
      'batting, bowling, fielding',
      name: 'paCricketDesc',
      desc: '',
      args: [],
    );
  }

  /// `croquet`
  String get paCroquet {
    return Intl.message(
      'croquet',
      name: 'paCroquet',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paCroquetDesc {
    return Intl.message(
      'general',
      name: 'paCroquetDesc',
      desc: '',
      args: [],
    );
  }

  /// `curling`
  String get paCurling {
    return Intl.message(
      'curling',
      name: 'paCurling',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paCurlingDesc {
    return Intl.message(
      'general',
      name: 'paCurlingDesc',
      desc: '',
      args: [],
    );
  }

  /// `darts`
  String get paDartsWall {
    return Intl.message(
      'darts',
      name: 'paDartsWall',
      desc: '',
      args: [],
    );
  }

  /// `wall or lawn`
  String get paDartsWallDesc {
    return Intl.message(
      'wall or lawn',
      name: 'paDartsWallDesc',
      desc: '',
      args: [],
    );
  }

  /// `auto racing`
  String get paAutoRacing {
    return Intl.message(
      'auto racing',
      name: 'paAutoRacing',
      desc: '',
      args: [],
    );
  }

  /// `open wheel`
  String get paAutoRacingDesc {
    return Intl.message(
      'open wheel',
      name: 'paAutoRacingDesc',
      desc: '',
      args: [],
    );
  }

  /// `fencing`
  String get paFencing {
    return Intl.message(
      'fencing',
      name: 'paFencing',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paFencingDesc {
    return Intl.message(
      'general',
      name: 'paFencingDesc',
      desc: '',
      args: [],
    );
  }

  /// `football`
  String get paAmericanFootballGeneral {
    return Intl.message(
      'football',
      name: 'paAmericanFootballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `touch, flag, general`
  String get paAmericanFootballGeneralDesc {
    return Intl.message(
      'touch, flag, general',
      name: 'paAmericanFootballGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `football or baseball`
  String get paCatch {
    return Intl.message(
      'football or baseball',
      name: 'paCatch',
      desc: '',
      args: [],
    );
  }

  /// `playing catch`
  String get paCatchDesc {
    return Intl.message(
      'playing catch',
      name: 'paCatchDesc',
      desc: '',
      args: [],
    );
  }

  /// `frisbee playing`
  String get paFrisbee {
    return Intl.message(
      'frisbee playing',
      name: 'paFrisbee',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paFrisbeeDesc {
    return Intl.message(
      'general',
      name: 'paFrisbeeDesc',
      desc: '',
      args: [],
    );
  }

  /// `golf`
  String get paGolfGeneral {
    return Intl.message(
      'golf',
      name: 'paGolfGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paGolfGeneralDesc {
    return Intl.message(
      'general',
      name: 'paGolfGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `gymnastics`
  String get paGymnasticsGeneral {
    return Intl.message(
      'gymnastics',
      name: 'paGymnasticsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paGymnasticsGeneralDesc {
    return Intl.message(
      'general',
      name: 'paGymnasticsGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `hacky sack`
  String get paHackySack {
    return Intl.message(
      'hacky sack',
      name: 'paHackySack',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paHackySackDesc {
    return Intl.message(
      'general',
      name: 'paHackySackDesc',
      desc: '',
      args: [],
    );
  }

  /// `handball`
  String get paHandballGeneral {
    return Intl.message(
      'handball',
      name: 'paHandballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paHandballGeneralDesc {
    return Intl.message(
      'general',
      name: 'paHandballGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `hang gliding`
  String get paHangGliding {
    return Intl.message(
      'hang gliding',
      name: 'paHangGliding',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paHangGlidingDesc {
    return Intl.message(
      'general',
      name: 'paHangGlidingDesc',
      desc: '',
      args: [],
    );
  }

  /// `hockey, field`
  String get paHockeyField {
    return Intl.message(
      'hockey, field',
      name: 'paHockeyField',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paHockeyFieldDesc {
    return Intl.message(
      'general',
      name: 'paHockeyFieldDesc',
      desc: '',
      args: [],
    );
  }

  /// `ice hockey`
  String get paIceHockeyGeneral {
    return Intl.message(
      'ice hockey',
      name: 'paIceHockeyGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paIceHockeyGeneralDesc {
    return Intl.message(
      'general',
      name: 'paIceHockeyGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `horseback riding`
  String get paHorseRidingGeneral {
    return Intl.message(
      'horseback riding',
      name: 'paHorseRidingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paHorseRidingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paHorseRidingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `jai alai`
  String get paJaiAlai {
    return Intl.message(
      'jai alai',
      name: 'paJaiAlai',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paJaiAlaiDesc {
    return Intl.message(
      'general',
      name: 'paJaiAlaiDesc',
      desc: '',
      args: [],
    );
  }

  /// `martial arts`
  String get paMartialArtsSlower {
    return Intl.message(
      'martial arts',
      name: 'paMartialArtsSlower',
      desc: '',
      args: [],
    );
  }

  /// `different types, slower pace, novice performers, practice`
  String get paMartialArtsSlowerDesc {
    return Intl.message(
      'different types, slower pace, novice performers, practice',
      name: 'paMartialArtsSlowerDesc',
      desc: '',
      args: [],
    );
  }

  /// `martial arts`
  String get paMartialArtsModerate {
    return Intl.message(
      'martial arts',
      name: 'paMartialArtsModerate',
      desc: '',
      args: [],
    );
  }

  /// `different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)`
  String get paMartialArtsModerateDesc {
    return Intl.message(
      'different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)',
      name: 'paMartialArtsModerateDesc',
      desc: '',
      args: [],
    );
  }

  /// `juggling`
  String get paJuggling {
    return Intl.message(
      'juggling',
      name: 'paJuggling',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paJugglingDesc {
    return Intl.message(
      'general',
      name: 'paJugglingDesc',
      desc: '',
      args: [],
    );
  }

  /// `kickball`
  String get paKickball {
    return Intl.message(
      'kickball',
      name: 'paKickball',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paKickballDesc {
    return Intl.message(
      'general',
      name: 'paKickballDesc',
      desc: '',
      args: [],
    );
  }

  /// `lacrosse`
  String get paLacrosse {
    return Intl.message(
      'lacrosse',
      name: 'paLacrosse',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paLacrosseDesc {
    return Intl.message(
      'general',
      name: 'paLacrosseDesc',
      desc: '',
      args: [],
    );
  }

  /// `lawn bowling`
  String get paLawnBowling {
    return Intl.message(
      'lawn bowling',
      name: 'paLawnBowling',
      desc: '',
      args: [],
    );
  }

  /// `bocce ball, outdoor`
  String get paLawnBowlingDesc {
    return Intl.message(
      'bocce ball, outdoor',
      name: 'paLawnBowlingDesc',
      desc: '',
      args: [],
    );
  }

  /// `moto-cross`
  String get paMotoCross {
    return Intl.message(
      'moto-cross',
      name: 'paMotoCross',
      desc: '',
      args: [],
    );
  }

  /// `off-road motor sports, all-terrain vehicle, general`
  String get paMotoCrossDesc {
    return Intl.message(
      'off-road motor sports, all-terrain vehicle, general',
      name: 'paMotoCrossDesc',
      desc: '',
      args: [],
    );
  }

  /// `orienteering`
  String get paOrienteering {
    return Intl.message(
      'orienteering',
      name: 'paOrienteering',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paOrienteeringDesc {
    return Intl.message(
      'general',
      name: 'paOrienteeringDesc',
      desc: '',
      args: [],
    );
  }

  /// `paddleball`
  String get paPaddleball {
    return Intl.message(
      'paddleball',
      name: 'paPaddleball',
      desc: '',
      args: [],
    );
  }

  /// `casual, general`
  String get paPaddleballDesc {
    return Intl.message(
      'casual, general',
      name: 'paPaddleballDesc',
      desc: '',
      args: [],
    );
  }

  /// `polo`
  String get paPoloHorse {
    return Intl.message(
      'polo',
      name: 'paPoloHorse',
      desc: '',
      args: [],
    );
  }

  /// `on horseback`
  String get paPoloHorseDesc {
    return Intl.message(
      'on horseback',
      name: 'paPoloHorseDesc',
      desc: '',
      args: [],
    );
  }

  /// `racquetball`
  String get paRacquetball {
    return Intl.message(
      'racquetball',
      name: 'paRacquetball',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paRacquetballDesc {
    return Intl.message(
      'general',
      name: 'paRacquetballDesc',
      desc: '',
      args: [],
    );
  }

  /// `climbing`
  String get paMountainClimbing {
    return Intl.message(
      'climbing',
      name: 'paMountainClimbing',
      desc: '',
      args: [],
    );
  }

  /// `rock or mountain climbing`
  String get paMountainClimbingDesc {
    return Intl.message(
      'rock or mountain climbing',
      name: 'paMountainClimbingDesc',
      desc: '',
      args: [],
    );
  }

  /// `rodeo sports`
  String get paRodeoSportGeneralModerate {
    return Intl.message(
      'rodeo sports',
      name: 'paRodeoSportGeneralModerate',
      desc: '',
      args: [],
    );
  }

  /// `general, moderate effort`
  String get paRodeoSportGeneralModerateDesc {
    return Intl.message(
      'general, moderate effort',
      name: 'paRodeoSportGeneralModerateDesc',
      desc: '',
      args: [],
    );
  }

  /// `rope jumping`
  String get paRopeJumpingGeneral {
    return Intl.message(
      'rope jumping',
      name: 'paRopeJumpingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce`
  String get paRopeJumpingGeneralDesc {
    return Intl.message(
      'moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce',
      name: 'paRopeJumpingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `rugby`
  String get paRugbyCompetitive {
    return Intl.message(
      'rugby',
      name: 'paRugbyCompetitive',
      desc: '',
      args: [],
    );
  }

  /// `union, team, competitive`
  String get paRugbyCompetitiveDesc {
    return Intl.message(
      'union, team, competitive',
      name: 'paRugbyCompetitiveDesc',
      desc: '',
      args: [],
    );
  }

  /// `rugby`
  String get paRugbyNonCompetitive {
    return Intl.message(
      'rugby',
      name: 'paRugbyNonCompetitive',
      desc: '',
      args: [],
    );
  }

  /// `touch, non-competitive`
  String get paRugbyNonCompetitiveDesc {
    return Intl.message(
      'touch, non-competitive',
      name: 'paRugbyNonCompetitiveDesc',
      desc: '',
      args: [],
    );
  }

  /// `shuffleboard`
  String get paShuffleboard {
    return Intl.message(
      'shuffleboard',
      name: 'paShuffleboard',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paShuffleboardDesc {
    return Intl.message(
      'general',
      name: 'paShuffleboardDesc',
      desc: '',
      args: [],
    );
  }

  /// `skateboarding`
  String get paSkateboardingGeneral {
    return Intl.message(
      'skateboarding',
      name: 'paSkateboardingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general, moderate effort`
  String get paSkateboardingGeneralDesc {
    return Intl.message(
      'general, moderate effort',
      name: 'paSkateboardingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `roller skating`
  String get paSkatingRoller {
    return Intl.message(
      'roller skating',
      name: 'paSkatingRoller',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paSkatingRollerDesc {
    return Intl.message(
      'general',
      name: 'paSkatingRollerDesc',
      desc: '',
      args: [],
    );
  }

  /// `rollerblading`
  String get paRollerbladingLight {
    return Intl.message(
      'rollerblading',
      name: 'paRollerbladingLight',
      desc: '',
      args: [],
    );
  }

  /// `in-line skating`
  String get paRollerbladingLightDesc {
    return Intl.message(
      'in-line skating',
      name: 'paRollerbladingLightDesc',
      desc: '',
      args: [],
    );
  }

  /// `skydiving`
  String get paSkydiving {
    return Intl.message(
      'skydiving',
      name: 'paSkydiving',
      desc: '',
      args: [],
    );
  }

  /// `skydiving, base jumping, bungee jumping`
  String get paSkydivingDesc {
    return Intl.message(
      'skydiving, base jumping, bungee jumping',
      name: 'paSkydivingDesc',
      desc: '',
      args: [],
    );
  }

  /// `soccer`
  String get paSoccerGeneral {
    return Intl.message(
      'soccer',
      name: 'paSoccerGeneral',
      desc: '',
      args: [],
    );
  }

  /// `casual, general`
  String get paSoccerGeneralDesc {
    return Intl.message(
      'casual, general',
      name: 'paSoccerGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `softball / baseball`
  String get paSoftballBaseballGeneral {
    return Intl.message(
      'softball / baseball',
      name: 'paSoftballBaseballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `fast or slow pitch, general`
  String get paSoftballBaseballGeneralDesc {
    return Intl.message(
      'fast or slow pitch, general',
      name: 'paSoftballBaseballGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `squash`
  String get paSquashGeneral {
    return Intl.message(
      'squash',
      name: 'paSquashGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paSquashGeneralDesc {
    return Intl.message(
      'general',
      name: 'paSquashGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `table tennis`
  String get paTableTennisGeneral {
    return Intl.message(
      'table tennis',
      name: 'paTableTennisGeneral',
      desc: '',
      args: [],
    );
  }

  /// `table tennis, ping pong`
  String get paTableTennisGeneralDesc {
    return Intl.message(
      'table tennis, ping pong',
      name: 'paTableTennisGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `tai chi, qi gong`
  String get paTaiChiQiGongGeneral {
    return Intl.message(
      'tai chi, qi gong',
      name: 'paTaiChiQiGongGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paTaiChiQiGongGeneralDesc {
    return Intl.message(
      'general',
      name: 'paTaiChiQiGongGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `tennis`
  String get paTennisGeneral {
    return Intl.message(
      'tennis',
      name: 'paTennisGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paTennisGeneralDesc {
    return Intl.message(
      'general',
      name: 'paTennisGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `trampoline`
  String get paTrampolineLight {
    return Intl.message(
      'trampoline',
      name: 'paTrampolineLight',
      desc: '',
      args: [],
    );
  }

  /// `recreational`
  String get paTrampolineLightDesc {
    return Intl.message(
      'recreational',
      name: 'paTrampolineLightDesc',
      desc: '',
      args: [],
    );
  }

  /// `volleyball`
  String get paVolleyballGeneral {
    return Intl.message(
      'volleyball',
      name: 'paVolleyballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `non-competitive, 6 - 9 member team, general`
  String get paVolleyballGeneralDesc {
    return Intl.message(
      'non-competitive, 6 - 9 member team, general',
      name: 'paVolleyballGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `wrestling`
  String get paWrestling {
    return Intl.message(
      'wrestling',
      name: 'paWrestling',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paWrestlingDesc {
    return Intl.message(
      'general',
      name: 'paWrestlingDesc',
      desc: '',
      args: [],
    );
  }

  /// `wallyball`
  String get paWallyball {
    return Intl.message(
      'wallyball',
      name: 'paWallyball',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paWallyballDesc {
    return Intl.message(
      'general',
      name: 'paWallyballDesc',
      desc: '',
      args: [],
    );
  }

  /// `track and field`
  String get paTrackField {
    return Intl.message(
      'track and field',
      name: 'paTrackField',
      desc: '',
      args: [],
    );
  }

  /// `(e.g. shot, discus, hammer throw)`
  String get paTrackField1Desc {
    return Intl.message(
      '(e.g. shot, discus, hammer throw)',
      name: 'paTrackField1Desc',
      desc: '',
      args: [],
    );
  }

  /// `(e.g. high jump, long jump, triple jump, javelin, pole vault)`
  String get paTrackField2Desc {
    return Intl.message(
      '(e.g. high jump, long jump, triple jump, javelin, pole vault)',
      name: 'paTrackField2Desc',
      desc: '',
      args: [],
    );
  }

  /// `(e.g. steeplechase, hurdles)`
  String get paTrackField3Desc {
    return Intl.message(
      '(e.g. steeplechase, hurdles)',
      name: 'paTrackField3Desc',
      desc: '',
      args: [],
    );
  }

  /// `backpacking`
  String get paBackpackingGeneral {
    return Intl.message(
      'backpacking',
      name: 'paBackpackingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBackpackingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBackpackingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `climbing hills, no load`
  String get paClimbingHillsNoLoadGeneral {
    return Intl.message(
      'climbing hills, no load',
      name: 'paClimbingHillsNoLoadGeneral',
      desc: '',
      args: [],
    );
  }

  /// `no load`
  String get paClimbingHillsNoLoadGeneralDesc {
    return Intl.message(
      'no load',
      name: 'paClimbingHillsNoLoadGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `hiking`
  String get paHikingCrossCountry {
    return Intl.message(
      'hiking',
      name: 'paHikingCrossCountry',
      desc: '',
      args: [],
    );
  }

  /// `cross country`
  String get paHikingCrossCountryDesc {
    return Intl.message(
      'cross country',
      name: 'paHikingCrossCountryDesc',
      desc: '',
      args: [],
    );
  }

  /// `walking`
  String get paWalkingForPleasure {
    return Intl.message(
      'walking',
      name: 'paWalkingForPleasure',
      desc: '',
      args: [],
    );
  }

  /// `for pleasure`
  String get paWalkingForPleasureDesc {
    return Intl.message(
      'for pleasure',
      name: 'paWalkingForPleasureDesc',
      desc: '',
      args: [],
    );
  }

  /// `walking the dog`
  String get paWalkingTheDog {
    return Intl.message(
      'walking the dog',
      name: 'paWalkingTheDog',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paWalkingTheDogDesc {
    return Intl.message(
      'general',
      name: 'paWalkingTheDogDesc',
      desc: '',
      args: [],
    );
  }

  /// `canoeing`
  String get paCanoeingGeneral {
    return Intl.message(
      'canoeing',
      name: 'paCanoeingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `rowing, for pleasure, general`
  String get paCanoeingGeneralDesc {
    return Intl.message(
      'rowing, for pleasure, general',
      name: 'paCanoeingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `diving`
  String get paDivingSpringboardPlatform {
    return Intl.message(
      'diving',
      name: 'paDivingSpringboardPlatform',
      desc: '',
      args: [],
    );
  }

  /// `springboard or platform`
  String get paDivingSpringboardPlatformDesc {
    return Intl.message(
      'springboard or platform',
      name: 'paDivingSpringboardPlatformDesc',
      desc: '',
      args: [],
    );
  }

  /// `kayaking`
  String get paKayakingModerate {
    return Intl.message(
      'kayaking',
      name: 'paKayakingModerate',
      desc: '',
      args: [],
    );
  }

  /// `moderate effort`
  String get paKayakingModerateDesc {
    return Intl.message(
      'moderate effort',
      name: 'paKayakingModerateDesc',
      desc: '',
      args: [],
    );
  }

  /// `paddle boat`
  String get paPaddleBoat {
    return Intl.message(
      'paddle boat',
      name: 'paPaddleBoat',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paPaddleBoatDesc {
    return Intl.message(
      'general',
      name: 'paPaddleBoatDesc',
      desc: '',
      args: [],
    );
  }

  /// `sailing`
  String get paSailingGeneral {
    return Intl.message(
      'sailing',
      name: 'paSailingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `boat and board sailing, windsurfing, ice sailing, general`
  String get paSailingGeneralDesc {
    return Intl.message(
      'boat and board sailing, windsurfing, ice sailing, general',
      name: 'paSailingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `water skiing`
  String get paSkiingWaterWakeboarding {
    return Intl.message(
      'water skiing',
      name: 'paSkiingWaterWakeboarding',
      desc: '',
      args: [],
    );
  }

  /// `water or wakeboarding`
  String get paSkiingWaterWakeboardingDesc {
    return Intl.message(
      'water or wakeboarding',
      name: 'paSkiingWaterWakeboardingDesc',
      desc: '',
      args: [],
    );
  }

  /// `diving`
  String get paDivingGeneral {
    return Intl.message(
      'diving',
      name: 'paDivingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `skindiving, scuba diving, general`
  String get paDivingGeneralDesc {
    return Intl.message(
      'skindiving, scuba diving, general',
      name: 'paDivingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `snorkeling`
  String get paSnorkeling {
    return Intl.message(
      'snorkeling',
      name: 'paSnorkeling',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paSnorkelingDesc {
    return Intl.message(
      'general',
      name: 'paSnorkelingDesc',
      desc: '',
      args: [],
    );
  }

  /// `surfing`
  String get paSurfing {
    return Intl.message(
      'surfing',
      name: 'paSurfing',
      desc: '',
      args: [],
    );
  }

  /// `body or board, general`
  String get paSurfingDesc {
    return Intl.message(
      'body or board, general',
      name: 'paSurfingDesc',
      desc: '',
      args: [],
    );
  }

  /// `paddle boarding`
  String get paPaddleBoarding {
    return Intl.message(
      'paddle boarding',
      name: 'paPaddleBoarding',
      desc: '',
      args: [],
    );
  }

  /// `standing`
  String get paPaddleBoardingDesc {
    return Intl.message(
      'standing',
      name: 'paPaddleBoardingDesc',
      desc: '',
      args: [],
    );
  }

  /// `swimming`
  String get paSwimmingGeneral {
    return Intl.message(
      'swimming',
      name: 'paSwimmingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `treading water, moderate effort, general`
  String get paSwimmingGeneralDesc {
    return Intl.message(
      'treading water, moderate effort, general',
      name: 'paSwimmingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `water aerobics`
  String get paWateraerobicsCalisthenics {
    return Intl.message(
      'water aerobics',
      name: 'paWateraerobicsCalisthenics',
      desc: '',
      args: [],
    );
  }

  /// `water aerobics, water calisthenics`
  String get paWateraerobicsCalisthenicsDesc {
    return Intl.message(
      'water aerobics, water calisthenics',
      name: 'paWateraerobicsCalisthenicsDesc',
      desc: '',
      args: [],
    );
  }

  /// `water polo`
  String get paWaterPolo {
    return Intl.message(
      'water polo',
      name: 'paWaterPolo',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paWaterPoloDesc {
    return Intl.message(
      'general',
      name: 'paWaterPoloDesc',
      desc: '',
      args: [],
    );
  }

  /// `water volleyball`
  String get paWaterVolleyball {
    return Intl.message(
      'water volleyball',
      name: 'paWaterVolleyball',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paWaterVolleyballDesc {
    return Intl.message(
      'general',
      name: 'paWaterVolleyballDesc',
      desc: '',
      args: [],
    );
  }

  /// `ice skating`
  String get paIceSkatingGeneral {
    return Intl.message(
      'ice skating',
      name: 'paIceSkatingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paIceSkatingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paIceSkatingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `skiing`
  String get paSkiingGeneral {
    return Intl.message(
      'skiing',
      name: 'paSkiingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paSkiingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paSkiingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `snow shoveling`
  String get paSnowShovingModerate {
    return Intl.message(
      'snow shoveling',
      name: 'paSnowShovingModerate',
      desc: '',
      args: [],
    );
  }

  /// `by hand, moderate effort`
  String get paSnowShovingModerateDesc {
    return Intl.message(
      'by hand, moderate effort',
      name: 'paSnowShovingModerateDesc',
      desc: '',
      args: [],
    );
  }

  /// `e.g. biking`
  String get exampleOfActivityLabel {
    return Intl.message(
      'e.g. biking',
      name: 'exampleOfActivityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Recipe`
  String get recipeLabel {
    return Intl.message(
      'Recipe',
      name: 'recipeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Create a meal`
  String get createRecipeLabel {
    return Intl.message(
      'Create a meal',
      name: 'createRecipeLabel',
      desc: '',
      args: [],
    );
  }

  /// `No recipe found`
  String get errorRecipeLabel {
    return Intl.message(
      'No recipe found',
      name: 'errorRecipeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Number of portions`
  String get mealPortionLabel {
    return Intl.message(
      'Number of portions',
      name: 'mealPortionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Portion eaten`
  String get portionEatLabel {
    return Intl.message(
      'Portion eaten',
      name: 'portionEatLabel',
      desc: '',
      args: [],
    );
  }

  /// `No food added`
  String get noFoodAddedLabel {
    return Intl.message(
      'No food added',
      name: 'noFoodAddedLabel',
      desc: '',
      args: [],
    );
  }

  /// `My students`
  String get myStudentsTitle {
    return Intl.message(
      'My students',
      name: 'myStudentsTitle',
      desc: '',
      args: [],
    );
  }

  /// `No students`
  String get noStudents {
    return Intl.message(
      'No students',
      name: 'noStudents',
      desc: '',
      args: [],
    );
  }

  /// `Error:`
  String get errorPrefix {
    return Intl.message(
      'Error:',
      name: 'errorPrefix',
      desc: '',
      args: [],
    );
  }

  /// `No data for today`
  String get noDataToday {
    return Intl.message(
      'No data for today',
      name: 'noDataToday',
      desc: '',
      args: [],
    );
  }

  /// `You can only sign out when internet connection is available to avoid losing data.`
  String get signOutOfflineMessage {
    return Intl.message(
      'You can only sign out when internet connection is available to avoid losing data.',
      name: 'signOutOfflineMessage',
      desc: '',
      args: [],
    );
  }

  /// `Failed to sync your data. Please sign in again later.`
  String get signOutSyncFailedMessage {
    return Intl.message(
      'Failed to sync your data. Please sign in again later.',
      name: 'signOutSyncFailedMessage',
      desc: '',
      args: [],
    );
  }

  /// `My students`
  String get coachStudentsLabel {
    return Intl.message(
      'My students',
      name: 'coachStudentsLabel',
      desc: '',
      args: [],
    );
  }

  /// `No internet connection. Feature unavailable.`
  String get noInternetConnectionMessage {
    return Intl.message(
      'No internet connection. Feature unavailable.',
      name: 'noInternetConnectionMessage',
      desc: '',
      args: [],
    );
  }

  /// `Set macros`
  String get setMacrosLabel {
    return Intl.message(
      'Set macros',
      name: 'setMacrosLabel',
      desc: '',
      args: [],
    );
  }

  /// `Manage account`
  String get manageAccountTitle {
    return Intl.message(
      'Manage account',
      name: 'manageAccountTitle',
      desc: '',
      args: [],
    );
  }

  /// `We only collect data essential to the proper functioning of the app:\n\nEmail address: used for login and account identification.\n\nNutrition data: your daily weight, calories, protein, fat, and carbohydrate intake.\n\nGoals: your personalized targets for calories, protein, fat, and carbs.\n\nAll data is securely stored on Supabase. We do not share any of your data with third parties.`
  String get manageAccountDescription {
    return Intl.message(
      'We only collect data essential to the proper functioning of the app:\n\nEmail address: used for login and account identification.\n\nNutrition data: your daily weight, calories, protein, fat, and carbohydrate intake.\n\nGoals: your personalized targets for calories, protein, fat, and carbs.\n\nAll data is securely stored on Supabase. We do not share any of your data with third parties.',
      name: 'manageAccountDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enable Supabase Sync`
  String get manageAccountEnableSync {
    return Intl.message(
      'Enable Supabase Sync',
      name: 'manageAccountEnableSync',
      desc: '',
      args: [],
    );
  }

  /// `Delete My Account`
  String get manageAccountDelete {
    return Intl.message(
      'Delete My Account',
      name: 'manageAccountDelete',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure?`
  String get manageAccountConfirmTitle {
    return Intl.message(
      'Are you sure?',
      name: 'manageAccountConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `This action cannot be undone.`
  String get manageAccountConfirmMessage {
    return Intl.message(
      'This action cannot be undone.',
      name: 'manageAccountConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Deletion`
  String get manageAccountConfirmAction {
    return Intl.message(
      'Confirm Deletion',
      name: 'manageAccountConfirmAction',
      desc: '',
      args: [],
    );
  }

  /// `Log out`
  String get logOutLabel {
    return Intl.message(
      'Log out',
      name: 'logOutLabel',
      desc: '',
      args: [],
    );
  }

  /// `If the password reset doesn't work:\n- exit the app and try again, or\n- make the request from the website: `
  String get forgotPasswordHelp {
    return Intl.message(
      'If the password reset doesn\'t work:\n- exit the app and try again, or\n- make the request from the website: ',
      name: 'forgotPasswordHelp',
      desc: '',
      args: [],
    );
  }

  /// `website`
  String get websiteLabel {
    return Intl.message(
      'website',
      name: 'websiteLabel',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'tr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
