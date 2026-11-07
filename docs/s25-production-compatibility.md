# Test S25 avec la production actuelle

Le client fonctionne désormais avec le schéma déjà déployé. **Aucune migration ni modification de production n’a été effectuée pour ce correctif de compatibilité.**

## Corrections

- Le moteur détecte le contrat serveur par une lecture limitée au compte connecté. Si les colonnes de version n’existent pas, il utilise les tables actuelles de poids et journées, avec `updatedat` pour les pesées et `updated_at` pour les journées. Les clés d’upsert restent composites utilisateur/date.
- Les données sortantes passent toujours par la préparation partagée : propriétaire, valeurs finies et bornées, déduplication et recalcul des consommations. Les champs non déployés ne sont pas envoyés.
- Les journées distantes dont le journal n’est pas présent localement ne sont pas écrasées par des zéros. Les journées ayant un journal local, y compris la suppression du dernier aliment, transmettent les totaux recalculés.
- Les suppressions de poids sont limitées au propriétaire et à la date. Les opérations locales en attente sont conservées dans les métadonnées chiffrées jusqu’à confirmation. Une ancienne réponse serveur ne peut pas effacer une édition ou suppression effectuée pendant l’envoi ; la reprise avec une nouvelle instance du moteur est testée.
- Les envois sont groupés par lots de 100 et limités dans le temps. Une modification pendant un envoi entraîne un passage supplémentaire.
- L’enregistrement d’un objectif essaie la nouvelle procédure puis utilise l’upsert actuel sur `user_id` **uniquement si la procédure n’existe pas**. Une erreur d’autorisation ne déclenche aucun contournement. Les garde-fous numériques s’appliquent aux deux parcours.
- La lecture des poids côté coach fonctionne sans colonne `deleted_at` et masque les tombstones lorsqu’elle existe.

## Ce que cette compatibilité ne déploie pas

Le serveur actuel n’a toujours pas les tables de synchronisation des aliments du journal et des recettes. Ces données conservent le fonctionnement de la version existante : **Hive local et sauvegardes ZIP**, notamment l’export avant déconnexion. La nouvelle synchronisation des lignes et l’historique serveur complet des objectifs attendent encore un déploiement coordonné. Le client conserve les deux parcours et peut utiliser le protocole versionné lorsque son schéma complet est disponible.

Cette étape rend le build testable avec la production actuelle ; elle ne signifie pas que les migrations serveur complètes du lot 6 ont été réalisées.

## Validation

- `flutter pub get` : réussi.
- `flutter analyze` : aucun problème.
- `flutter test` : **256 tests réussis**.
- `flutter build apk --debug --no-pub` : réussi ; APK dans `build/app/outputs/flutter-apk/app-debug.apk`.
- Régressions reproduites avant correction : schéma ancien refusant les nouvelles colonnes, procédure coach absente, poids coach sans `deleted_at`, et perte d’une modification pendant un envoi avec horodatage serveur.
- Le S25 n’était pas connecté au Mac : aucune installation ni connexion avec un compte réel n’a été effectuée sur l’appareil.
- Aucun commit ni push.

## Installation conservant les données

Depuis l’app actuellement installée, effectuer la déconnexion et attendre son succès afin de laisser terminer la sauvegarde existante. Brancher ensuite le S25 au Mac, avec le débogage USB autorisé.

Depuis la racine du projet, commencer par une mise à jour explicite avec ADB :

```bash
/opt/homebrew/share/android-commandlinetools/platform-tools/adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Si le résultat est `Success`, lancer ensuite :

```bash
flutter run
```

Puis se reconnecter sur le téléphone. L’installation `-r` remplace l’app sans la désinstaller. Si la signature diffère ou que le numéro de version est inférieur, ADB refuse l’opération : conserver l’installation et examiner l’erreur avant de poursuivre. Ne pas contourner ce refus par une désinstallation, qui effacerait les données locales ; Flutter peut tenter une réinstallation après certains échecs d’installation.
