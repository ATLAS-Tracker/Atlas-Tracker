// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a tr locale. All the
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
  String get localeName => 'tr';

  static String m0(versionNumber) => "Versiyon ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "%${pctCarbs} karbonhidrat, %${pctFats} yağ, %${pctProteins} protein";

  static String m2(riskValue) => "Eşlik eden hastalık riski: ${riskValue}";

  static String m3(age) => "${age} yıl";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "ör. koşu, bisiklet, yoga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Aktivite"),
        "addItemLabel": MessageLookupByLibrary.simpleMessage("Yeni Öğe Ekle:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Ekle"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Bilgi\n\'2011 Compendium\n of Physical Activities\'\nden sağlanmıştır"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Özel Yemek Öğesi"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Daha Fazla Bilgi\nFoodData Central\'da"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Daha Fazla Bilgi\nOpenFoodFacts\'te"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Bilinmeyen Yemek Öğesi"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Yaş"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Tümü"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "AtlasTracker, gizliliğinize saygı duyan ücretsiz ve açık kaynaklı bir kalori ve besin takipçisidir."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("GPL-3.0 lisansı"),
        "appTitle": MessageLookupByLibrary.simpleMessage("AtlasTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Temel miktar (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "Vücut Kitle İndeksi (BMI), yetişkinlerde aşırı kiloyu ve obeziteyi sınıflandırmak için kullanılan bir indekstir. Kilogram cinsinden ağırlığın, metre cinsinden boyun karesine bölünmesiyle tanımlanır (kg/m²).\n\nBMI, yağ ve kas kütlesi arasında ayrım yapmaz ve bazı bireyler için yanıltıcı olabilir."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "ör. mısır gevreği, süt, kahve ..."),
        "breakfastLabel": MessageLookupByLibrary.simpleMessage("Kahvaltı"),
        "burnedLabel": MessageLookupByLibrary.simpleMessage("yakılan"),
        "buttonNextLabel": MessageLookupByLibrary.simpleMessage("İLERİ"),
        "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Sıfırla"),
        "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Kaydet"),
        "buttonStartLabel": MessageLookupByLibrary.simpleMessage("BAŞLA"),
        "buttonYesLabel": MessageLookupByLibrary.simpleMessage("EVET"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Makro besin dağılımı"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(önerilen)"),
        "calculationsTDEEIOM2006Label":
            MessageLookupByLibrary.simpleMessage("Tıp Enstitüsü Denklemi"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("TDEE denklemi"),
        "caloriesLabel": MessageLookupByLibrary.simpleMessage("Kalori"),
        "carbohydrateLabel":
            MessageLookupByLibrary.simpleMessage("karbonhidrat"),
        "carbohydratesLabel":
            MessageLookupByLibrary.simpleMessage("Karbonhidratlar"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("karbonhidrat"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Kilo Hedefini Seçin"),
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "coachStudentsLabel":
            MessageLookupByLibrary.simpleMessage("Öğrencilerim"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Hangi yemek türüne kopyalamak istiyorsunuz?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "\"Bugüne Kopyala\" ile yemeği bugüne kopyalayabilirsiniz. \"Sil\" ile yemeği silebilirsiniz."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Ne yapmak istiyorsunuz?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Özel bir yemek öğesi oluşturmak istiyor musunuz?"),
        "createCustomDialogTitle":
            MessageLookupByLibrary.simpleMessage("Özel yemek öğesi oluştur?"),
        "createRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Öğün oluştur"),
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Günlük Kcal ayarı:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Anonim kullanım verileri sağlayarak geliştirmeyi destekleyin"),
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Seçilen öğeyi silmek istiyor musunuz?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Bu öğüne ait tüm girdileri silmek istiyor musunuz?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Girdiler silinsin mi?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Öğeyi Sil?"),
        "deltaWeightBody": MessageLookupByLibrary.simpleMessage(
            "Ağırlık farkı, ortalama ağırlık ile bu gün için girilen mevcut ağırlık arasındaki farktır.\nMevcut gün için herhangi bir ağırlık kaydedilmemişse, son geçerli ağırlık kullanılacaktır."),
        "deltaWeightLabel": MessageLookupByLibrary.simpleMessage("Kilo Farkı"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("İPTAL"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("BUGÜNE KOPYALA"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("SİL"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("TAMAM"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Günlük"),
        "dinnerExample":
            MessageLookupByLibrary.simpleMessage("ör. çorba, tavuk, şarap ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Akşam Yemeği"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Öğeyi Düzenle"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Yemeği Düzenle"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("enerji"),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Ürün verileri alınırken hata oluştu"),
        "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
            "Aktiviteler yüklenirken hata oluştu"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Yemek kaydedilirken hata oluştu. Doğru yemek bilgilerini girdiniz mi?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Tarayıcı uygulaması açılırken hata oluştu"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "E-posta uygulaması açılırken hata oluştu"),
        "errorPrefix": MessageLookupByLibrary.simpleMessage("Hata:"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Ürün bulunamadı"),
        "errorRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Hiç tarif bulunamadı"),
        "exampleOfActivityLabel":
            MessageLookupByLibrary.simpleMessage("örn: bisiklet"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Dışa Aktar"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Uygulama verilerini bir zip dosyasına dışa aktarabilir ve daha sonra içe aktarabilirsiniz. Bu, verilerinizi yedeklemek veya başka bir cihaza aktarmak istiyorsanız kullanışlıdır.\n\nUygulama, verilerinizi saklamak için herhangi bir bulut hizmeti kullanmaz."),
        "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Dışa Aktarma / İçe Aktarma hatası"),
        "exportImportLabel": MessageLookupByLibrary.simpleMessage(
            "Verileri Dışa Aktar / İçe Aktar"),
        "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
            "Dışa Aktarma / İçe Aktarma başarılı"),
        "exportImportSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Verilerinizi Supabase depolamasına yedekleyin veya oradan geri yükleyin."),
        "exportImportSupabaseLabel": MessageLookupByLibrary.simpleMessage(
            "Supabase ile Dışa Aktar / İçe Aktar"),
        "exportSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Verilerinizi zip dosyası olarak Supabase depolamasına yedekleyin."),
        "exportSupabaseLabel":
            MessageLookupByLibrary.simpleMessage("Supabase\'e Aktar"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("yağ"),
        "fatsLabel": MessageLookupByLibrary.simpleMessage("Yağlar"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("lif"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "forgotPasswordBackToLogin":
            MessageLookupByLibrary.simpleMessage("Girişe geri dön"),
        "forgotPasswordButton": MessageLookupByLibrary.simpleMessage(
            "Şifre sıfırlama e-postası gönder"),
        "forgotPasswordEmailLabel":
            MessageLookupByLibrary.simpleMessage("E-postanı gir"),
        "forgotPasswordEmailSent": MessageLookupByLibrary.simpleMessage(
            "E-posta gönderildi! Yeni şifre seçmek için e-postandaki bağlantıya tıkla."),
        "forgotPasswordHelp": MessageLookupByLibrary.simpleMessage(
            "Şifre sıfırlama çalışmazsa:\n- uygulamadan çıkıp işlemi tekrar deneyin veya\n- isteği web sitesi üzerinden yapın: "),
        "forgotPasswordSendError": MessageLookupByLibrary.simpleMessage(
            "E-posta gönderilirken hata oluştu:"),
        "forgotPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Şifreni mi unuttun?"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("♀ kadın"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Cinsiyet"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("♂ erkek"),
        "goalGainWeight": MessageLookupByLibrary.simpleMessage("Kilo Al"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Hedef"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Kilo Ver"),
        "goalMaintainWeight": MessageLookupByLibrary.simpleMessage("Kilo Koru"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Boy"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Ana Sayfa"),
        "importAction": MessageLookupByLibrary.simpleMessage("İçe Aktar"),
        "importSupabaseDescription": MessageLookupByLibrary.simpleMessage(
            "Verilerinizi Supabase\'de saklanan bir yedekten geri yükleyin."),
        "importSupabaseLabel":
            MessageLookupByLibrary.simpleMessage("Supabase\'den İçe Aktar"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Yeni aktivite eklendi"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Yeni alım eklendi"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Öğe silindi"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Öğe güncellendi"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kalan kcal"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "logOutLabel": MessageLookupByLibrary.simpleMessage("Çıkış yap"),
        "loginAlreadySignedIn": MessageLookupByLibrary.simpleMessage(
            "Başka bir cihazda zaten giriş yapılmış. Lütfen önce çıkış yapın."),
        "loginButton": MessageLookupByLibrary.simpleMessage("Giriş Yap"),
        "loginEmailInvalid":
            MessageLookupByLibrary.simpleMessage("Geçersiz e-posta adresi"),
        "loginEmailLabel": MessageLookupByLibrary.simpleMessage("E-posta"),
        "loginEmailRequired":
            MessageLookupByLibrary.simpleMessage("E-posta gerekli"),
        "loginError": MessageLookupByLibrary.simpleMessage("Giriş hatası"),
        "loginForgotPassword":
            MessageLookupByLibrary.simpleMessage("Şifreni mi unuttun?"),
        "loginPasswordLabel": MessageLookupByLibrary.simpleMessage("Şifre"),
        "loginTitle": MessageLookupByLibrary.simpleMessage("Giriş Yap"),
        "loginUnknownError":
            MessageLookupByLibrary.simpleMessage("Bilinmeyen hata"),
        "lunchExample": MessageLookupByLibrary.simpleMessage(
            "ör. pizza, salata, pirinç ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Öğle Yemeği"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Makro besin Dağılımı:"),
        "manageAccountConfirmAction":
            MessageLookupByLibrary.simpleMessage("Silmeyi Onayla"),
        "manageAccountConfirmMessage":
            MessageLookupByLibrary.simpleMessage("Bu işlem geri alınamaz."),
        "manageAccountConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Emin misiniz?"),
        "manageAccountDelete":
            MessageLookupByLibrary.simpleMessage("Hesabımı Sil"),
        "manageAccountDescription": MessageLookupByLibrary.simpleMessage(
            "Uygulamanın düzgün çalışması için gerekli olan verileri topluyoruz:\n\nE-posta adresi: giriş ve hesap kimliği için kullanılır.\n\nBeslenme verileri: günlük kilonuz ve aldığınız kalori, protein, yağ ve karbonhidrat miktarı.\n\nHedefler: kalori, protein, yağ ve karbonhidrat için kişiselleştirilmiş hedefleriniz.\n\nTüm veriler Supabase üzerinde güvenli bir şekilde saklanır. Verilerinizi üçüncü taraflarla paylaşmayız."),
        "manageAccountEnableSync": MessageLookupByLibrary.simpleMessage(
            "Supabase Senkronizasyonunu Etkinleştir"),
        "manageAccountTitle":
            MessageLookupByLibrary.simpleMessage("Hesabı yönet"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Markalar"),
        "mealCarbsLabel":
            MessageLookupByLibrary.simpleMessage("karbonhidrat başına"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("yağ başına"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal başına"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Yemek adı"),
        "mealPortionLabel":
            MessageLookupByLibrary.simpleMessage("Porsiyon sayısı"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("protein başına 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Yemek boyutu (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Yemek boyutu (oz/fl oz)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Yemek birimi"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Üründe gerekli kcal veya makro besin bilgileri eksik"),
        "myStudentsTitle": MessageLookupByLibrary.simpleMessage("Öğrencilerim"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Son zamanlarda eklenen aktivite yok"),
        "noDataToday":
            MessageLookupByLibrary.simpleMessage("Bugün için veri yok"),
        "noFoodAddedLabel":
            MessageLookupByLibrary.simpleMessage("Hiçbir gıda eklenmedi"),
        "noInternetConnectionMessage": MessageLookupByLibrary.simpleMessage(
            "İnternet bağlantısı yok. Özellik kullanılamıyor."),
        "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Son zamanlarda eklenen yemek yok"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Sonuç bulunamadı"),
        "noStudents": MessageLookupByLibrary.simpleMessage("Öğrenci yok"),
        "notAvailableLabel":
            MessageLookupByLibrary.simpleMessage("Mevcut Değil"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Hiçbir şey eklenmedi"),
        "notificationActivationError": MessageLookupByLibrary.simpleMessage(
            "Bildirim etkinleştirme sorunu. Lütfen daha sonra tekrar deneyin."),
        "notificationsLabel":
            MessageLookupByLibrary.simpleMessage("Bildirimler"),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Beslenme Bilgileri"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Normal Kilo"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Obezite Sınıf I"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Obezite Sınıf II"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Obezite Sınıf III"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Obezite Öncesi"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Ortalama"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Artmış"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Düşük \n(ancak diğer \nklinik sorunların riski artmış)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Orta"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Şiddetli"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Çok şiddetli"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Düşük Kilolu"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("futbol"),
        "paAmericanFootballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("dokunmatik, bayrak, genel"),
        "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("okçuluk"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("avcılık dışı"),
        "paAutoRacing": MessageLookupByLibrary.simpleMessage("otomobil yarışı"),
        "paAutoRacingDesc":
            MessageLookupByLibrary.simpleMessage("açık tekerlek"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("sırt çantasıyla gezme"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "sosyal tekler ve çiftler, genel"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("basketbol"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paBicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("bisiklet sürme"),
        "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("dağ bisikleti"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("sabit bisiklet"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("bilardo"),
        "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("boks"),
        "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("kum torbası"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boks"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ringde, genel"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("kalistenik"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "hafif veya orta derecede çaba, genel (ör. sırt egzersizleri)"),
        "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("kano"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "kürek çekme, zevk için, genel"),
        "paCatch": MessageLookupByLibrary.simpleMessage("futbol veya beyzbol"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("yakalama oyunu"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("amigo"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
            "jimnastik hareketleri, rekabetçi"),
        "paChildrenGame":
            MessageLookupByLibrary.simpleMessage("çocuk oyunları"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(ör. seksek, 4-kare, dodgeball, oyun alanı aletleri, t-ball, tetherball, misket, arcade oyunları), orta derecede çaba"),
        "paClimbingHillsNoLoadGeneral":
            MessageLookupByLibrary.simpleMessage("tepe tırmanma, yük yok"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("yük yok"),
        "paCricket": MessageLookupByLibrary.simpleMessage("kriket"),
        "paCricketDesc":
            MessageLookupByLibrary.simpleMessage("vuruş, bowling, saha"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("kroket"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aerobik"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paDancingGeneral": MessageLookupByLibrary.simpleMessage("genel dans"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "ör. disko, halk, İrlanda step dansı, hat dansı, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("dart"),
        "paDartsWallDesc":
            MessageLookupByLibrary.simpleMessage("duvar veya çim"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("dalış"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "deri dalışı, scuba dalışı, genel"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("dalış"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("trambolin veya platform"),
        "paFencing": MessageLookupByLibrary.simpleMessage("eskrim"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("frisbee oyunu"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("jimnastik"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("hentbol"),
        "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("yelken kanat"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paHeadingBicycling":
            MessageLookupByLibrary.simpleMessage("bisiklet sürme"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("koşullandırma egzersizi"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("dans"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("koşu"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("spor"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("yürüyüş"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("su aktiviteleri"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("kış aktiviteleri"),
        "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("yürüyüş"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("kırsal alan"),
        "paHockeyField": MessageLookupByLibrary.simpleMessage("çim hokeyi"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("at binme"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("buz hokeyi"),
        "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("buz pateni"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("koşu"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("jonglörlük"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kano"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("orta derecede çaba"),
        "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lakros"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paLawnBowling": MessageLookupByLibrary.simpleMessage("çim bowling"),
        "paLawnBowlingDesc":
            MessageLookupByLibrary.simpleMessage("bocce topu, açık hava"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("dövüş sanatları"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "farklı tipler, orta tempo (ör. judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boks)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("dövüş sanatları"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "farklı tipler, daha yavaş tempo, acemi performansçılar, pratik"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-kros"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "arazi motor sporları, arazi aracı, genel"),
        "paMountainClimbing": MessageLookupByLibrary.simpleMessage("tırmanma"),
        "paMountainClimbingDesc":
            MessageLookupByLibrary.simpleMessage("kaya veya dağ tırmanışı"),
        "paOrienteering": MessageLookupByLibrary.simpleMessage("oryantiring"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("kürek tahtası"),
        "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("ayakta"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("pedallı tekne"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("rahat, genel"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("at üzerinde"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("raketbol"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("direnç antrenmanı"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "ağırlık kaldırma, serbest ağırlık, nautilus veya evrensel"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("rodeo sporları"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("genel, orta derecede çaba"),
        "paRollerbladingLight":
            MessageLookupByLibrary.simpleMessage("patenle kayma"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("sıralı paten"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("ip atlama"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "orta tempo, 100-120 atlama/dakika, genel, 2 ayak atlama, düz atlama"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("ip atlama"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("birlik, takım, rekabetçi"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
            "dokunmatik, rekabetçi olmayan"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("koşu"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("yelken"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "tekne ve tahta yelken, rüzgar sörfü, buz yelken, genel"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("kaykay"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel, orta derecede çaba"),
        "paSkatingRoller": MessageLookupByLibrary.simpleMessage("paten kayma"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("kayak"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("su kayağı"),
        "paSkiingWaterWakeboardingDesc":
            MessageLookupByLibrary.simpleMessage("su veya wakeboarding"),
        "paSkydiving": MessageLookupByLibrary.simpleMessage("paraşütle atlama"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "paraşütle atlama, base jumping, bungee jumping"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("şnorkelle dalış"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("kar küreme"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("elle, orta derecede çaba"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("futbol"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("rahat, genel"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softbol / beyzbol"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "hızlı veya yavaş atış, genel"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("sörf"),
        "paSurfingDesc":
            MessageLookupByLibrary.simpleMessage("vücut veya tahta, genel"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("yüzme"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "su üzerinde durma, orta derecede çaba, genel"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("masa tenisi"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("masa tenisi, ping pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai chi, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("atletizm"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(ör. gülle, disk, çekiç atma)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(ör. yüksek atlama, uzun atlama, üçlü atlama, cirit, sırıkla atlama)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(ör. engelli koşu, engelli yarış)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trambolin"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("eğlence amaçlı"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("tek tekerlekli bisiklet"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("voleybol"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "rekabetçi olmayan, 6 - 9 üyeli takım, genel"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("yürüyüş"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("zevk için"),
        "paWalkingTheDog":
            MessageLookupByLibrary.simpleMessage("köpeği gezdirmek"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paWaterAerobics": MessageLookupByLibrary.simpleMessage("su egzersizi"),
        "paWaterAerobicsDesc":
            MessageLookupByLibrary.simpleMessage("su aerobiği, su kalistenik"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("su topu"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("su voleybolu"),
        "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("su aerobiği"),
        "paWateraerobicsCalisthenicsDesc":
            MessageLookupByLibrary.simpleMessage("su aerobiği, su kalistenik"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("güreş"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "iş yerinde çoğunlukla ayakta durma veya yürüme ve aktif serbest zaman aktiviteleri"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Aktif"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "ör. iş yerinde oturma veya ayakta durma ve hafif serbest zaman aktiviteleri"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Düşük Aktif"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "ör. ofis işi ve çoğunlukla oturarak geçirilen serbest zaman aktiviteleri"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Hareketsiz"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "iş yerinde çoğunlukla yürüme, koşma veya ağırlık taşıma ve aktif serbest zaman aktiviteleri"),
        "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("Çok Aktif"),
        "passwordDigit": MessageLookupByLibrary.simpleMessage("En az 1 rakam"),
        "passwordLowercase":
            MessageLookupByLibrary.simpleMessage("En az 1 küçük harf"),
        "passwordMinLength":
            MessageLookupByLibrary.simpleMessage("En az 8 karakter"),
        "passwordRequired":
            MessageLookupByLibrary.simpleMessage("Şifre gerekli"),
        "passwordSpecialChar":
            MessageLookupByLibrary.simpleMessage("En az 1 özel karakter"),
        "passwordUppercase":
            MessageLookupByLibrary.simpleMessage("En az 1 büyük harf"),
        "per100gmlLabel":
            MessageLookupByLibrary.simpleMessage("100g/ml başına"),
        "perServingLabel":
            MessageLookupByLibrary.simpleMessage("Porsiyon Başına"),
        "portionEatLabel":
            MessageLookupByLibrary.simpleMessage("Yenilen porsiyon"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Gizlilik politikası"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("protein"),
        "proteinsLabel": MessageLookupByLibrary.simpleMessage("Proteinler"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Miktar"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Gizlilik politikasını okudum ve kabul ediyorum."),
        "recentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("Son Eklenenler"),
        "recipeLabel": MessageLookupByLibrary.simpleMessage("Tarif"),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Geliştiriciye bir hata bildirmek istiyor musunuz?"),
        "resetPasswordButton":
            MessageLookupByLibrary.simpleMessage("Şifreyi değiştir"),
        "resetPasswordChanged": MessageLookupByLibrary.simpleMessage(
            "Şifre değiştirildi! Artık yeni şifrenle giriş yapabilirsin."),
        "resetPasswordConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Şifreyi onayla"),
        "resetPasswordNewLabel":
            MessageLookupByLibrary.simpleMessage("Yeni şifre"),
        "resetPasswordNoMatch":
            MessageLookupByLibrary.simpleMessage("Şifreler eşleşmiyor"),
        "resetPasswordTips": MessageLookupByLibrary.simpleMessage(
            "• En az 8 karakter kullan\n• Rakam ve özel karakterler ekle\n• Büyük ve küçük harf kullan"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Yeni şifre"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Tekrar Dene"),
        "roleCoachLabel": MessageLookupByLibrary.simpleMessage("Antrenör"),
        "roleLabel": MessageLookupByLibrary.simpleMessage("Rol"),
        "roleStudentLabel": MessageLookupByLibrary.simpleMessage("Öğrenci"),
        "saturatedFatLabel": MessageLookupByLibrary.simpleMessage("doymuş yağ"),
        "scanProductLabel": MessageLookupByLibrary.simpleMessage("Ürünü Tara"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
            "Lütfen bir arama kelimesi girin"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Yiyecek"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Ara"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Ürünler"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Arama sonuçları"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Cinsiyet Seçin"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Boy Seçin"),
        "selectPalCategoryLabel":
            MessageLookupByLibrary.simpleMessage("Aktivite Seviyesini Seçin"),
        "selectRoleDialogLabel":
            MessageLookupByLibrary.simpleMessage("Rol Seçin"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Kilo Seçin"),
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Anonim kullanım verileri gönder"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Porsiyon"),
        "servingSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Porsiyon boyutu (oz/fl oz)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Porsiyon boyutu (g/ml)"),
        "setMacrosLabel":
            MessageLookupByLibrary.simpleMessage("Makro hedeflerini ayarla"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("Hakkında"),
        "settingFeedbackLabel":
            MessageLookupByLibrary.simpleMessage("Geri Bildirim"),
        "settingsCalculationsLabel":
            MessageLookupByLibrary.simpleMessage("Hesaplamalar"),
        "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Mesafe"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("İmperial (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Ayarlar"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Lisanslar"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Kütle"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metrik (kg, cm, ml)"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Gizlilik Ayarları"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Hata Bildir"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Kaynak Kodu"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Sistem"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Koyu"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Tema"),
        "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Açık"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Sistem varsayılanı"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Birimler"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Hacim"),
        "signOutOfflineMessage": MessageLookupByLibrary.simpleMessage(
            "Verilerin kaybolmaması için yalnızca internet bağlantısı olduğunda çıkış yapabilirsiniz."),
        "signOutSyncFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Veriler senkronize edilemedi. Lütfen daha sonra tekrar giriş yapın."),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "ör. elma, dondurma, çikolata ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Atıştırmalık"),
        "stepsLabel": MessageLookupByLibrary.simpleMessage("adım"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("şeker"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("tüketilen"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Birim"),
        "websiteLabel": MessageLookupByLibrary.simpleMessage("web sitesi"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Kilo"),
        "yearsLabel": m3
      };
}
