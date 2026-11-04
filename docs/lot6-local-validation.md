# Atlas Tracker — changements locaux et préparation Supabase

**Compatibilité S25 ajoutée ensuite :** le client peut maintenant utiliser le serveur actuel sans les migrations complètes. Voir [les changements, limites et commandes de test](s25-production-compatibility.md).

**Mise à jour après inspection et autorisation :** un durcissement distinct, compatible avec l’ancien client, a été appliqué en production. Voir [le compte rendu de déploiement](production-security-rollout-2026-11-04.md). Les paragraphes ci-dessous décrivent la préparation initiale ; les migrations complètes du lot 6 restent non déployées.

Les lots 1 à 5 sont implémentés dans le checkout courant. Le lot 6 comprend le code client et des scripts SQL de revue, testés sur des données synthétiques dans PostgreSQL local. Aucun commit, push, déploiement ni accès au projet Supabase de production n’a été effectué.

## Comportements livrés en local

- Totaux du journal recalculés après les écritures, migration des cumuls existants, arrondis et format français partagés, dépassements visibles et dernière pesée réelle.
- Affichage métrique uniquement, sans reconversion des nombres stockés. L’ancien champ Hive des unités est retiré sans déplacer les autres identifiants.
- Menu des aliments, copie/déplacement, annulation des suppressions, édition d’une entrée sans doublon, validation des quantités et conservation de la navigation.
- Bibliothèque d’aliments personnalisés, édition des recettes sans ajout au journal, sauvegarde attendue et avertissement avant abandon d’un brouillon.
- Bouton Ajouter permanent, contexte jour/repas, résultats enrichis, saisie manuelle après un scan infructueux, journal déplié, sélection de date, copie d’hier et états d’erreur.
- Consentement Crashlytics explicite et désactivé par défaut, contraste, tooltips, photos entières et avatar de repli, portrait sur téléphone.
- Connexion compatible avec les mots de passe existants, réinitialisation française sans création implicite de compte, saisie du poids jusqu’à 400 kg et modification des pesées historiques.
- Coach : tri, dernière journée renseignée, retour après sauvegarde, historique par date d’application et conservation de l’objectif B lorsqu’un objectif C est prévu.

## Synchronisation du lot 6

`SyncPreparation` est le point de préparation des quatre tables nutritionnelles : propriétaire courant, déduplication par version, valeurs finies et bornées, recalcul des totaux et sérialisation détachée de Hive. Les lignes exclues restent locales et leur nombre est journalisé.

Le moteur lit uniquement le propriétaire connecté, compare les versions, garde les suppressions dans une boîte Hive chiffrée par utilisateur et accepte une annulation ultérieure. Les modifications reçues pendant un envoi déclenchent un nouveau passage. Les requêtes sont paginées, groupées et limitées dans le temps ; les erreurs conservent les données pour réessayer. Les anciens watchers de journées/poids et l’ancien service de démarrage ne sont plus raccordés à l’app.

La restauration automatique d’archives au démarrage est supprimée. Les rafraîchissements nutritionnels se font après affichage local. Les modifications de profil hors connexion sont conservées jusqu’à l’envoi, avant toute lecture susceptible de les écraser.

`modified_at` représente la version de modification du client ; `updated_at` est imposé par le serveur dans les scripts préparés. Les horloges de plus de cinq minutes dans le futur sont refusées. Les objectifs coach et les consommations recalculées côté serveur ne peuvent pas être remplacés par des valeurs arbitraires de l’élève.

## Scripts proposés à la revue

1. `supabase/lot6_food_readonly.sql` : lecture seule des trois tables FDC, RLS et retrait des droits d’écriture, y compris les droits accordés par colonne.
2. `supabase/journal_remote_sync.sql` : script existant de création des tables journal/recettes. Ne pas l’appliquer seul : ses policies sont remplacées par le script suivant.
3. `supabase/lot6_integrity.sql` : propriétaires, versions serveur, validations, tombstones, projections des totaux, objectifs par date et procédure contrôlée `atlas_set_macro_goal`.

Les scripts ne sont pas des migrations de production validées sur le schéma réel. Le précontrôle s’arrête devant un index unique global sur une date ; il ne supprime pas une contrainte inconnue. Le changement de clé des objectifs ne comporte pas de `CASCADE`.

Reproduction locale :

```bash
bash supabase/tests/run_lot6_local.sh
```

Ce script crée un cluster temporaire neuf, accessible uniquement par socket local, avec des utilisateurs synthétiques. Il arrête le serveur à sa sortie et conserve ses journaux dans `/tmp/atlas-lot6-check.*`. Il vérifie aussi le rejeu des scripts et le refus d’un ancien index global incompatible. **Ne jamais exécuter `lot6_fixture.sql` sur un projet hébergé.**

## Validation et limites

Vérification finale du checkout : **243 tests réussis**, `flutter analyze` sans problème, `git diff --check` propre, plist iOS et XML Android valides. Le rejeu PostgreSQL sur un cluster neuf est réussi ; les serveurs temporaires ont été arrêtés.

La validation Flutter complète est exécutée dans l’ordre `flutter pub get`, `flutter analyze`, `flutter test`. Les tests couvrent notamment le cumul erroné, les déplacements entre dates, les suppressions/annulations, les versions de recettes, l’isolation, les modifications pendant un envoi, les délais réseau et le profil hors connexion. Certains tests ont été ajoutés après implémentation ; tous n’ont pas été exécutés individuellement en rouge avant correction.

Les assertions PostgreSQL couvrent les lectures et écritures autorisées/refusées, les droits FDC, l’isolation entre élèves et coach, les quantités/poids invalides, les versions anciennes, les tombstones, les totaux et l’objectif courant conservé avant une date future.

Pas de validation sur appareil ni de compilation iOS : ce Mac ne dispose pas de Xcode complet. Le schéma, les données, les grants et les dépendances des contraintes de production n’ont pas été inspectés. La génération complète des modèles reste tributaire de la variable FDC historique manquante ; les adaptateurs modifiés sont présents et passent l’analyse et les tests avec la configuration générée existante.

## Prochaine étape nécessitant un accord

Demander d’abord l’autorisation d’inspecter **en lecture seule** le schéma, les contraintes, policies, triggers et grants du projet de production « Atlas Tracker ». Présenter ensuite les adaptations du SQL et obtenir un accord explicite avant chaque application. Ne pas publier le nouveau client avant les migrations compatibles : il attend notamment `modified_at`, `deleted_at` et la procédure d’enregistrement des objectifs.
