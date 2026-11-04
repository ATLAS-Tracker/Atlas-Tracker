# Audit UX/UI — branche `refactor/ui` (2 nov. 2026)

Audit fait à la lecture du code (app non lancée : pas de simulateur iOS disponible). Chemins relatifs à `lib/`.
Priorités : **P0** bloque ou induit en erreur · **P1** friction notable · **P2** finition.

---

## P0 — à corriger avant une release

### Données fausses ou trompeuses
| # | Écran | Problème | Correction |
|---|---|---|---|
| 1 | Accueil, Journal | Les kcal restantes sont bloquées à 0 et la barre à 100 % (`home/presentation/widgets/dashboard_widget.dart:85`, `diary/presentation/widgets/diary_summary_card.dart:46`, `core/presentation/widgets/macro_energy_bar.dart:35`). À 600 kcal au-dessus, on voit « 0 kcal restantes » comme si l'objectif était pile atteint. | Afficher « +600 kcal au-dessus » dans une couleur d'alerte et matérialiser le dépassement sur la barre. |
| 2 | Coach (jour, tendance) | Même problème sur l'anneau et les barres de macros, plafonnés à 100 % (`profile/student_macros_page.dart:506,706`). | Idem, avec une couleur d'alerte au-delà de 110 %. |
| 3 | Poids, Coach | « Objectif / Reste à l'objectif » utilise le **poids du profil**, pas un poids cible (`add_weight/presentation/add_weight_screen.dart:124,453`, `student_macros_bloc.dart:112`). | Créer un vrai champ `targetWeightKg`. En attendant, masquer ces deux valeurs. |
| 4 | Profil | Taille, activité, âge et objectif sont modifiables mais **ne changent rien** aux calories : l'objectif ne vient que des macros du coach, ou des valeurs par défaut 120/250/60 g. | Afficher les objectifs actuels avec « Fixés par votre coach », et retirer ou étiqueter les champs sans effet. |
| 5 | Ajout d'aliment | Effacer le champ quantité enregistre l'ancienne quantité. En mode portion, rien ne se passe. « 0 » est accepté (`meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart:225`). | Désactiver « Ajouter » et afficher une erreur si le champ est vide ou ≤ 0. |
| 6 | Ajout d'aliment | ⚠️ **Régression récente :** quand on modifie un produit Open Food Facts, il garde `source: off` (`edit_meal/presentation/bloc/edit_meal_bloc.dart:62`). La fiche recharge alors le produit et **écrase les valeurs corrigées**. | Passer en `source: custom` après une modification. |

### Navigation cassée / actions destructrices
| # | Écran | Problème | Correction |
|---|---|---|---|
| 7 | Journal | Un **appui long supprime l'aliment immédiatement**, sans confirmation ni annulation (`diary/diary_page.dart:338`), alors que le même geste lance aussi un glisser-déposer. | Feuille d'actions Modifier / Copier / Supprimer, ou snackbar avec « Annuler ». |
| 8 | Ajout d'aliment | Enregistrer un aliment modifié fait `pushNamedAndRemoveUntil(addMealRoute)` (`edit_meal/presentation/edit_meal_screen.dart:507`). Venu de l'Accueil, du Journal ou d'une recette, **toute la pile de navigation est vidée** : écran noir après « Ajouter », brouillon de recette perdu. | `pop(result)` ou `pushReplacement`. |
| 9 | Recettes | Modifier une recette **l'ajoute à nouveau au journal** (`create_meal/create_meal_modal.dart:231`), et on ne peut pas enregistrer une recette sans l'ajouter. | En mode édition, enregistrer sans ajouter au journal. |
| 10 | Connexion | Les **règles de création de mot de passe s'appliquent à la connexion** (`auth/login_screen.dart:312` → `PasswordUtils.validate`). Un mot de passe valide contenant `-`, `_` ou `+` est refusé avant même d'appeler Supabase. | À la connexion, vérifier uniquement que le champ n'est pas vide. |
| 11 | Journal / Accueil | La saisie de quantité utilise un clavier sans virgule sur iOS. Une valeur vide fait planter `double.parse` sans retour, et le champ est pré-rempli « 150.00 » (`edit_dialog.dart:55,102`). | `numberWithOptions(decimal: true)`, `tryParse` avec un message d'erreur, et un format français. |

