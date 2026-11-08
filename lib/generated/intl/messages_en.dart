// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(versionNumber) => "Version ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% carbs, ${pctFats}% fats, ${pctProteins}% proteins";

  static String m2(amount) => "+${amount} kcal above goal";

  static String m3(unit) => "Values per 100 ${unit}";

  static String m4(reason) => "Failed to delete: ${reason}";

  static String m5(date) => "Last logged day: ${date}";

  static String m6(riskValue) => "Risk of comorbidities: ${riskValue}";

  static String m7(date) => "Last goal applied on ${date}";

  static String m23(min, max, unit) =>
      "Enter a value between ${min} and ${max} ${unit}.";

  static String m8(count) =>
      "${Intl.plural(count, one: '${count} serving', other: '${count} servings')}";

  static String m9(portions, weight) => "${portions} (${weight})";

  static String m10(count) =>
      "${Intl.plural(count, one: 'See ${count} more food', other: 'See ${count} more foods')}";

  static String m11(message) => "Supabase error: ${message}";

  static String m12(count, total) => "${count}/${total} days";

  static String m13(value) => "${value} vs goal";

  static String m14(period) => "Avg ${period}";

  static String m15(period) => "Change ${period}";

  static String m16(date) => "Weigh-in for ${date}";

  static String m17(goal) => "Goal: ${goal}";

  static String m18(value, unit) => "Period average: ${value} ${unit}";

  static String m19(period) => "Average over ${period}";

  static String m20(period) => "Change over ${period}";

  static String m21(count) =>
      "${Intl.plural(count, one: '${count} weigh-in', other: '${count} weigh-ins')}";

  static String m22(age) => "${age} years";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountDeletedSuccess": MessageLookupByLibrary.simpleMessage(
            "Account successfully deleted."),
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "e.g. running, biking, yoga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Activity"),
        "addIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Add an ingredient"),
        "addItemLabel": MessageLookupByLibrary.simpleMessage("Add new Item:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Add"),
        "addRecipeToDiary": MessageLookupByLibrary.simpleMessage(
            "Also add one serving to the diary"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Information provided\n by the \n\'2011 Compendium\n of Physical Activities\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Custom Meal Item"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "More Information at\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "More Information at\nOpenFoodFacts"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Unknown Meal Item"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Age"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("All"),
        "allTimeLabel": MessageLookupByLibrary.simpleMessage("All"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "AtlasTracker is a free and open-source calorie and nutrient tracker that respects your privacy."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("GPL-3.0 license"),
        "appTitle": MessageLookupByLibrary.simpleMessage("ATLAS TRACKER"),
        "appVersionName": m0,
        "authRateLimit": MessageLookupByLibrary.simpleMessage(
            "Too many attempts. Please wait before trying again."),
        "authRetryError": MessageLookupByLibrary.simpleMessage(
            "The request failed. Check your connection and try again."),
        "averageWeightBody": MessageLookupByLibrary.simpleMessage(
            "Average user weight over the last seven days. The current day is not counted."),
        "averageWeightLabel":
            MessageLookupByLibrary.simpleMessage("Average Weight"),
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Base quantity (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "Body Mass Index (BMI) is a index to classify overweight and obesity in adults. It is defined as weight in kilograms divided by the square of height in meters (kg/m²).\n\nBMI does not differentiate between fat and muscle mass and can be misleading for some individuals."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "bodyGoalPreviewDescription": MessageLookupByLibrary.simpleMessage(
            "Bulking, cutting or maintenance: macros will adapt to the target weight."),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "e.g. cereal, milk, coffee ..."),
        "breakfastLabel": MessageLookupByLibrary.simpleMessage("Breakfast"),
        "buttonNextLabel": MessageLookupByLibrary.simpleMessage("NEXT"),
        "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Reset"),
        "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Save"),
        "buttonStartLabel": MessageLookupByLibrary.simpleMessage("START"),
        "buttonYesLabel": MessageLookupByLibrary.simpleMessage("YES"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Macros distribution"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(recommended)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Institute of Medicine Equation"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("TDEE equation"),
        "caloriesAboveGoal": m2,
        "caloriesLabel": MessageLookupByLibrary.simpleMessage("Calories"),
        "carbohydrateLabel":
            MessageLookupByLibrary.simpleMessage("carbohydrate"),
        "carbohydratesLabel":
            MessageLookupByLibrary.simpleMessage("Carbohydrates"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("carbs"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Choose Weight Goal"),
        "cloudSyncProblem": MessageLookupByLibrary.simpleMessage(
            "Cloud synchronization problem."),
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "coachLoggedToday":
            MessageLookupByLibrary.simpleMessage("logged today"),
        "coachStudentsLabel":
            MessageLookupByLibrary.simpleMessage("My students"),
        "coachTodayTitle":
            MessageLookupByLibrary.simpleMessage("Daily check-in"),
        "codeCooldownHelp": MessageLookupByLibrary.simpleMessage(
            "You can resend a code after 30 seconds."),
        "codeSentLabel":
            MessageLookupByLibrary.simpleMessage("A new code has been sent."),
        "comingSoonLabel": MessageLookupByLibrary.simpleMessage("Coming soon"),
        "consumedLabel": MessageLookupByLibrary.simpleMessage("consumed"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Which meal type do you want to copy to?"),
        "copyFromYesterdayLabel":
            MessageLookupByLibrary.simpleMessage("Copy from yesterday"),
        "copyIntakeLabel": MessageLookupByLibrary.simpleMessage("Copy"),
        "copyMealLabel": MessageLookupByLibrary.simpleMessage("Copy meal"),
        "copyMealTargetDateLabel":
            MessageLookupByLibrary.simpleMessage("Destination day"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "With \"Copy to today\" you can copy the meal to today. With \"Delete\" you can delete the meal."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("What do you want to do?"),
        "crashReportsConsentHelp": MessageLookupByLibrary.simpleMessage(
            "Optional. Share technical reports with Firebase Crashlytics to help fix errors. You can withdraw your consent here."),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Do you want create a custom meal item?"),
        "createCustomDialogTitle":
            MessageLookupByLibrary.simpleMessage("Create custom meal item?"),
        "createRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Create a recipe"),
        "currentWeightLabel":
            MessageLookupByLibrary.simpleMessage("current weight"),
        "customFoodAddPhoto":
            MessageLookupByLibrary.simpleMessage("Add a photo"),
        "customFoodChangePhoto":
            MessageLookupByLibrary.simpleMessage("Change photo"),
        "customFoodNameError":
            MessageLookupByLibrary.simpleMessage("Enter a food name."),
        "customFoodNameLabel":
            MessageLookupByLibrary.simpleMessage("Food name"),
        "customFoodNumberError": MessageLookupByLibrary.simpleMessage(
            "Enter a non-negative number."),
        "customFoodOptionalDetails":
            MessageLookupByLibrary.simpleMessage("Optional details"),
        "customFoodPer100": m3,
        "customFoodPerPortion":
            MessageLookupByLibrary.simpleMessage("Values per portion"),
        "customFoodPhotoError": MessageLookupByLibrary.simpleMessage(
            "Unable to load or save this photo. Please try again."),
        "customFoodPortionHint":
            MessageLookupByLibrary.simpleMessage("e.g. 6 nuggets"),
        "customFoodPortionMode":
            MessageLookupByLibrary.simpleMessage("1 serving"),
        "customFoodPortionName":
            MessageLookupByLibrary.simpleMessage("Portion name (optional)"),
        "customFoodQuantityMode":
            MessageLookupByLibrary.simpleMessage("100 g / 100 ml"),
        "customFoodReferenceHelp": MessageLookupByLibrary.simpleMessage(
            "Enter the values for this reference. Choose the amount consumed on the next screen."),
        "customFoodTitle": MessageLookupByLibrary.simpleMessage("Custom food"),
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Daily Kcal adjustment:"),
        "dailyMacroGoalsTitle":
            MessageLookupByLibrary.simpleMessage("Daily targets"),
        "dailySummaryLabel":
            MessageLookupByLibrary.simpleMessage("Day summary"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Support development by providing anonymous usage data"),
        "dayMacrosTitle": MessageLookupByLibrary.simpleMessage("Macros"),
        "decreaseWeightLabel":
            MessageLookupByLibrary.simpleMessage("Decrease weight"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Delete all"),
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Do want to delete the selected item?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Do want to delete all items of this meal?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Delete Items?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Delete Item?"),
        "deleteWeightCardTitle":
            MessageLookupByLibrary.simpleMessage("Delete this weight"),
        "deltaWeightBody": MessageLookupByLibrary.simpleMessage(
            "The weight delta is the difference between the average weight and the current weight entered for this day.\nIf no weight is recorded for the current day, the last valid weight will be used."),
        "deltaWeightLabel":
            MessageLookupByLibrary.simpleMessage("Weight Delta"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("CANCEL"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("Copy to today"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("DELETE"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Diary"),
        "dinnerExample": MessageLookupByLibrary.simpleMessage(
            "e.g. soup, chicken, wine ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Dinner"),
        "discardChangesLabel":
            MessageLookupByLibrary.simpleMessage("Leave without saving"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Edit item"),
        "editLabel": MessageLookupByLibrary.simpleMessage("Edit"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Edit meal"),
        "editRecipeLabel": MessageLookupByLibrary.simpleMessage("Edit recipe"),
        "editWeightLabel": MessageLookupByLibrary.simpleMessage("Edit weight"),
        "emptyValueLabel": MessageLookupByLibrary.simpleMessage("-"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("energy"),
        "enterCodeLabel":
            MessageLookupByLibrary.simpleMessage("Verification code"),
        "enterManuallyLabel":
            MessageLookupByLibrary.simpleMessage("Enter manually"),
        "enterValidMacrosHelp": MessageLookupByLibrary.simpleMessage(
            "Enter all three macros (0–1,000 g). Total energy must be greater than zero and at most 10,000 kcal."),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Error while fetching product data"),
        "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
            "Error while loading activities"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Error while saving meal. Did you input the correct meal information?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Error while opening browser app"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "Error while opening email app"),
        "errorPrefix": MessageLookupByLibrary.simpleMessage("Error:"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Product not found"),
        "errorRecipeLabel":
            MessageLookupByLibrary.simpleMessage("No recipe found"),
        "evolutionLabel": MessageLookupByLibrary.simpleMessage("Evolution"),
        "exampleOfActivityLabel":
            MessageLookupByLibrary.simpleMessage("e.g. biking"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Export"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "You can export the app data to a zip file and import it later. This is useful if you want to backup your data or transfer it to another device.\n\nThe app does not use any cloud service to store your data."),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Export / Import error"),
        "exportImportLabel":
            MessageLookupByLibrary.simpleMessage("Export / Import data"),
        "exportImportSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Export / Import successful"),
        "exportImportSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Backup your data to Supabase storage as a zip file or restore it from there."),
        "exportImportSupabaseLabel": MessageLookupByLibrary.simpleMessage(
            "Export / Import with Supabase"),
        "exportSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Backup your data to Supabase storage as a zip file."),
        "exportSupabaseLabel":
            MessageLookupByLibrary.simpleMessage("Export to Supabase"),
        "failedToDeleteWithReason": m4,
        "fatLabel": MessageLookupByLibrary.simpleMessage("fat"),
        "fatsLabel": MessageLookupByLibrary.simpleMessage("Fats"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("fiber"),
        "forgotPasswordBackToLogin":
            MessageLookupByLibrary.simpleMessage("Back to sign in"),
        "forgotPasswordButton":
            MessageLookupByLibrary.simpleMessage("Send password reset email"),
        "forgotPasswordEmailLabel":
            MessageLookupByLibrary.simpleMessage("Enter your email"),
        "forgotPasswordEmailSent": MessageLookupByLibrary.simpleMessage(
            "Email sent! Click the link in your email to choose a new password."),
        "forgotPasswordHelp": MessageLookupByLibrary.simpleMessage(
            "If the password reset doesn\'t work:\n- exit the app and try again, or\n- make the request from the website: "),
        "forgotPasswordSendError":
            MessageLookupByLibrary.simpleMessage("Error sending email:"),
        "forgotPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Forgot your password?"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("female"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Gender"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("male"),
        "genericErrorOccurred":
            MessageLookupByLibrary.simpleMessage("An error occurred."),
        "goalGainWeight": MessageLookupByLibrary.simpleMessage("Gain Weight"),
        "goalGainWeightDashboard":
            MessageLookupByLibrary.simpleMessage("Muscle gain"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Goal"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Lose Weight"),
        "goalLoseWeightDashboard":
            MessageLookupByLibrary.simpleMessage("Weight loss"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Maintain Weight"),
        "goalMaintainWeightDashboard":
            MessageLookupByLibrary.simpleMessage("Weight maintenance"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Height"),
        "helloLabel": MessageLookupByLibrary.simpleMessage("Hello"),
        "hidePasswordLabel":
            MessageLookupByLibrary.simpleMessage("Hide password"),
        "historyLabel": MessageLookupByLibrary.simpleMessage("History"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Home"),
        "importAction": MessageLookupByLibrary.simpleMessage("Import"),
        "importSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Restore your data from a backup stored in Supabase."),
        "importSupabaseLabel":
            MessageLookupByLibrary.simpleMessage("Import from Supabase"),
        "increaseWeightLabel":
            MessageLookupByLibrary.simpleMessage("Increase weight"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Added new activity"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Added new intake"),
        "intakeSaveError": MessageLookupByLibrary.simpleMessage(
            "The food could not be saved. Please retry."),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Item deleted"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Item updated"),
        "journalLoadError": MessageLookupByLibrary.simpleMessage(
            "Your data could not be loaded. Please retry."),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal left"),
        "kcalMacrosLabel":
            MessageLookupByLibrary.simpleMessage("kcal • macros"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lastFourteenDaysLabel":
            MessageLookupByLibrary.simpleMessage("Last 14 days"),
        "lastJournalDay": m5,
        "lastMonthLabel": MessageLookupByLibrary.simpleMessage("1 month"),
        "lastSevenDaysLabel":
            MessageLookupByLibrary.simpleMessage("Last 7 days"),
        "lastSixMonthsLabel": MessageLookupByLibrary.simpleMessage("6 months"),
        "lastThreeMonthsLabel":
            MessageLookupByLibrary.simpleMessage("3 months"),
        "lastYearLabel": MessageLookupByLibrary.simpleMessage("1 year"),
        "learnMoreLabel": MessageLookupByLibrary.simpleMessage(
            "Learn more: atlas-tracker.fr"),
        "logOutLabel": MessageLookupByLibrary.simpleMessage("Log out"),
        "loginAlreadySignedIn": MessageLookupByLibrary.simpleMessage(
            "Already signed in on another device. Please sign out first."),
        "loginButton": MessageLookupByLibrary.simpleMessage("Sign In"),
        "loginCoachAccountHelp": MessageLookupByLibrary.simpleMessage(
            "Your coach creates your account. Sign in with the credentials you received."),
        "loginEmailInvalid":
            MessageLookupByLibrary.simpleMessage("Invalid email address"),
        "loginEmailLabel": MessageLookupByLibrary.simpleMessage("Email"),
        "loginEmailRequired":
            MessageLookupByLibrary.simpleMessage("Email required"),
        "loginError": MessageLookupByLibrary.simpleMessage("Sign in error"),
        "loginForgotPassword":
            MessageLookupByLibrary.simpleMessage("Forgot password?"),
        "loginInvalidCredentials": MessageLookupByLibrary.simpleMessage(
            "The email address or password is incorrect."),
        "loginPasswordLabel": MessageLookupByLibrary.simpleMessage("Password"),
        "loginProfileUnavailable": MessageLookupByLibrary.simpleMessage(
            "Your profile is not available yet. Please contact your coach."),
        "loginTitle": MessageLookupByLibrary.simpleMessage("Sign In"),
        "loginUnknownError":
            MessageLookupByLibrary.simpleMessage("Unknown error"),
        "lunchExample":
            MessageLookupByLibrary.simpleMessage("e.g. pizza, salad, rice ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Lunch"),
        "macroCaloriesExplanation": MessageLookupByLibrary.simpleMessage(
            "Calories calculated from macronutrients."),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Macronutrient Distribution:"),
        "macroDistributionTitle":
            MessageLookupByLibrary.simpleMessage("Macro distribution"),
        "macroGoalHistoryEmpty": MessageLookupByLibrary.simpleMessage(
            "The history of target changes will appear here."),
        "macroGoalsSaved": MessageLookupByLibrary.simpleMessage("Goals saved."),
        "macroGoalsTabLabel": MessageLookupByLibrary.simpleMessage("Targets"),
        "manageAccountConfirmAction":
            MessageLookupByLibrary.simpleMessage("Confirm Deletion"),
        "manageAccountConfirmMessage": MessageLookupByLibrary.simpleMessage(
            "This action cannot be undone."),
        "manageAccountConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Are you sure?"),
        "manageAccountDelete":
            MessageLookupByLibrary.simpleMessage("Delete My Account"),
        "manageAccountDescription": MessageLookupByLibrary.simpleMessage(
            "We only collect data essential to the proper functioning of the app:\n\nEmail address: used for login and account identification.\n\nNutrition data: your daily weight, calories, protein, fat, and carbohydrate intake.\n\nGoals: your personalized targets for calories, protein, fat, and carbs.\n\nAll data is securely stored on Supabase. We do not share any of your data with third parties."),
        "manageAccountEnableSync":
            MessageLookupByLibrary.simpleMessage("Enable Supabase Sync"),
        "manageAccountTitle":
            MessageLookupByLibrary.simpleMessage("Manage account"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Brands"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("carbs per"),
        "mealCopiedSnackbar":
            MessageLookupByLibrary.simpleMessage("Meal copied"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("fat per"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal per"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Meal name"),
        "mealPortionLabel":
            MessageLookupByLibrary.simpleMessage("Number of portions"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("protein per 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Meal size (g/ml)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Meal unit"),
        "mealsOfDayLabel":
            MessageLookupByLibrary.simpleMessage("Today’s meals"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "minutesAbbrevLabel": MessageLookupByLibrary.simpleMessage("min"),
        "missingNutrientsDialogContent": MessageLookupByLibrary.simpleMessage(
            "Oops! This product sheet seems incomplete. Would you like to manually enter the missing nutritional information so you can save it?"),
        "missingNutrientsDialogTitle":
            MessageLookupByLibrary.simpleMessage("Missing data"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Product missing required kcal or macronutrients information"),
        "moveIntakeLabel": MessageLookupByLibrary.simpleMessage("Move"),
        "myStudentsTitle": MessageLookupByLibrary.simpleMessage("My students"),
        "nextLabel": MessageLookupByLibrary.simpleMessage("Next"),
        "noActivityRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("No activity recently added"),
        "noDataToday":
            MessageLookupByLibrary.simpleMessage("No data for today"),
        "noFoodAddedLabel":
            MessageLookupByLibrary.simpleMessage("No food added"),
        "noFoodYesterdayLabel": MessageLookupByLibrary.simpleMessage(
            "No food was logged for this meal yesterday."),
        "noInternetConnectionMessage": MessageLookupByLibrary.simpleMessage(
            "No internet connection. Feature unavailable."),
        "noMealsRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("No meals recently added"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "noStudents": MessageLookupByLibrary.simpleMessage("No students"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/A"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Nothing added"),
        "notificationActivationError": MessageLookupByLibrary.simpleMessage(
            "Notification activation problem. Please try again later."),
        "notificationsLabel":
            MessageLookupByLibrary.simpleMessage("Notifications"),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Nutrition Information"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Normal Weight"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Obesity Class I"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Obesity Class II"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Obesity Class III"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Pre-obesity"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Average"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Increased"),
        "nutritionalStatusRiskLabel": m6,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Low \n(but risk of other \nclinical problems increased)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Moderate"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Severe"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Very severe"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Underweight"),
        "overviewLabel": MessageLookupByLibrary.simpleMessage("Overview"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("football"),
        "paAmericanFootballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("touch, flag, general"),
        "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("archery"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("non-hunting"),
        "paAutoRacing": MessageLookupByLibrary.simpleMessage("auto racing"),
        "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("open wheel"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("backpacking"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "social singles and doubles, general"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("basketball"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("bicycling"),
        "paBicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("bicycling, mountain"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("bicycling, stationary"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("billiards"),
        "paBilliardsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("boxing"),
        "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("punching bag"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boxing"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("in ring, general"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("calisthenics"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "light or moderate effort, general (e.g., back exercises)"),
        "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("canoeing"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "rowing, for pleasure, general"),
        "paCatch": MessageLookupByLibrary.simpleMessage("football or baseball"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("playing catch"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("cheerleading"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
            "gymnastic moves, competitive"),
        "paChildrenGame":
            MessageLookupByLibrary.simpleMessage("children’s games"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort"),
        "paClimbingHillsNoLoadGeneral":
            MessageLookupByLibrary.simpleMessage("climbing hills, no load"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("no load"),
        "paCricket": MessageLookupByLibrary.simpleMessage("cricket"),
        "paCricketDesc":
            MessageLookupByLibrary.simpleMessage("batting, bowling, fielding"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("croquet"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aerobic"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paDancingGeneral":
            MessageLookupByLibrary.simpleMessage("general dancing"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "e.g. disco, folk, Irish step dancing, line dancing, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("darts"),
        "paDartsWallDesc": MessageLookupByLibrary.simpleMessage("wall or lawn"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("diving"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "skindiving, scuba diving, general"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("diving"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("springboard or platform"),
        "paFencing": MessageLookupByLibrary.simpleMessage("fencing"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("frisbee playing"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("gymnastics"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("handball"),
        "paHandballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("hang gliding"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("bicycling"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("conditioning exercise"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("dancing"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("running"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("sports"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("walking"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("water activities"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("winter activities"),
        "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("hiking"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("cross country"),
        "paHockeyField": MessageLookupByLibrary.simpleMessage("hockey, field"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("horseback riding"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("ice hockey"),
        "paIceHockeyGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("ice skating"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("juggling"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kayaking"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("moderate effort"),
        "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lacrosse"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paLawnBowling": MessageLookupByLibrary.simpleMessage("lawn bowling"),
        "paLawnBowlingDesc":
            MessageLookupByLibrary.simpleMessage("bocce ball, outdoor"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("martial arts"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("martial arts"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "different types, slower pace, novice performers, practice"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-cross"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "off-road motor sports, all-terrain vehicle, general"),
        "paMountainClimbing": MessageLookupByLibrary.simpleMessage("climbing"),
        "paMountainClimbingDesc":
            MessageLookupByLibrary.simpleMessage("rock or mountain climbing"),
        "paOrienteering": MessageLookupByLibrary.simpleMessage("orienteering"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("paddle boarding"),
        "paPaddleBoardingDesc":
            MessageLookupByLibrary.simpleMessage("standing"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("paddle boat"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("casual, general"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("on horseback"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("resistance training"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "weight lifting, free weight, nautilus or universal"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("rodeo sports"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("general, moderate effort"),
        "paRollerbladingLight":
            MessageLookupByLibrary.simpleMessage("rollerblading"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("in-line skating"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("rope jumping"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("rope skipping"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("union, team, competitive"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("touch, non-competitive"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("running"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("sailing"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "boat and board sailing, windsurfing, ice sailing, general"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("skateboarding"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general, moderate effort"),
        "paSkatingRoller":
            MessageLookupByLibrary.simpleMessage("roller skating"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("skiing"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("water skiing"),
        "paSkiingWaterWakeboardingDesc":
            MessageLookupByLibrary.simpleMessage("water or wakeboarding"),
        "paSkydiving": MessageLookupByLibrary.simpleMessage("skydiving"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "skydiving, base jumping, bungee jumping"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("snorkeling"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("snow shoveling"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("by hand, moderate effort"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("soccer"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("casual, general"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softball / baseball"),
        "paSoftballBaseballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("fast or slow pitch, general"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("surfing"),
        "paSurfingDesc":
            MessageLookupByLibrary.simpleMessage("body or board, general"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("swimming"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "treading water, moderate effort, general"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("table tennis"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("table tennis, ping pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai chi, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tennis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("track and field"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(e.g. shot, discus, hammer throw)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(e.g. high jump, long jump, triple jump, javelin, pole vault)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(e.g. steeplechase, hurdles)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampoline"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("recreational"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("unicycling"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paVolleyballGeneral":
            MessageLookupByLibrary.simpleMessage("volleyball"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "non-competitive, 6 - 9 member team, general"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("walking"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("for pleasure"),
        "paWalkingTheDog":
            MessageLookupByLibrary.simpleMessage("walking the dog"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paWaterAerobics":
            MessageLookupByLibrary.simpleMessage("water exercise"),
        "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
            "water aerobics, water calisthenics"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("water polo"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("water volleyball"),
        "paWaterVolleyballDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("water aerobics"),
        "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
            "water aerobics, water calisthenics"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("wrestling"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "packageLabel": MessageLookupByLibrary.simpleMessage("Package"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Mostly standing or walking in job and active free time activities"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Active"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "e.g. sitting or standing in job and light free time activities"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Low Active"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "e.g. office job and mostly sitting free time activities"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sedentary"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Mostly walking, running or carrying weight in job and active free time activities"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Very Active"),
        "passwordDigit":
            MessageLookupByLibrary.simpleMessage("At least 1 digit"),
        "passwordLowercase":
            MessageLookupByLibrary.simpleMessage("At least 1 lowercase letter"),
        "passwordMinLength":
            MessageLookupByLibrary.simpleMessage("At least 8 characters"),
        "passwordRequired":
            MessageLookupByLibrary.simpleMessage("Password required"),
        "passwordRulesHelpLabel":
            MessageLookupByLibrary.simpleMessage("Password rules"),
        "passwordSpecialChar": MessageLookupByLibrary.simpleMessage(
            "At least 1 special character"),
        "passwordUppercase":
            MessageLookupByLibrary.simpleMessage("At least 1 uppercase letter"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Per 100g/ml"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Per Serving"),
        "portionEatLabel":
            MessageLookupByLibrary.simpleMessage("Portion eaten"),
        "positiveQuantityError": MessageLookupByLibrary.simpleMessage(
            "Enter a quantity greater than zero"),
        "previousGoalAppliedOn": m7,
        "previousLabel": MessageLookupByLibrary.simpleMessage("Previous"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Privacy policy"),
        "productSearchMayTakeLongerMessage":
            MessageLookupByLibrary.simpleMessage("Searching…"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profile"),
        "profileValueRange": m23,
        "proteinLabel": MessageLookupByLibrary.simpleMessage("protein"),
        "proteinsLabel": MessageLookupByLibrary.simpleMessage("Proteins"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Quantity"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "I have read and accept the privacy policy."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Recently"),
        "recipeCoverLabel":
            MessageLookupByLibrary.simpleMessage("Your recipe photo"),
        "recipeEmptyHelp": MessageLookupByLibrary.simpleMessage(
            "Add the foods that make up your recipe."),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Ingredients"),
        "recipeLabel": MessageLookupByLibrary.simpleMessage("Recipe"),
        "recipeLibraryHelp": MessageLookupByLibrary.simpleMessage(
            "The recipe is saved in your library."),
        "recipeNameHint":
            MessageLookupByLibrary.simpleMessage("e.g. Chicken & avocado bowl"),
        "recipeNameLabel": MessageLookupByLibrary.simpleMessage("Recipe name"),
        "recipePortionsHelp": MessageLookupByLibrary.simpleMessage(
            "Values per serving will be calculated when you save."),
        "recipeSaveError": MessageLookupByLibrary.simpleMessage(
            "The recipe could not be saved. Your draft is preserved."),
        "recipeTotalsLabel":
            MessageLookupByLibrary.simpleMessage("Recipe total"),
        "remainingToLoseLabel": MessageLookupByLibrary.simpleMessage("To goal"),
        "remainingWeightLabel":
            MessageLookupByLibrary.simpleMessage("remaining"),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Do you want to report an error to the developer?"),
        "resendCodeLabel": MessageLookupByLibrary.simpleMessage("Resend code"),
        "resetCodeInvalid": MessageLookupByLibrary.simpleMessage(
            "This code is invalid or expired. Request a new code."),
        "resetPasswordButton":
            MessageLookupByLibrary.simpleMessage("Change password"),
        "resetPasswordChanged": MessageLookupByLibrary.simpleMessage(
            "Password changed! You can now sign in with your new password."),
        "resetPasswordConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Confirm password"),
        "resetPasswordNewLabel":
            MessageLookupByLibrary.simpleMessage("New password"),
        "resetPasswordNoMatch":
            MessageLookupByLibrary.simpleMessage("Passwords do not match"),
        "resetPasswordTips": MessageLookupByLibrary.simpleMessage(
            "• Use at least 8 characters\n• Mix numbers & special characters\n• Uppercase + lowercase"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("New password"),
        "restoreFailedLabel": MessageLookupByLibrary.simpleMessage(
            "Could not restore. Please try again."),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Retry"),
        "roleCoachLabel": MessageLookupByLibrary.simpleMessage("Coach"),
        "roleLabel": MessageLookupByLibrary.simpleMessage("Role"),
        "roleStudentLabel": MessageLookupByLibrary.simpleMessage("Student"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("saturated fat"),
        "saveMacroGoalsError": MessageLookupByLibrary.simpleMessage(
            "Problem while saving macro goals."),
        "saveMyWeightLabel":
            MessageLookupByLibrary.simpleMessage("Save my weight"),
        "savePreferenceFailed":
            MessageLookupByLibrary.simpleMessage("Could not save preference."),
        "saveQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Save quantity"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Scan Product"),
        "searchDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Please enter a search word"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Food"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Search"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Products"),
        "searchRecentTabLabel":
            MessageLookupByLibrary.simpleMessage("My foods"),
        "searchRecipesTabLabel":
            MessageLookupByLibrary.simpleMessage("Recipes"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Search results"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Select Gender"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Select Height"),
        "selectMyWeightLabel":
            MessageLookupByLibrary.simpleMessage("Select my weight"),
        "selectPalCategoryLabel":
            MessageLookupByLibrary.simpleMessage("Select Activity Level"),
        "selectRoleDialogLabel":
            MessageLookupByLibrary.simpleMessage("Select Role"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Select Weight"),
        "selectedPortionCount": m8,
        "selectedPortionWeight": m9,
        "sendAnonymousUserData":
            MessageLookupByLibrary.simpleMessage("Send crash reports"),
        "sendCodeLabel": MessageLookupByLibrary.simpleMessage("Send a code"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Serving"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Serving size (g/ml)"),
        "setMacrosLabel": MessageLookupByLibrary.simpleMessage("Set macros"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("About"),
        "settingFeedbackLabel":
            MessageLookupByLibrary.simpleMessage("Feedback"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Distance"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Settings"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licenses"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Mass"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Privacy Settings"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Report Error"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Source Code"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Dark"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Theme"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Light"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("System default"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Volume"),
        "showFewerFoods": MessageLookupByLibrary.simpleMessage("Show less"),
        "showMoreFoods": m10,
        "showPasswordLabel":
            MessageLookupByLibrary.simpleMessage("Show password"),
        "signOutConfirmMessage": MessageLookupByLibrary.simpleMessage(
            "Do you want to sign out of your account?"),
        "signOutOfflineMessage": MessageLookupByLibrary.simpleMessage(
            "You can only sign out when internet connection is available to avoid losing data."),
        "signOutSyncFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Failed to sync your data. Please sign in again later."),
        "skipLabel": MessageLookupByLibrary.simpleMessage("Latter"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "e.g. apple, ice cream, chocolate ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Snack"),
        "studentConsistencyLabel":
            MessageLookupByLibrary.simpleMessage("Consistency"),
        "studentDayTab": MessageLookupByLibrary.simpleMessage("Day"),
        "studentLoadError": MessageLookupByLibrary.simpleMessage(
            "The student\'s data could not be loaded. Please retry."),
        "studentNoEntryLabel":
            MessageLookupByLibrary.simpleMessage("No entries"),
        "studentTrendTab": MessageLookupByLibrary.simpleMessage("Trend"),
        "subscriptionInactiveMessage": MessageLookupByLibrary.simpleMessage(
            "Your subscription is no longer active. Please contact your coach."),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("sugar"),
        "supabaseError": m11,
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("supplied"),
        "switchCameraLabel":
            MessageLookupByLibrary.simpleMessage("Switch camera"),
        "targetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Target weight"),
        "todayLabel": MessageLookupByLibrary.simpleMessage("Today"),
        "toggleFlashLabel":
            MessageLookupByLibrary.simpleMessage("Toggle flash"),
        "trendAvgCaloriesLabel":
            MessageLookupByLibrary.simpleMessage("Avg. calories"),
        "trendDaysTracked": m12,
        "trendGoalLabel": MessageLookupByLibrary.simpleMessage("Goal"),
        "trendMacrosSubtitle":
            MessageLookupByLibrary.simpleMessage("Average daily intake"),
        "trendMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Average macros"),
        "trendNoDataLabel":
            MessageLookupByLibrary.simpleMessage("No data yet for this period"),
        "trendNotEnoughDataLabel":
            MessageLookupByLibrary.simpleMessage("Not enough data"),
        "trendPeriod14d": MessageLookupByLibrary.simpleMessage("14 d"),
        "trendPeriod1m": MessageLookupByLibrary.simpleMessage("1 mo"),
        "trendPeriod3m": MessageLookupByLibrary.simpleMessage("3 mo"),
        "trendPeriod7d": MessageLookupByLibrary.simpleMessage("7 d"),
        "trendSingleWeighInLabel": MessageLookupByLibrary.simpleMessage(
            "Only one weigh-in in this period"),
        "trendVsGoal": m13,
        "undoLabel": MessageLookupByLibrary.simpleMessage("Undo"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Unit"),
        "unnamedStudentLabel":
            MessageLookupByLibrary.simpleMessage("Unnamed student"),
        "unsavedRecipeMessage": MessageLookupByLibrary.simpleMessage(
            "Leave and lose the changes to this recipe?"),
        "unsavedRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Unsaved changes"),
        "userNotConnected":
            MessageLookupByLibrary.simpleMessage("User not connected."),
        "verifyCodeLabel": MessageLookupByLibrary.simpleMessage("Verify code"),
        "viewProductSheetButtonLabel":
            MessageLookupByLibrary.simpleMessage("View product page"),
        "websiteLabel": MessageLookupByLibrary.simpleMessage("website"),
        "weightAverageDeltaLabel": MessageLookupByLibrary.simpleMessage(
            "Difference from the 7-day average"),
        "weightAverageGapLabel":
            MessageLookupByLibrary.simpleMessage("Difference from average"),
        "weightAverageShort": m14,
        "weightChangeShort": m15,
        "weightEntryDate": m16,
        "weightGapShort": MessageLookupByLibrary.simpleMessage("Gap"),
        "weightGoalReminder": m17,
        "weightGoalShortLabel": MessageLookupByLibrary.simpleMessage("Goal"),
        "weightHistoryLabel":
            MessageLookupByLibrary.simpleMessage("Weight history"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Weight"),
        "weightMaxLabel": MessageLookupByLibrary.simpleMessage("max"),
        "weightMeasurementsLabel":
            MessageLookupByLibrary.simpleMessage("Weigh-ins"),
        "weightMinLabel": MessageLookupByLibrary.simpleMessage("min"),
        "weightNoMeasurementsLabel": MessageLookupByLibrary.simpleMessage(
            "No weigh-ins for this period"),
        "weightPeriodAverage": m18,
        "weightPeriodAverageLabel": m19,
        "weightPeriodChangeLabel": m20,
        "weightSaveError": MessageLookupByLibrary.simpleMessage(
            "Could not save your weight. Please try again."),
        "weightSavedLabel":
            MessageLookupByLibrary.simpleMessage("Weight saved"),
        "weightSavingLabel": MessageLookupByLibrary.simpleMessage("Saving…"),
        "weightTodayLabel":
            MessageLookupByLibrary.simpleMessage("today\'s weight"),
        "weightTrendNotEnoughLabel":
            MessageLookupByLibrary.simpleMessage("not enough weigh-ins"),
        "weightWeighInCount": m21,
        "yearsLabel": m22,
        "yesterdayLabel": MessageLookupByLibrary.simpleMessage("Yesterday")
      };
}
