# Inspection Supabase production — 4 novembre 2026

Projet vérifié dans Chrome : **Atlas Tracker**, `bgllklprpgwkzaxrpivd`, branche **main / PRODUCTION**. Autorisation : inspection en lecture seule. Seuls les catalogues système ont été interrogés ; aucune ligne de données d’élève n’a été consultée et aucune donnée, policy, fonction ou structure n’a été modifiée.

## Constats prioritaires

1. **FDC exposé en écriture** : `fdc_food`, `fdc_nutrients` et `fdc_portions` ont RLS désactivée, aucune policy, et tous les droits de table pour `anon` et `authenticated`, dont INSERT, UPDATE, DELETE et TRUNCATE. Aucun grant par colonne n’a été trouvé sur ces tables. Le script local `supabase/lot6_food_readonly.sql` correspond à ce schéma : il conserve SELECT et retire les écritures, avec RLS et policy de lecture.
2. **Poids sans isolation dans les policies** : sur `user_weight`, les policies SELECT, INSERT, UPDATE et DELETE ne vérifient que l’existence d’un abonnement actif du demandeur. Leur prédicat ne limite ni `user_id` ni l’affectation coach/élève. Ce constat repose sur les définitions SQL, sans tentative d’accès à d’autres utilisateurs.
3. **Objectifs sans affectation coach/élève** : `coach_macro_goals` autorise SELECT, INSERT et UPDATE sur le seul contrôle d’abonnement actif. La clé primaire `user_id` explique l’écrasement de l’objectif précédent.
4. **Rôle de profil modifiable** : `users` accorde UPDATE au niveau table ; la policy d’UPDATE vérifie seulement `auth.uid() = id`, sans restriction de colonnes. Cela permet en principe de changer son propre `role` ou `coach_id` lorsque la ligne est visible. Aucune tentative de modification n’a été faite.
5. **Révocation de sessions exposée** : `public.revoke_user_sessions(uid uuid)` est SECURITY DEFINER, exécutable par `anon` et `authenticated`, et son corps supprime les sessions du `uid` fourni sans contrôle `auth.uid()`. Elle n’a pas été appelée. Il faut préparer sa restriction/correction avant application autorisée.
6. **Secret dans un trigger** : le trigger de notification des objectifs contient un jeton `service_role` dans ses arguments HTTP. Le secret n’est pas reproduit dans ce rapport ni utilisé. Prévoir un mécanisme de secret adapté et la rotation du jeton avec vérification des services qui en dépendent.

## Schéma réel et différences avec la fixture locale

| Table | État constaté |
| --- | --- |
| `user_intakes`, `user_recipes` | Absentes de `public`. |
| `tracked_days` | RLS active ; PK `(user_id, day)` déjà correcte ; `updated_at` et `created_at` timestamptz ; trigger `trg_set_updated_at` sur UPDATE. Les policies limitent le propriétaire et le coach assigné et exigent un abonnement actif. |
| `user_weight` | RLS active ; PK `(user_id, date)` déjà correcte ; `id uuid`, `weight numeric(5,2)` ; horodatage historique `updatedat`, sans underscore ; trigger `set_updatedat` sur UPDATE. |
| `coach_macro_goals` | PK `(user_id)` ; macros et kcal en `integer` ; `updated_at` nullable avec valeur par défaut ; FK vers `users(id)`. Aucune FK entrante vers cette table n’a été trouvée. Trigger HTTP de notification sur INSERT, UPDATE et DELETE. |
| `users` | RLS active ; rôle/coach stockés dans la table ; contraintes sur les enums et les valeurs positives ; index sur `coach_id` ; présence d’un identifiant Stripe à protéger des écritures client. |
| `fdc_food` | Uniquement `fdc_id bigint` et `description_fr text`. |
| `fdc_nutrients` | `fdc_id bigint`, `nutrient_id bigint`, `amount numeric`. FK vers `fdc_food`. |
| `fdc_portions` | `fdc_id bigint`, `measure_unit_id bigint`, `amount numeric`, `gram_weight bigint`. FK vers `fdc_food`. |

Les fonctions d’horodatage existantes imposent `now()` à UPDATE ; elles ne couvrent pas INSERT. `search_fdc_food(search text)` est SECURITY INVOKER et exécutable par les deux rôles clients ; la policy SELECT prévue sur FDC conserve son accès en lecture.

## Conséquences pour le lot 6

- **Ne pas appliquer tel quel `lot6_integrity.sql`** : il faut d’abord préserver les conditions d’abonnement existantes lors du remplacement des policies et coordonner le trigger de notification avec l’historique par date. Le SQL local actuel reste un script de préparation, pas une migration prête pour cette production.
- Reproduire localement les types et triggers réels, notamment UUID/numeric/`updatedat`, et tester les comptes abonnés/non abonnés, les rôles et les affectations.
- Les clés de journées et de poids sont déjà composites : aucun index global de date n’est à supprimer dans ce projet.
- Auditer les grants TRUNCATE et la fonction de révocation avant de considérer le contrôle d’accès sécurisé. Ne pas tester une suppression de sessions en production pour prouver le problème.
- Le webhook d’objectifs peut actuellement se déclencher aussi pour une date future. Vérifier le comportement attendu et ses dépendances avant de changer le stockage des objectifs.

## Première étape proposée, soumise à accord distinct

Appliquer uniquement **`supabase/lot6_food_readonly.sql`** aux trois tables FDC, puis vérifier en lecture seule les policies et droits effectifs. Aucune donnée alimentaire ne sera modifiée par ce script. La recherche restera autorisée en lecture. Les modifications des données utilisateurs, fonctions et objectifs feront l’objet d’étapes séparées après adaptation et tests locaux.

L’accord donné pour cette inspection n’autorise aucune de ces applications.
