// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
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
  String get localeName => 'fr';

  static String m0(versionNumber) => "Version ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% glucides, ${pctFats}% lipides, ${pctProteins}% protéines";

  static String m2(amount) => "+${amount} kcal au-dessus";

  static String m3(unit) => "Valeurs pour 100 ${unit}";

  static String m4(reason) => "Échec de la suppression : ${reason}";

  static String m5(date) => "Dernière journée renseignée : ${date}";

  static String m6(riskValue) => "Risque de comorbidités : ${riskValue}";

  static String m7(date) => "Dernier objectif appliqué le ${date}";

  static String m17(min, max, unit) =>
      "Entrez une valeur entre ${min} et ${max} ${unit}.";

  static String m8(count) =>
      "${Intl.plural(count, one: '${count} portion', other: '${count} portions')}";

  static String m9(portions, weight) => "${portions} (de ${weight})";

  static String m10(count) =>
      "${Intl.plural(count, one: 'Voir ${count} autre aliment', other: 'Voir ${count} autres aliments')}";

  static String m11(message) => "Erreur Supabase : ${message}";

  static String m12(count, total) => "${count}/${total} jours";

  static String m13(value) => "${value} vs objectif";

  static String m14(date) => "Pesée du ${date}";

  static String m15(value, unit) => "Moyenne de la période : ${value} ${unit}";

  static String m16(age) => "${age} ans";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountDeletedSuccess": MessageLookupByLibrary.simpleMessage(
            "Compte supprimé avec succès."),
        "activityExample":
            MessageLookupByLibrary.simpleMessage("ex : course, vélo, yoga..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Activité"),
        "addIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Ajouter un ingrédient"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Ajouter un nouvel élément :"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "addRecipeToDiary": MessageLookupByLibrary.simpleMessage(
            "Ajouter aussi une portion au journal"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Informations fournies\n par le \n\'Compendium 2011\n des activités physiques\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Aliment personnalisé"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Plus d\'informations sur\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Plus d\'informations sur\nOpenFoodFacts"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Aliment inconnu"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Âge"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Tous"),
        "allTimeLabel": MessageLookupByLibrary.simpleMessage("Tout"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "AtlasTracker est un traqueur de calories et de nutriments gratuit et open-source qui respecte votre vie privée."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("Licence GPL-3.0"),
        "appTitle": MessageLookupByLibrary.simpleMessage("ATLAS TRACKER"),
        "appVersionName": m0,
        "authRateLimit": MessageLookupByLibrary.simpleMessage(
            "Trop de tentatives. Patientez un peu avant de réessayer."),
        "authRetryError": MessageLookupByLibrary.simpleMessage(
            "La demande n\'a pas abouti. Vérifiez votre connexion et réessayez."),
        "averageWeightBody": MessageLookupByLibrary.simpleMessage(
            "Poids moyen de l\'utilisateur sur les sept derniers jours. Le jour courant n\'étant pas compté."),
        "averageWeightLabel":
            MessageLookupByLibrary.simpleMessage("Poids moyen"),
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Quantité de base"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Bêta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "L\'indice de masse corporelle (IMC) est un indice permettant de classer le surpoids et l\'obésité chez les adultes. Il est défini comme le poids en kilogrammes divisé par le carré de la taille en mètres (kg/m²).\n\nL\'IMC ne fait pas de distinction entre la masse grasse et la masse musculaire et peut être trompeur pour certaines personnes."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("IMC"),
        "bodyGoalPreviewDescription": MessageLookupByLibrary.simpleMessage(
            "Prise de masse, sèche ou maintien : les macros s’ajusteront au poids cible."),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "ex : céréales, lait, café..."),
        "breakfastLabel":
            MessageLookupByLibrary.simpleMessage("Petit-déjeuner"),
        "buttonNextLabel": MessageLookupByLibrary.simpleMessage("SUIVANT"),
        "buttonResetLabel":
            MessageLookupByLibrary.simpleMessage("Réinitialiser"),
        "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Enregistrer"),
        "buttonStartLabel": MessageLookupByLibrary.simpleMessage("DÉMARRER"),
        "buttonYesLabel": MessageLookupByLibrary.simpleMessage("OUI"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage(
                "Répartition des macronutriments"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(recommandé)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Équation de l\'Institut de Médecine"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Équation TDEE"),
        "caloriesAboveGoal": m2,
        "caloriesLabel": MessageLookupByLibrary.simpleMessage("Calories"),
        "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("glucides"),
        "carbohydratesLabel": MessageLookupByLibrary.simpleMessage("Glucides"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("glucides"),
        "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
            "Choisir l\'objectif de poids"),
        "cloudSyncProblem": MessageLookupByLibrary.simpleMessage(
            "Problème de synchronisation avec le cloud."),
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "coachLoggedToday":
            MessageLookupByLibrary.simpleMessage("ont saisi aujourd\'hui"),
        "coachStudentsLabel":
            MessageLookupByLibrary.simpleMessage("Voir mes élèves"),
        "coachTodayTitle":
            MessageLookupByLibrary.simpleMessage("Suivi du jour"),
        "codeCooldownHelp": MessageLookupByLibrary.simpleMessage(
            "Vous pourrez renvoyer un code après 30 secondes."),
        "codeSentLabel": MessageLookupByLibrary.simpleMessage(
            "Un nouveau code a été envoyé."),
        "comingSoonLabel":
            MessageLookupByLibrary.simpleMessage("Bientôt disponible"),
        "consumedLabel": MessageLookupByLibrary.simpleMessage("consommées"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Vers quel type de repas voulez-vous copier ?"),
        "copyFromYesterdayLabel":
            MessageLookupByLibrary.simpleMessage("Copier depuis hier"),
        "copyIntakeLabel": MessageLookupByLibrary.simpleMessage("Copier"),
        "copyMealLabel":
            MessageLookupByLibrary.simpleMessage("Copier le repas"),
        "copyMealTargetDateLabel":
            MessageLookupByLibrary.simpleMessage("Jour de destination"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Avec \"Copier vers aujourd\'hui\", vous pouvez copier le repas vers aujourd\'hui. Avec \"Supprimer\", vous pouvez supprimer le repas."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Que voulez-vous faire ?"),
        "crashReportsConsentHelp": MessageLookupByLibrary.simpleMessage(
            "Facultatif. Partager des rapports techniques avec Firebase Crashlytics pour aider à corriger les erreurs. Vous pouvez retirer votre accord ici."),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous créer un aliment personnalisé ?"),
        "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Créer un aliment personnalisé ?"),
        "createRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Créer une recette"),
        "currentWeightLabel":
            MessageLookupByLibrary.simpleMessage("poids actuel"),
        "customFoodAddPhoto":
            MessageLookupByLibrary.simpleMessage("Ajouter une photo"),
        "customFoodChangePhoto":
            MessageLookupByLibrary.simpleMessage("Changer la photo"),
        "customFoodNameError": MessageLookupByLibrary.simpleMessage(
            "Renseigne le nom de l’aliment."),
        "customFoodNameLabel":
            MessageLookupByLibrary.simpleMessage("Nom de l’aliment"),
        "customFoodNumberError": MessageLookupByLibrary.simpleMessage(
            "Saisis un nombre positif ou zéro."),
        "customFoodOptionalDetails":
            MessageLookupByLibrary.simpleMessage("Informations facultatives"),
        "customFoodPer100": m3,
        "customFoodPerPortion":
            MessageLookupByLibrary.simpleMessage("Valeurs pour une portion"),
        "customFoodPhotoError": MessageLookupByLibrary.simpleMessage(
            "Impossible de charger ou d’enregistrer cette photo. Réessaie."),
        "customFoodPortionHint":
            MessageLookupByLibrary.simpleMessage("Ex. : 6 nuggets"),
        "customFoodPortionMode":
            MessageLookupByLibrary.simpleMessage("1 portion"),
        "customFoodPortionName": MessageLookupByLibrary.simpleMessage(
            "Nom de la portion (facultatif)"),
        "customFoodQuantityMode":
            MessageLookupByLibrary.simpleMessage("100 g / 100 ml"),
        "customFoodReferenceHelp": MessageLookupByLibrary.simpleMessage(
            "Saisis les valeurs indiquées pour cette référence. La quantité consommée sera choisie ensuite."),
        "customFoodTitle":
            MessageLookupByLibrary.simpleMessage("Aliment personnalisé"),
        "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
            "Ajustement quotidien des kcal :"),
        "dailyMacroGoalsTitle":
            MessageLookupByLibrary.simpleMessage("Objectifs journaliers"),
        "dailySummaryLabel":
            MessageLookupByLibrary.simpleMessage("Résumé du jour"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Soutenir le développement en fournissant des données d\'utilisation anonymes"),
        "dayMacrosTitle": MessageLookupByLibrary.simpleMessage("Macros"),
        "decreaseWeightLabel":
            MessageLookupByLibrary.simpleMessage("Diminuer le poids"),
        "deleteAllLabel":
            MessageLookupByLibrary.simpleMessage("Tout supprimer"),
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous supprimer l\'élément sélectionné ?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous supprimer tous les éléments de ce repas ?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Supprimer des éléments ?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Supprimer l\'élément ?"),
        "deleteWeightCardTitle":
            MessageLookupByLibrary.simpleMessage("Supprimer ce poids"),
        "deltaWeightBody": MessageLookupByLibrary.simpleMessage(
            "L\'écart de poids est la différence entre le poids moyen et le poids courant renseigné pour ce jour.\nSi aucun poids n\'est enregistré pour le jour courant, le dernier poids valide sera utilisé."),
        "deltaWeightLabel":
            MessageLookupByLibrary.simpleMessage("Écart de poids"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ANNULER"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("Copier vers aujourd\'hui"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("SUPPRIMER"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Journal"),
        "dinnerExample":
            MessageLookupByLibrary.simpleMessage("ex : soupe, poulet, vin..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Dîner"),
        "discardChangesLabel":
            MessageLookupByLibrary.simpleMessage("Quitter sans enregistrer"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Modifier l\'élément"),
        "editLabel": MessageLookupByLibrary.simpleMessage("Modifier"),
        "editMealLabel":
            MessageLookupByLibrary.simpleMessage("Modifier le repas"),
        "editRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Modifier la recette"),
        "editWeightLabel":
            MessageLookupByLibrary.simpleMessage("Modifier le poids"),
        "emptyValueLabel": MessageLookupByLibrary.simpleMessage("-"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("énergie"),
        "enterCodeLabel":
            MessageLookupByLibrary.simpleMessage("Code de vérification"),
        "enterManuallyLabel":
            MessageLookupByLibrary.simpleMessage("Entrer manuellement"),
        "enterValidMacrosHelp": MessageLookupByLibrary.simpleMessage(
            "Renseignez les trois macros (0 à 1 000 g). Le total doit être supérieur à zéro et ne pas dépasser 10 000 kcal."),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Erreur lors de la récupération des données du produit"),
        "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
            "Erreur lors du chargement des activités"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Erreur lors de l\'enregistrement du repas. Avez-vous entré les informations correctes sur le repas ?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Erreur lors de l\'ouverture de l\'application navigateur"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "Erreur lors de l\'ouverture de l\'application e-mail"),
        "errorPrefix": MessageLookupByLibrary.simpleMessage("Erreur :"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Produit non trouvé"),
        "errorRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Aucune recette trouvée"),
        "evolutionLabel": MessageLookupByLibrary.simpleMessage("Évolution"),
        "exampleOfActivityLabel":
            MessageLookupByLibrary.simpleMessage("ex : vélo"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Exporter"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Vous pouvez exporter les données de l\'application dans un fichier zip et les importer plus tard. C\'est utile si vous souhaitez sauvegarder vos données ou les transférer vers un autre appareil.\n\nL\'application n\'utilise aucun service cloud pour stocker vos données."),
        "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Erreur d\'exportation / d\'importation"),
        "exportImportLabel": MessageLookupByLibrary.simpleMessage(
            "Exporter / Importer des données"),
        "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
            "Exportation / Importation réussie"),
        "exportImportSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Sauvegardez vos données dans Supabase ou restaurez-les depuis ce stockage."),
        "exportImportSupabaseLabel": MessageLookupByLibrary.simpleMessage(
            "Exporter / Importer via Supabase"),
        "exportSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Sauvegardez vos données dans le stockage Supabase sous forme de fichier zip."),
        "exportSupabaseLabel":
            MessageLookupByLibrary.simpleMessage("Exporter vers Supabase"),
        "failedToDeleteWithReason": m4,
        "fatLabel": MessageLookupByLibrary.simpleMessage("lipides"),
        "fatsLabel": MessageLookupByLibrary.simpleMessage("Lipides"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("fibres"),
        "forgotPasswordBackToLogin":
            MessageLookupByLibrary.simpleMessage("Retour à la connexion"),
        "forgotPasswordButton": MessageLookupByLibrary.simpleMessage(
            "Envoyer l\'e-mail de réinitialisation"),
        "forgotPasswordEmailLabel":
            MessageLookupByLibrary.simpleMessage("Entrez votre e-mail"),
        "forgotPasswordEmailSent": MessageLookupByLibrary.simpleMessage(
            "E-mail envoyé ! Clique sur le lien dans ton e-mail pour choisir un nouveau mot de passe."),
        "forgotPasswordHelp": MessageLookupByLibrary.simpleMessage(
            "Si le reset de mot de passe ne fonctionne pas :\n- quitter l\'application et recommencer la manipulation, ou\n- faire la demande depuis le site : "),
        "forgotPasswordSendError": MessageLookupByLibrary.simpleMessage(
            "Erreur lors de l\'envoi de l\'e-mail :"),
        "forgotPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Mot de passe oublié ?"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("femme"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Sexe"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("homme"),
        "genericErrorOccurred":
            MessageLookupByLibrary.simpleMessage("Une erreur est survenue."),
        "goalGainWeight":
            MessageLookupByLibrary.simpleMessage("Prendre du poids"),
        "goalGainWeightDashboard":
            MessageLookupByLibrary.simpleMessage("Prise de masse"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Objectif"),
        "goalLoseWeight":
            MessageLookupByLibrary.simpleMessage("Perdre du poids"),
        "goalLoseWeightDashboard":
            MessageLookupByLibrary.simpleMessage("Perte de poids"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Maintenir le poids"),
        "goalMaintainWeightDashboard":
            MessageLookupByLibrary.simpleMessage("Maintien du poids"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Taille"),
        "helloLabel": MessageLookupByLibrary.simpleMessage("Bonjour"),
        "hidePasswordLabel":
            MessageLookupByLibrary.simpleMessage("Masquer le mot de passe"),
        "historyLabel": MessageLookupByLibrary.simpleMessage("Historique"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Accueil"),
        "importAction": MessageLookupByLibrary.simpleMessage("Importer"),
        "importSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Restaurez vos données à partir d\'une sauvegarde stockée sur Supabase."),
        "importSupabaseLabel":
            MessageLookupByLibrary.simpleMessage("Importer depuis Supabase"),
        "increaseWeightLabel":
            MessageLookupByLibrary.simpleMessage("Augmenter le poids"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Nouvelle activité ajoutée"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Nouvelle prise ajoutée"),
        "intakeSaveError": MessageLookupByLibrary.simpleMessage(
            "L\'aliment n\'a pas pu être enregistré. Réessayez."),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Élément supprimé"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Élément mis à jour"),
        "journalLoadError": MessageLookupByLibrary.simpleMessage(
            "Les données n\'ont pas pu être chargées. Réessayez."),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal restantes"),
        "kcalMacrosLabel":
            MessageLookupByLibrary.simpleMessage("kcal • macros"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lastFourteenDaysLabel":
            MessageLookupByLibrary.simpleMessage("14 derniers jours"),
        "lastJournalDay": m5,
        "lastMonthLabel": MessageLookupByLibrary.simpleMessage("1 mois"),
        "lastSevenDaysLabel":
            MessageLookupByLibrary.simpleMessage("7 derniers jours"),
        "lastSixMonthsLabel": MessageLookupByLibrary.simpleMessage("6 mois"),
        "lastThreeMonthsLabel": MessageLookupByLibrary.simpleMessage("3 mois"),
        "lastYearLabel": MessageLookupByLibrary.simpleMessage("1 an"),
        "learnMoreLabel": MessageLookupByLibrary.simpleMessage(
            "En savoir plus : atlas-tracker.fr"),
        "logOutLabel": MessageLookupByLibrary.simpleMessage("Se déconnecter"),
        "loginAlreadySignedIn": MessageLookupByLibrary.simpleMessage(
            "Déjà connecté sur un autre appareil. Veuillez d\'abord vous déconnecter."),
        "loginButton": MessageLookupByLibrary.simpleMessage("Se connecter"),
        "loginCoachAccountHelp": MessageLookupByLibrary.simpleMessage(
            "Votre compte est créé par votre coach. Connectez-vous avec les identifiants reçus."),
        "loginEmailInvalid":
            MessageLookupByLibrary.simpleMessage("Adresse e-mail invalide"),
        "loginEmailLabel": MessageLookupByLibrary.simpleMessage("E-mail"),
        "loginEmailRequired":
            MessageLookupByLibrary.simpleMessage("E-mail requis"),
        "loginError":
            MessageLookupByLibrary.simpleMessage("Erreur de connexion"),
        "loginForgotPassword":
            MessageLookupByLibrary.simpleMessage("Mot de passe oublié ?"),
        "loginInvalidCredentials": MessageLookupByLibrary.simpleMessage(
            "L\'adresse e-mail ou le mot de passe est incorrect."),
        "loginPasswordLabel":
            MessageLookupByLibrary.simpleMessage("Mot de passe"),
        "loginProfileUnavailable": MessageLookupByLibrary.simpleMessage(
            "Votre profil n\'est pas encore disponible. Contactez votre coach."),
        "loginTitle": MessageLookupByLibrary.simpleMessage("Connexion"),
        "loginUnknownError":
            MessageLookupByLibrary.simpleMessage("Erreur inconnue"),
        "lunchExample":
            MessageLookupByLibrary.simpleMessage("ex : pizza, salade, riz..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Déjeuner"),
        "macroCaloriesExplanation": MessageLookupByLibrary.simpleMessage(
            "Calories calculées à partir des macronutriments."),
        "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
            "Répartition des macronutriments :"),
        "macroDistributionTitle":
            MessageLookupByLibrary.simpleMessage("Répartition des macros"),
        "macroGoalHistoryEmpty": MessageLookupByLibrary.simpleMessage(
            "L’historique des modifications d’objectifs apparaîtra ici."),
        "macroGoalsSaved": MessageLookupByLibrary.simpleMessage(
            "Les objectifs ont été enregistrés."),
        "macroGoalsTabLabel": MessageLookupByLibrary.simpleMessage("Objectifs"),
        "manageAccountConfirmAction":
            MessageLookupByLibrary.simpleMessage("Confirmer la suppression"),
        "manageAccountConfirmMessage": MessageLookupByLibrary.simpleMessage(
            "Cette action est irréversible."),
        "manageAccountConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Êtes-vous sûr ?"),
        "manageAccountDelete":
            MessageLookupByLibrary.simpleMessage("Supprimer mon compte"),
        "manageAccountDescription": MessageLookupByLibrary.simpleMessage(
            "Nous ne collectons que les données essentielles au bon fonctionnement de l\'application :\n\nAdresse e-mail : utilisée pour la connexion et l\'identification du compte.\n\nDonnées nutritionnelles : votre poids quotidien, ainsi que vos apports en calories, protéines, lipides et glucides.\n\nObjectifs : vos cibles personnalisées pour les calories, protéines, lipides et glucides.\n\nToutes les données sont stockées en toute sécurité sur Supabase. Nous ne partageons aucune de vos données avec des tiers."),
        "manageAccountEnableSync": MessageLookupByLibrary.simpleMessage(
            "Activer la synchronisation Supabase"),
        "manageAccountTitle":
            MessageLookupByLibrary.simpleMessage("Gérer le compte"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marque"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("glucides par"),
        "mealCopiedSnackbar":
            MessageLookupByLibrary.simpleMessage("Repas copié"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("lipides par"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal par"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Nom du repas"),
        "mealPortionLabel":
            MessageLookupByLibrary.simpleMessage("Nombre de portions"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("protéines par"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Quantité par défaut"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Unité de repas"),
        "mealsOfDayLabel":
            MessageLookupByLibrary.simpleMessage("Repas du jour"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "minutesAbbrevLabel": MessageLookupByLibrary.simpleMessage("min"),
        "missingNutrientsDialogContent": MessageLookupByLibrary.simpleMessage(
            "Oups ! Cette fiche produit semble incomplète. Souhaitez-vous saisir manuellement les informations nutritionnelles manquantes pour pouvoir l\'enregistrer ?"),
        "missingNutrientsDialogTitle":
            MessageLookupByLibrary.simpleMessage("Données manquantes"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Le produit ne contient pas les informations requises sur les kcal ou les macronutriments"),
        "moveIntakeLabel": MessageLookupByLibrary.simpleMessage("Déplacer"),
        "myStudentsTitle": MessageLookupByLibrary.simpleMessage("Mes élèves"),
        "nextLabel": MessageLookupByLibrary.simpleMessage("Suivant"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Aucune activité ajoutée récemment"),
        "noDataToday": MessageLookupByLibrary.simpleMessage(
            "Aucune donnée pour aujourd’hui"),
        "noFoodAddedLabel":
            MessageLookupByLibrary.simpleMessage("Aucun aliment ajouté"),
        "noFoodYesterdayLabel": MessageLookupByLibrary.simpleMessage(
            "Aucun aliment pour ce repas hier."),
        "noInternetConnectionMessage": MessageLookupByLibrary.simpleMessage(
            "Pas de connexion Internet. Fonctionnalité indisponible."),
        "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Aucun repas ajouté récemment"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Aucun résultat trouvé"),
        "noStudents": MessageLookupByLibrary.simpleMessage("Aucun élève"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/A"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Rien ajouté"),
        "notificationActivationError": MessageLookupByLibrary.simpleMessage(
            "Problème d\'activation des notifications. Veuillez réessayer plus tard."),
        "notificationsLabel":
            MessageLookupByLibrary.simpleMessage("Notifications"),
        "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
            "Informations nutritionnelles"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Poids normal"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Obésité classe I"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Obésité classe II"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Obésité classe III"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Pré-obésité"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Moyen"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Accru"),
        "nutritionalStatusRiskLabel": m6,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Faible \n(mais risque d\'autres \nproblèmes cliniques augmenté)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Modéré"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Sévère"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Très sévère"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Insuffisance pondérale"),
        "overviewLabel": MessageLookupByLibrary.simpleMessage("Aperçu"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("football américain"),
        "paAmericanFootballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("toucher, flag, général"),
        "paArcheryGeneral":
            MessageLookupByLibrary.simpleMessage("tir à l\'arc"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("non-chasse"),
        "paAutoRacing":
            MessageLookupByLibrary.simpleMessage("course automobile"),
        "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("monoplace"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("randonnée avec sac à dos"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "simples et doubles sociaux, général"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("basket-ball"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("cyclisme"),
        "paBicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("cyclisme, VTT"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("cyclisme, stationnaire"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("billard"),
        "paBilliardsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("boxe"),
        "paBoxingBagDesc":
            MessageLookupByLibrary.simpleMessage("sac de frappe"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boxe"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("sur le ring, général"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("balle au balai"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("callisthénie"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "effort léger ou modéré, général (ex : exercices pour le dos)"),
        "paCanoeingGeneral":
            MessageLookupByLibrary.simpleMessage("canoë-kayak"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "aviron, pour le plaisir, général"),
        "paCatch": MessageLookupByLibrary.simpleMessage("football ou baseball"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("jouer à la balle"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("cheerleading"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
            "mouvements de gymnastique, compétitif"),
        "paChildrenGame":
            MessageLookupByLibrary.simpleMessage("jeux d\'enfants"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(ex : marelle, 4 carrés, balle au prisonnier, jeux de plein air, t-ball, tetherball, billes, jeux d\'arcade), effort modéré"),
        "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
            "escalade de collines, sans charge"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("sans charge"),
        "paCricket": MessageLookupByLibrary.simpleMessage("cricket"),
        "paCricketDesc":
            MessageLookupByLibrary.simpleMessage("batte, lancer, champ"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("croquet"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aérobic"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paDancingGeneral":
            MessageLookupByLibrary.simpleMessage("danse générale"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "ex : disco, folk, danse irlandaise, danse en ligne, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("fléchettes"),
        "paDartsWallDesc":
            MessageLookupByLibrary.simpleMessage("mur ou pelouse"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("plongée"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "plongée en apnée, plongée sous-marine, général"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("plongeon"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("tremplin ou plateforme"),
        "paFencing": MessageLookupByLibrary.simpleMessage("escrime"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("jeu de frisbee"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("gymnastique"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("handball"),
        "paHandballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("deltaplane"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("cyclisme"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("exercice de conditionnement"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("danse"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("course"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("sports"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("marche"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("activités aquatiques"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("activités hivernales"),
        "paHikingCrossCountry":
            MessageLookupByLibrary.simpleMessage("randonnée"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("à travers le pays"),
        "paHockeyField":
            MessageLookupByLibrary.simpleMessage("hockey sur gazon"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("équitation"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("hockey sur glace"),
        "paIceHockeyGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("patinage sur glace"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("jonglerie"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kayak"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("effort modéré"),
        "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lacrosse"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paLawnBowling":
            MessageLookupByLibrary.simpleMessage("bowling sur gazon"),
        "paLawnBowlingDesc":
            MessageLookupByLibrary.simpleMessage("pétanque, extérieur"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("arts martiaux"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "différents types, rythme modéré (ex : judo, jujitsu, karaté, kick boxing, tae kwan do, tai-bo, boxe thaïlandaise)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("arts martiaux"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "différents types, rythme plus lent, débutants, entraînement"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-cross"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "sports motorisés tout-terrain, véhicule tout-terrain, général"),
        "paMountainClimbing": MessageLookupByLibrary.simpleMessage("escalade"),
        "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
            "escalade de rocher ou de montagne"),
        "paOrienteering":
            MessageLookupByLibrary.simpleMessage("course d\'orientation"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("stand up paddle"),
        "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("debout"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("pédalo"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("occasionnel, général"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("à cheval"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("entraînement de résistance"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "musculation, poids libres, nautilus ou universel"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("sports de rodéo"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("général, effort modéré"),
        "paRollerbladingLight": MessageLookupByLibrary.simpleMessage("roller"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("roller en ligne"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("saut à la corde"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "rythme modéré, 100-120 sauts/min, général, saut à deux pieds, rebond simple"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("saut à la corde"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("union, équipe, compétitif"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("toucher, non-compétitif"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("course"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("voile"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "voile de bateau et de planche, planche à voile, voile sur glace, général"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("skateboard"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général, effort modéré"),
        "paSkatingRoller":
            MessageLookupByLibrary.simpleMessage("patin à roulettes"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("ski"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("ski nautique"),
        "paSkiingWaterWakeboardingDesc":
            MessageLookupByLibrary.simpleMessage("ski nautique ou wakeboard"),
        "paSkydiving": MessageLookupByLibrary.simpleMessage("parachutisme"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "parachutisme, saut BASE, saut à l\'élastique"),
        "paSnorkeling":
            MessageLookupByLibrary.simpleMessage("plongée avec tuba"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("déneigement à la pelle"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("à la main, effort modéré"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("football"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("occasionnel, général"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softball / baseball"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "lancer rapide ou lent, général"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("surf"),
        "paSurfingDesc":
            MessageLookupByLibrary.simpleMessage("body ou planche, général"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("natation"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "tête hors de l\'eau, effort modéré, général"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("tennis de table"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("tennis de table, ping-pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai chi, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tennis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("athlétisme"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(ex : lancer du poids, disque, marteau)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(ex : saut en hauteur, saut en longueur, triple saut, javelot, saut à la perche)"),
        "paTrackField3Desc":
            MessageLookupByLibrary.simpleMessage("(ex : steeple, haies)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampoline"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("récréatif"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("monocycle"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paVolleyballGeneral":
            MessageLookupByLibrary.simpleMessage("volley-ball"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "non-compétitif, équipe de 6 à 9 membres, général"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("marche"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("pour le plaisir"),
        "paWalkingTheDog":
            MessageLookupByLibrary.simpleMessage("promener le chien"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paWaterAerobics":
            MessageLookupByLibrary.simpleMessage("exercice aquatique"),
        "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
            "aérobic aquatique, callisthénie aquatique"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("water-polo"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("général"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("volley-ball aquatique"),
        "paWaterVolleyballDesc":
            MessageLookupByLibrary.simpleMessage("général"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("aérobic aquatique"),
        "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
            "aérobic aquatique, callisthénie aquatique"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("lutte"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("général"),
        "packageLabel": MessageLookupByLibrary.simpleMessage("Paquet"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Majoritairement debout ou en marche au travail et activités de loisirs actives"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Actif"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "ex : travail assis ou debout et activités de loisirs légères"),
        "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("Peu actif"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "ex : travail de bureau et activités de loisirs majoritairement assises"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sédentaire"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Majoritairement en marche, en course ou en portant des poids au travail et activités de loisirs actives"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Très actif"),
        "passwordDigit":
            MessageLookupByLibrary.simpleMessage("Au moins 1 chiffre"),
        "passwordLowercase":
            MessageLookupByLibrary.simpleMessage("Au moins 1 minuscule"),
        "passwordMinLength":
            MessageLookupByLibrary.simpleMessage("Au moins 8 caractères"),
        "passwordRequired":
            MessageLookupByLibrary.simpleMessage("Mot de passe requis"),
        "passwordRulesHelpLabel":
            MessageLookupByLibrary.simpleMessage("Règles du mot de passe"),
        "passwordSpecialChar": MessageLookupByLibrary.simpleMessage(
            "Au moins 1 caractère spécial"),
        "passwordUppercase":
            MessageLookupByLibrary.simpleMessage("Au moins 1 majuscule"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Pour 100"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Par portion"),
        "portionEatLabel":
            MessageLookupByLibrary.simpleMessage("Portion mangée"),
        "positiveQuantityError": MessageLookupByLibrary.simpleMessage(
            "Saisissez une quantité supérieure à zéro"),
        "previousGoalAppliedOn": m7,
        "previousLabel": MessageLookupByLibrary.simpleMessage("Précédent"),
        "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
            "Politique de confidentialité"),
        "productSearchMayTakeLongerMessage":
            MessageLookupByLibrary.simpleMessage("Recherche en cours…"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
        "profileValueRange": m17,
        "proteinLabel": MessageLookupByLibrary.simpleMessage("protéines"),
        "proteinsLabel": MessageLookupByLibrary.simpleMessage("Protéines"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Quantité"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "J\'ai lu et j\'accepte la politique de confidentialité."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Récemment"),
        "recipeCoverLabel":
            MessageLookupByLibrary.simpleMessage("La photo de ta recette"),
        "recipeEmptyHelp": MessageLookupByLibrary.simpleMessage(
            "Ajoute les aliments qui composent ta recette."),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Ingrédients"),
        "recipeLabel": MessageLookupByLibrary.simpleMessage("Recette"),
        "recipeLibraryHelp": MessageLookupByLibrary.simpleMessage(
            "La recette est enregistrée dans votre bibliothèque. La recette entière correspond à une portion."),
        "recipeNameHint":
            MessageLookupByLibrary.simpleMessage("Ex. Bowl poulet & avocat"),
        "recipeNameLabel":
            MessageLookupByLibrary.simpleMessage("Nom de la recette"),
        "recipePortionsHelp": MessageLookupByLibrary.simpleMessage(
            "Les valeurs par portion seront calculées à l’enregistrement."),
        "recipeSaveError": MessageLookupByLibrary.simpleMessage(
            "La recette n\'a pas pu être enregistrée. Votre brouillon est conservé."),
        "recipeTotalsLabel":
            MessageLookupByLibrary.simpleMessage("Total de la recette"),
        "remainingToLoseLabel":
            MessageLookupByLibrary.simpleMessage("Reste à l’objectif"),
        "remainingWeightLabel":
            MessageLookupByLibrary.simpleMessage("restants"),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous signaler une erreur au développeur ?"),
        "resendCodeLabel":
            MessageLookupByLibrary.simpleMessage("Renvoyer un code"),
        "resetCodeInvalid": MessageLookupByLibrary.simpleMessage(
            "Ce code est invalide ou expiré. Demandez un nouveau code."),
        "resetPasswordButton":
            MessageLookupByLibrary.simpleMessage("Changer le mot de passe"),
        "resetPasswordChanged": MessageLookupByLibrary.simpleMessage(
            "Mot de passe changé ! Tu peux maintenant te connecter avec ton nouveau mot de passe."),
        "resetPasswordConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Confirmer le mot de passe"),
        "resetPasswordNewLabel":
            MessageLookupByLibrary.simpleMessage("Nouveau mot de passe"),
        "resetPasswordNoMatch": MessageLookupByLibrary.simpleMessage(
            "Les mots de passe ne correspondent pas"),
        "resetPasswordTips": MessageLookupByLibrary.simpleMessage(
            "• Utilise au moins 8 caractères\n• Mélange chiffres & caractères spéciaux\n• Majuscules + minuscules"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Nouveau mot de passe"),
        "restoreFailedLabel": MessageLookupByLibrary.simpleMessage(
            "Restauration impossible. Réessayez."),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "roleCoachLabel": MessageLookupByLibrary.simpleMessage("Coach"),
        "roleLabel": MessageLookupByLibrary.simpleMessage("Rôle"),
        "roleStudentLabel": MessageLookupByLibrary.simpleMessage("Élève"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("graisses saturées"),
        "saveMacroGoalsError": MessageLookupByLibrary.simpleMessage(
            "Problème lors de l\'enregistrement des objectifs macro."),
        "saveMyWeightLabel":
            MessageLookupByLibrary.simpleMessage("Enregistrer mon poids"),
        "savePreferenceFailed": MessageLookupByLibrary.simpleMessage(
            "Impossible d’enregistrer la préférence."),
        "saveQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Enregistrer la quantité"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Scanner un produit"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
            "Veuillez entrer un mot de recherche"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Aliments"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Rechercher"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produits"),
        "searchRecentTabLabel":
            MessageLookupByLibrary.simpleMessage("Mes aliments"),
        "searchRecipesTabLabel":
            MessageLookupByLibrary.simpleMessage("Recettes"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Résultats de recherche"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Sélectionner le sexe"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Sélectionner la taille"),
        "selectMyWeightLabel":
            MessageLookupByLibrary.simpleMessage("Sélectionner mon poids"),
        "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
            "Sélectionner le niveau d\'activité"),
        "selectRoleDialogLabel":
            MessageLookupByLibrary.simpleMessage("Sélectionner le rôle"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Sélectionner le poids"),
        "selectedPortionCount": m8,
        "selectedPortionWeight": m9,
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Envoyer les rapports de plantage"),
        "sendCodeLabel":
            MessageLookupByLibrary.simpleMessage("Envoyer un code"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Portion"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Quantité par portion"),
        "setMacrosLabel":
            MessageLookupByLibrary.simpleMessage("Définir les macros"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("À propos"),
        "settingFeedbackLabel":
            MessageLookupByLibrary.simpleMessage("Commentaires"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Distance"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Paramètres"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licences"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Masse"),
        "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
            "Paramètres de confidentialité"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Signaler une erreur"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Code Source"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Foncé"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Thème"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Clair"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Par défaut du système"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Volume"),
        "showFewerFoods": MessageLookupByLibrary.simpleMessage("Réduire"),
        "showMoreFoods": m10,
        "showPasswordLabel":
            MessageLookupByLibrary.simpleMessage("Afficher le mot de passe"),
        "signOutConfirmMessage": MessageLookupByLibrary.simpleMessage(
            "Voulez-vous vous déconnecter de votre compte ?"),
        "signOutOfflineMessage": MessageLookupByLibrary.simpleMessage(
            "Vous ne pouvez vous déconnecter que lorsque la connexion internet est rétablie pour ne pas perdre vos données."),
        "signOutSyncFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Échec de la synchronisation des données. Veuillez vous reconnecter plus tard."),
        "skipLabel": MessageLookupByLibrary.simpleMessage("Plus tard"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "ex : pomme, glace, chocolat..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Collation"),
        "studentConsistencyLabel":
            MessageLookupByLibrary.simpleMessage("Jours avec saisie"),
        "studentDayTab": MessageLookupByLibrary.simpleMessage("Jour"),
        "studentLoadError": MessageLookupByLibrary.simpleMessage(
            "Les données de l\'élève n\'ont pas pu être chargées. Réessayez."),
        "studentNoEntryLabel":
            MessageLookupByLibrary.simpleMessage("Aucune saisie"),
        "studentTrendTab": MessageLookupByLibrary.simpleMessage("Tendance"),
        "subscriptionInactiveMessage": MessageLookupByLibrary.simpleMessage(
            "Votre abonnement n\'est plus actif. Veuillez contacter votre coach."),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("sucre"),
        "supabaseError": m11,
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("Ingérées"),
        "switchCameraLabel":
            MessageLookupByLibrary.simpleMessage("Changer de caméra"),
        "targetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Poids cible"),
        "todayLabel": MessageLookupByLibrary.simpleMessage("Aujourd\'hui"),
        "toggleFlashLabel": MessageLookupByLibrary.simpleMessage(
            "Activer ou désactiver le flash"),
        "trendAvgCaloriesLabel":
            MessageLookupByLibrary.simpleMessage("Moy. calories"),
        "trendDaysTracked": m12,
        "trendGoalLabel": MessageLookupByLibrary.simpleMessage("Objectif"),
        "trendMacrosSubtitle":
            MessageLookupByLibrary.simpleMessage("Apports moyens par jour"),
        "trendMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Moyenne des macros"),
        "trendNoDataLabel": MessageLookupByLibrary.simpleMessage(
            "Pas encore de données sur cette période"),
        "trendNotEnoughDataLabel":
            MessageLookupByLibrary.simpleMessage("Données insuffisantes"),
        "trendPeriod14d": MessageLookupByLibrary.simpleMessage("14 j"),
        "trendPeriod1m": MessageLookupByLibrary.simpleMessage("1 mois"),
        "trendPeriod3m": MessageLookupByLibrary.simpleMessage("3 mois"),
        "trendPeriod7d": MessageLookupByLibrary.simpleMessage("7 j"),
        "trendSingleWeighInLabel": MessageLookupByLibrary.simpleMessage(
            "Une seule pesée sur la période"),
        "trendVsGoal": m13,
        "undoLabel": MessageLookupByLibrary.simpleMessage("Annuler"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Unité"),
        "unnamedStudentLabel":
            MessageLookupByLibrary.simpleMessage("Élève sans nom"),
        "unsavedRecipeMessage": MessageLookupByLibrary.simpleMessage(
            "Quitter et perdre les modifications de cette recette ?"),
        "unsavedRecipeTitle": MessageLookupByLibrary.simpleMessage(
            "Modifications non enregistrées"),
        "userNotConnected":
            MessageLookupByLibrary.simpleMessage("Utilisateur non connecté."),
        "verifyCodeLabel":
            MessageLookupByLibrary.simpleMessage("Vérifier le code"),
        "viewProductSheetButtonLabel":
            MessageLookupByLibrary.simpleMessage("Voir la fiche produit"),
        "websiteLabel": MessageLookupByLibrary.simpleMessage("site"),
        "weightAverageDeltaLabel": MessageLookupByLibrary.simpleMessage(
            "Écart à la moyenne sur 7 jours"),
        "weightEntryDate": m14,
        "weightGoalShortLabel":
            MessageLookupByLibrary.simpleMessage("Objectif"),
        "weightHistoryLabel":
            MessageLookupByLibrary.simpleMessage("Historique des poids"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Poids"),
        "weightMeasurementsLabel":
            MessageLookupByLibrary.simpleMessage("Pesées"),
        "weightNoMeasurementsLabel": MessageLookupByLibrary.simpleMessage(
            "Aucune pesée sur cette période"),
        "weightPeriodAverage": m15,
        "weightSaveError": MessageLookupByLibrary.simpleMessage(
            "Impossible d’enregistrer le poids. Réessayez."),
        "weightSavedLabel":
            MessageLookupByLibrary.simpleMessage("Poids enregistré"),
        "weightSavingLabel":
            MessageLookupByLibrary.simpleMessage("Enregistrement…"),
        "yearsLabel": m16,
        "yesterdayLabel": MessageLookupByLibrary.simpleMessage("Hier")
      };
}