### Lisibilité / accessibilité
| # | Problème | Correction |
|---|---|---|
| 12 | Couleurs des macros utilisées pour du texte sur fond clair : glucides #f2a51a **1,97:1**, lipides #16b892 **2,41:1**, protéines 3,86:1 (WCAG demande 4,5:1). Le pire cas : les grammes des cartes repas en 10 pt, réduits en plus par `FittedBox` (`intake_card.dart:415`). | Couleurs pures réservées aux pastilles et aux remplissages. Pour le texte, des variantes foncées, ou du texte neutre à côté d'une icône colorée. |
| 13 | L'écart de poids du Journal est en rouge #E51C26 sur le bleu de la marque, soit un contraste d'environ **1:1** : invisible (`diary_summary_card.dart:168`). | Texte blanc avec une flèche ↑/↓, ou une pastille blanche. |
| 14 | Mode sombre : les cartes ont la même couleur que le fond (#121212 sur #121212, `core/styles/color_schemes.dart:96`) et disparaissent. | Une vraie gamme de gris (`surfaceContainerLow` ≈ #1a1b1f, etc.). |
| 15 | 16 boutons-icônes sur 39 n'ont ni tooltip ni libellé : VoiceOver et TalkBack lisent seulement « bouton » (scanner, crayon, « + », mot de passe…). | Tooltip localisé sur chaque `IconButton`. |

---

## P1 — friction notable

**Parcours principal (logger un repas)**
- **Pas de bouton « Ajouter » permanent :** il faut faire défiler jusqu'au bon repas, et l'Accueil est bloqué sur aujourd'hui. Ajouter un bouton flottant ou un onglet central, avec le repas présélectionné selon l'heure.
- **La recherche n'indique ni le repas ni le jour** (titre « Rechercher », bouton « Ajouter »). Afficher « Dîner · lun. 2 nov. » et « Ajouter au dîner ».
- **Les cartes de résultats n'ont pas de kcal**, et « 1000 g » s'affiche sans étiquette. Ajouter « xxx kcal / 100 g » et « Paquet 1 kg ».
- **Rien quand la recherche ne trouve rien :** ajouter « Créer « {recherche} » » et « Scanner ». Le crayon sans libellé et la boîte de confirmation redondante sont à supprimer.
- **Les aliments personnalisés ne sont jamais enregistrés** dans une bibliothèque : on les perd si on revient en arrière.
- **Changer d'unité garde le nombre :** « 1 portion » devient « 1 g ». Il faut convertir.
- **Le champ quantité ajoute un écouteur à chaque reconstruction** (`meal_detail_bottom_sheet.dart:74`), donc la saisie devient de plus en plus lente.
- **Une fiche ouverte depuis le journal propose « Ajouter »**, ce qui crée un doublon. Proposer plutôt « Modifier la quantité ».
- **Le champ de recherche n'a pas le focus automatique**, et le message de chargement parle de 20 secondes, ce qui inquiète.
- **Scanner :** un nouveau contrôleur est créé à chaque reconstruction, un même scan déclenche plusieurs ajouts, et « produit non trouvé » ne propose pas de saisie manuelle.
- **Recettes :**
  - le choix du repas commence toujours à petit-déjeuner, aujourd'hui ;
  - on peut quitter sans avertissement de modifications non enregistrées ;
  - le texte parle de portions, mais la recette entière compte pour une seule portion ;
  - la suppression se fait par glisser-déposer, sans confirmation.

**Accueil / Journal**
- **Hiérarchie de l'Accueil :** le titre de l'objectif est plus gros que les kcal restantes. Le poids apparaît 3 fois, et le premier repas est sous la ligne de flottaison.
- **Le Journal est replié par défaut**, et chaque repas est replié à nouveau à l'intérieur : environ 6 taps pour modifier un aliment d'un jour passé. Tout se replie après chaque modification.
- **Gestes cachés :** un appui long sur l'Accueil lance un glisser-déposer qui déplace l'aliment ou le supprime, sans aucune indication. Prévoir un menu « ⋮ » par aliment.
- **Suppressions incohérentes :** certaines ont une confirmation, d'autres non, et aucune ne propose d'annulation. Dans les boîtes de dialogue, « OK » est à gauche, sans couleur d'alerte.
- **Copier n'existe que dans le Journal :** ajouter « Copier depuis hier » sur un repas vide de l'Accueil.
- **Pas d'état d'erreur ni de mode hors-ligne :** l'écran tourne indéfiniment. Ajouter « Réessayer » et le tirer-pour-rafraîchir.
- **Changer de jour** se fait seulement semaine par semaine : environ 13 taps pour remonter 3 mois. Ajouter un sélecteur de date et une puce « Aujourd'hui ».
- **Formats de nombres mélangés :** « 72.5 kg » sur l'Accueil, « 72,5 kg » dans le Journal.

**Poids / Profil / Réglages / Connexion**
- **Premier lancement :** pas d'onboarding, pas d'inscription, et aucune explication du type « compte créé par votre coach ». Pas d'autoremplissage du mot de passe.
- **Réinitialisation du mot de passe :** entièrement en anglais, erreurs Supabase brutes, pas de renvoi du code. `signInWithOtp` peut créer un compte sur une adresse mal tapée.
- **Erreurs de connexion :** affichées en anglais (« Invalid login credentials »). Un profil absent provoque une déconnexion silencieuse.
- **Crashlytics est activé par défaut, sans consentement** (`config_data_source.dart:118`) : risque RGPD/CNIL.
- **Poids :**
  - plafond à 150 kg ;
  - en mode impérial, la saisie est enregistrée en kg ;
  - la saisie au clavier est cachée (il faut taper sur le chiffre) ;
  - le graphique invente des points et prolonge la courbe à plat ;
  - l'historique n'est pas modifiable.
- **Les curseurs poids et taille du profil** couvrent ±50 kg avec 1 000 crans : impossible à régler précisément.
- **Déconnexion sans confirmation.** La suppression de compte n'a pas de bouton rouge, pas d'indicateur de progression, et permet le double tap.

**Coach**
- **Historique des objectifs :** une seule ligne, écrasée à chaque enregistrement. Masquer l'onglet ou stocker une ligne par objectif.
- **Après l'enregistrement d'un objectif :** aucun retour pour le coach, rien pour l'élève, et la liste des élèves n'est pas rafraîchie.
- **Liste des élèves :** pas de tri par élève « en retard » ou « hors objectif », pas de date de dernière saisie, et l'UUID s'affiche quand le nom manque.
- **Éditeur :**
  - grammes uniquement, sans aucun garde-fou (0 g partout est accepté) ;
  - le bouton désactivé n'explique pas pourquoi ;
  - la date par défaut est demain, sans l'indiquer.
- **Statistiques de tendance :** elles incluent la journée en cours, à moitié saisie, et toute journée > 0 kcal compte comme « remplie ».
- **Le coach ne voit pas ce que l'élève a mangé :** seulement les totaux.
- **Erreurs :** sans bouton réessayer, avec le message d'exception brut.

---

## P2 — finition (extrait)

- **Formats français :** décimales avec un point à plusieurs endroits, kcal tronquées au lieu d'arrondies, « g » et « % » codés en dur, mélange du tutoiement et du vouvoiement.
- **Valeurs manquantes :** « Fibres 0 g » au lieu de « — ».
- **Tailles de texte :** 22 `FittedBox` réduisent le texte que l'utilisateur a agrandi, et 272 hauteurs sont fixées en dur.
- **Cibles tactiles < 48 dp :** flèches du calendrier (40), sélecteurs de période coach (38), puces Poids/Calories (~24).
- **Graphiques et anneaux :** non décrits pour les lecteurs d'écran.
- **Tendance du poids :** indiquée par la couleur seule. « Maintenir » vire au rouge dès ±0,2 kg, ce qui inquiète inutilement.
- **Réglages :**
  - les lignes n'affichent pas leur valeur actuelle ;
  - l'icône « Unités » est un flocon ;
  - pas de choix de langue.
- **Premier utilisateur :** il voit 4 cartes « 0 kcal » identiques, sans invitation à commencer.
- **Coquilles :** 356 jours au lieu de 365 (calendrier, copie). La zone de suppression rouge est opaque à cause d'un `..withValues` ignoré.

---

## Bugs graphiques potentiels

Détectés à la lecture du code. « Sûr » : le code produit le bug à coup sûr. « Probable » : il dépend de l'appareil ou des données.

| # | Écran | Ce que voit l'utilisateur | Cause | Correction | Certitude |
|---|---|---|---|---|---|
| G1 | Fiche produit | **Bandes noires** en haut (barre d'état) et en bas (indicateur d'accueil) sur tout iPhone avec encoche ou Dynamic Island, et sur Android en plein écran | `SafeArea` placée **autour** du `Scaffold` (`meal_detail/meal_detail_screen.dart:94`, idem pour le chargement à la l.131) | Retirer cette `SafeArea`, mettre `SafeArea(top: false)` sur la barre du bas | sûr |
| G2 | Recherche | **Le crayon de la barre du haut clignote** (disparaît puis revient) à chaque changement d'onglet ou retour de la fiche. Les blocs créés ne sont jamais fermés | `locator<AddMealBloc>()..add(...)` appelé dans `build` sur une factory (`add_meal/presentation/add_meal_screen.dart:102`) | Créer le bloc dans `initState`, le fermer dans `dispose` | sûr |
| G3 | Liste des élèves (coach) | Un tirer-pour-rafraîchir **efface toute la liste** au profit d'un spinner plein écran, puis la liste revient en haut. Même chose à chaque retour sur l'onglet | Nouveau `Future` dans le `FutureBuilder` ; `MainScreen` reconstruit les pages sans `IndexedStack` (`coach_students_page.dart:84,97`, `main_screen.dart:90`) | Spinner seulement si `!snapshot.hasData` ; `IndexedStack`, qui garde aussi le défilement du Journal | sûr |
| G4 | Visionneuse photo | **Emballage rogné** : la marque et les ingrédients sont coupés sur les côtés | `BoxFit.cover` en plein écran (`core/presentation/widgets/image_full_screen.dart:51,66`) | `BoxFit.contain` sur fond noir | sûr |
| G5 | Fiche produit | Toucher l'icône d'un aliment **sans photo** ouvre une visionneuse vide | `onTap` actif même sans photo (`meal_detail_screen.dart:238`) | `onTap: hasPhoto ? … : null` | sûr |
| G6 | Toute l'app | **Paysage autorisé** sur iPhone (`ios/Runner/Info.plist`) et Android, alors que l'interface est pensée pour le portrait. Débordements (« BOTTOM OVERFLOWED ») dans l'éditeur coach avec le clavier, sur la recherche et sur la fiche produit | Pas de `setPreferredOrientations` | Verrouiller le portrait sur téléphone | sûr (config) / probable (débordements) |
| G7 | Boîte « Modifier l'aliment » | Les boutons sont **coupés sous le clavier** sur iPhone SE, avec un grand texte ou en paysage | `AlertDialog` sans `scrollable: true` (`core/presentation/widgets/edit_dialog.dart:51`, ainsi que `add_activity_screen`, `reset_password_screen`) | `scrollable: true` | probable |
| G8 | Graphique de poids | Sur 3 mois ou 1 an, les **graduations de l'axe Y se chevauchent** ou s'affichent de façon irrégulière | Intervalle Y fixé à 0,5 (`add_weight_screen.dart:1279`) | Intervalle calculé selon la plage (environ 4 graduations) | probable |
| G9 | Profil | **Disque bleu vide** à la place de l'avatar après une réinstallation ou un changement de téléphone | `FileImage` sans gestion d'erreur quand le fichier local manque (`profile_photo_picker.dart:84`) | Vérifier que le fichier existe, sinon afficher l'icône | probable |
| G10 | Fiche produit | **La page saute** à chaque chiffre tapé dans le champ quantité si on a défilé vers le tableau nutritionnel | `Scrollable.ensureVisible` animé à chaque frappe (`meal_detail_screen.dart:493`) | Défiler seulement si les kcal sont hors de l'écran | probable |

Vérifiés sans problème : tags `Hero`, valeurs du menu des unités, anneau et barre avec un objectif à 0, calendrier sur un écran de 320 pt, cache d'images.

---

## Incohérences d'information

Endroits où la même donnée est calculée ou affichée différemment : un utilisateur qui compare deux écrans voit des chiffres ou des mots contradictoires.

**I1 — L'Accueil et le Journal ne lisent pas la même source (sûr)**
- L'Accueil **recalcule** la somme des aliments du jour, et l'objectif à partir des macros (`home_bloc.dart:94`, `get_kcal_goal_usecase.dart:13`).
- Le Journal lit `TrackedDay` : un cumul **incrémenté** à chaque modification, avec un objectif figé à la première saisie du jour (`diary_summary_card.dart:43`).
- Dans le Journal, la liste des repas et le résumé peuvent donc se contredire **sur le même écran**.
- Cause vérifiée : `HomeBloc.deleteIntakeItem` et `updateIntakeItem` appliquent l'écart à `DateTime.now()` et non à la date de l'aliment (`home_bloc.dart:227,261`). Si l'Accueil est resté ouvert après minuit, supprimer un aliment de la veille retire ses kcal **du jour en cours**.
- `TrackedDay.updatedAt` n'est écrit qu'à la création, donc les totaux modifiés sur un autre appareil ne se synchronisent jamais (probable).
- **Source unique proposée :** la somme des aliments, avec `TrackedDay` **recalculé** (et non incrémenté) après chaque écriture.

**I2 — Le coach et l'élève voient des chiffres différents pour le même jour**
- Le coach lit `tracked_days` sur Supabase, l'élève lit ses données locales (Hive).
- Quand le coach enregistre un objectif, l'élève ne le récupère qu'au démarrage ou à une notification push. S'il saisit un repas entre-temps, sa ligne locale **écrase l'objectif du coach** pour ce jour (probable).
- Arrondis différents : le coach utilise `round()`, l'élève `toInt()`. 899,6 kcal donne « 900 kcal » chez le coach et « 899 » chez l'élève.

**I3 — Les kcal affichées ne s'additionnent pas (sûr)**
- Exemple sur l'Accueil : « 1240 kcal restantes » et « 899 / 2140 consommées », alors que 1240 + 899 ≠ 2140.
- Chaque aliment, chaque repas et le total du jour sont tronqués séparément. Quatre repas de 400,7 / 600,6 / 500,8 / 100,9 donnent des en-têtes qui font 1 600, alors que le total du jour affiche 1 603.
- **Correction :** arrondir une seule fois, puis calculer « restantes = objectif − consommé » sur les valeurs arrondies.

**I4 — « Poids actuel » change de sens selon l'écran (sûr)**
- Accueil et Journal : uniquement le poids **du jour**, « — » sinon.
- Écran Poids : le **dernier** poids enregistré, ou à défaut le poids du profil.
- Pesé hier : l'Accueil affiche « — », mais en touchant la carte, l'écran Poids affiche « 72,5 kg » avec un écart.
- Sans aucun historique, l'écran Poids affiche quand même un écart calculé par rapport au poids du profil.

**I5 — Cinq « écarts de poids » différents sous des libellés semblables (sûr)**

| Écran | Calcul |
|---|---|
| Accueil, Journal, Historique | poids du jour − moyenne des 7 jours **précédents** |
| Écran Poids, en-tête | **dernier** poids − cette même moyenne (avec repli sur le profil) |
| Écran Poids, graphique 7 j | « Moyenne de la période », **aujourd'hui inclus** : « +0,4 » à côté d'une moyenne qui donne +0,3 |
| Coach, tendance | dernier − premier poids de la période, libellé simplement « Poids » |
| Coach, jour | poids − poids du profil, libellé « vs objectif » |

- Signes différents : Accueil « + 0.3 » (avec espace), Journal « +0,3 », coach « −0,3 ».
- Couleurs différentes : un écart nul est orange sur l'Accueil et rouge ailleurs.
- **Source unique proposée :** un formateur partagé et `weightTrendColor` partout.

**I6 — « Objectif » désigne trois choses (sûr)**
- L'Accueil titre « **Objectif coach** : Prise de masse », alors que cette valeur est choisie **par l'élève** dans son profil.
- L'écran Poids affiche la même valeur sous un autre libellé : « Objectif : **Prendre du poids** ».
- Le poids cible s'appelle « Cible » sur l'Accueil et « Objectif » sur l'écran Poids. Le reste s'appelle « restants » sur l'un et « Reste à l'objectif » sur l'autre.
- « Objectif » sert aussi pour les kcal dans la tendance coach.

**I7 — L'éditeur coach présente des valeurs par défaut comme un objectif existant (probable)**
- Sans objectif défini par le coach, les jours de l'élève reçoivent 250/60/120 g, soit 2 020 kcal.
- Le coach voit donc « objectif 2 020 kcal » et un formulaire pré-rempli, alors que l'encart « objectif précédent » est vide.

**I8 — Les pastilles du calendrier contredisent les chiffres (sûr)**
- Une pastille est verte si le total est entre −1 000 et +500 kcal de l'objectif (`tracked_day_entity.dart:77`).
- Avec un objectif de 2 000, un jour à 1 050 kcal (52 %) est **vert** et un jour à 2 550 kcal est **rouge**.
- Un jour vidé de tous ses aliments reste rouge, alors que le coach affiche « — ».
- Il faut une seule règle « dans l'objectif », partagée avec la tendance coach.

**I9 — Les portions s'affichent différemment selon l'écran (sûr)**
- Dans un repas : « 2 Portion », avec majuscule, sans pluriel et sans grammes. Sur la fiche produit : « 2 portions (de 60 g) ».
- Dans une recette, un ingrédient ajouté en portions est enregistré avec l'unité `serving` mais une quantité **en grammes** : la recette affiche « 60 Portion » pour 2 × 30 g. Les kcal restent justes.
- **Correction :** enregistrer `unit: 'g'` dans le parcours recette.

**I10 — Ordre des macros (sûr, faible impact)**
- Partout l'ordre est glucides, lipides, protéines, sauf le tableau nutritionnel de la fiche produit (lipides, glucides, protéines), qui utilise en plus un autre libellé (`carbohydrateLabel` au lieu de `carbsLabel`).

**I11 — Objectif ancien qui revient chez l'élève (probable, rare)**
- `addMacroGoalFromCoach` repart de l'avant-dernier objectif (`add_macro_goal_usecase.dart:41`).
- Scénario : objectifs A puis B, puis C programmé à une date future, sans que l'élève ait ouvert l'app entre-temps. L'élève revoit **A** jusqu'à la date de C, alors que le coach voit B.

---

## Système de design

| Constat | Chiffres |
|---|---|
| Rayons | 20 valeurs différentes |
| Marges | 30+ `EdgeInsets` différents |
| Décorations | 94 `BoxDecoration` en ligne contre 4 utilisations de `atlasCardDecoration` |
| Graisses | w800 ×66, w700 ×42, w900 ×7 : pas de hiérarchie, chiffres empâtés |
| Icônes | outlined (114), rounded (78), filled (~130) mélangées |
| Composants doublons | 7 pastilles et badges privés, 7 implémentations d'onglets |
| Couleurs en dur | `Colors.white` ×53. Le panneau bleu de la marque reste clair en mode sombre |
| Palette | `outline` = noir pur en mode clair. `secondary` est cassé (alpha 15 %). `material-theme.json` n'est plus synchronisé |
| Polices | Poppins : 18 fichiers (3 Mo) sans `weight:` déclarée, Light marquée italique par erreur |

**Recommandations**
1. Régénérer les palettes claire et sombre à partir d'une seule couleur de base, avec une vraie gamme de gris en mode sombre et des contours gris.
2. Créer une extension de thème `AtlasTokens` (dégradé de la marque, texte sur fond de marque, couleurs des macros pour le remplissage et pour le texte, succès/alerte/info), avec une variante sombre. Interdire `Colors.white` et `Colors.orange` dans les écrans.
3. Définir des tokens de rayon {8, 12, 16, 24, pilule} et d'espacement {4, 8, 12, 16, 24, 32}, et câbler `cardTheme`, `dialogTheme` et `chipTheme`.
4. Créer des composants partagés `AtlasPill` et `AtlasStat` (chiffres tabulaires, w700 maximum), et tout faire passer par `AtlasTabBar`.
5. Mettre en place un garde-fou d'accessibilité : tooltip obligatoire, Semantics sur les graphiques, tests visuels en mode sombre et avec un texte à 200 %.

---

## Ce qui marche bien
- **Langage visuel Atlas cohérent** : même panneau de marque, mêmes icônes et couleurs de macros partout.
- **L'Accueil ne clignote pas** au rafraîchissement, et la mise en page s'adapte aux grands textes.
- **Valeurs par défaut intelligentes** sur la fiche produit : portion, sinon 100 g, avec seulement g, ml et portion proposés.
- **Formulaire d'aliment personnalisé** court, avec une validation directe.
- **Côté coach, les données manquantes sont honnêtes** (« — » plutôt que 0), et les états vides, de chargement et d'erreur de la liste des élèves sont gérés.
- **Déconnexion prudente** : sauvegarde des données avant, et refus hors-ligne avec une explication en français.
- **Textes presque tous traduits** (fichiers l10n), avec une discipline typographique correcte (183 `textTheme` contre 12 tailles codées en dur).
