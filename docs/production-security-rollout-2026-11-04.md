# Sécurité compatible avec l’application en production

**Appliqué le 4 novembre 2026**, projet `bgllklprpgwkzaxrpivd`, branche main / PRODUCTION, dans Chrome. Autorisation donnée par l’utilisateur pour sécuriser les accès tout en conservant le fonctionnement de l’application déjà publiée.

## Changements appliqués

1. `supabase/lot6_food_readonly.sql` : RLS sur les trois tables FDC, SELECT conservé pour les deux rôles clients, droits d’écriture retirés. La procédure réelle `search_fdc_food('pomme')` a été exécutée sous le rôle `anon` sans erreur.
2. `supabase/production_compatible_security.sql` :
   - retrait de TRUNCATE, REFERENCES et TRIGGER aux rôles clients et PUBLIC sur les dix tables publiques existantes ;
   - douze policies **restrictives** ajoutées sur poids, objectifs et appareils. Elles se combinent avec les douze policies permissives existantes, conservées, et gardent donc les conditions d’abonnement ;
   - poids accessibles au propriétaire et à son coach assigné en lecture, écrits par le propriétaire ; objectifs lus par le propriétaire et son coach, écrits par le coach assigné ; tokens d’appareil limités à leur propriétaire ;
   - un trigger empêche les clients de changer rôle, affectation coach, identité ou identifiant Stripe, tout en permettant les modifications du profil et les écritures du backend ;
   - `revoke_user_sessions` est bloquée pour le rôle anonyme et contrôle la cible pour les utilisateurs connectés. Les appels du backend restent autorisés. Aucune révocation n’a été exécutée en production.

Les transactions utilisent un délai de verrouillage de 3 secondes et un délai d’exécution de 15 secondes. Des contrôles de lecture sous le rôle authenticated, pour chacun des six profils existants, ont été exécutés **avant le commit** de la seconde transaction. Une divergence aurait provoqué son annulation. Ils comparent l’accès réel aux poids, objectifs, appareils et profil avec le périmètre propriétaire/coach attendu, abonnement compris.

## Compatibilité conservée

- Aucune table, colonne, contrainte, clé ou donnée n’a été supprimée ou modifiée par ces scripts de durcissement.
- La clé `coach_macro_goals(user_id)` reste compatible avec l’upsert de l’application actuellement publiée.
- Les policies existantes des journées, pas, profils et abonnements sont conservées. Les policies existantes des poids/objectifs/appareils restent en place, avec les restrictions ajoutées.
- Les triggers d’horodatage et le trigger HTTP de notification des objectifs sont conservés.
- Les accès service_role du backend restent disponibles ; aucune clé n’a été changée.
- Les migrations `journal_remote_sync.sql` et `lot6_integrity.sql` n’ont **pas** été appliquées. Elles nécessitent une version client coordonnée.

## Vérifications

Sept catégories de régressions de sécurité ont été reproduites sur une fixture PostgreSQL synthétique avant correction, puis passent après correction. Les tests positifs couvrent les upserts de poids, leur suppression, les éditions de profil, le renouvellement FCM, les écritures de journées, l’upsert coach sur `user_id`, l’exécution des notifications simulées, le backend et le refus des comptes non abonnés. Le rejeu du script est aussi validé.

```bash
bash supabase/tests/run_compatible_security_local.sh
```

Le cluster local est accessible uniquement par socket et arrêté en fin de test. **Ne jamais exécuter la fixture sur une base hébergée.** Le test de lecture sans écriture est disponible dans `supabase/tests/compatible_security_read_checks.sql`.

Validation Flutter du checkout : **243 tests réussis**, `flutter analyze` sans problème ; `git diff --check` propre. Aucun commit ni push.

### Comparaison avant / après

Vérification finale : **2026-11-04 18:55:04 UTC**.

| Élément | Avant | Après |
| --- | ---: | ---: |
| Profils | 6 | 6 |
| Pesées | 592 | 592 |
| Journées | 810 | 810 |
| Objectifs | 3 | 3 |
| Appareils | 6 | 6 |
| Abonnements | 6 | 6 |
| Sessions | 69 | 69 |

Les signatures des colonnes, contraintes et du trigger de notification sont identiques avant et après :

- Colonnes : `3b92efcb1918486ef309467460a3b5af`.
- Contraintes : `6e0a00ef24622e6a1afddb92f6c4ff91`.
- Trigger de notification : `9923dfc632fe4f8b02b22f54d226f4b2`.

Après application : RLS active sur les trois tables FDC, douze policies restrictives présentes, douze policies permissives historiques conservées, zéro grant TRUNCATE aux clients sur les tables publiques, garde de profil active, exécution anonyme de la révocation refusée. Le Security Advisor relancé affiche **0 erreur et 11 avertissements** ; le Health Advisor affiche 0 erreur, 0 avertissement.

## Limites et opérations à planifier

Pas de test sur appareil ni d’envoi de notification réelle en production. Les écritures des parcours applicatifs ont été testées localement ; les contrôles sur les comptes réels sont restés en lecture seule afin de conserver leurs données et sessions.

Les avertissements restants concernent six fonctions historiques sans search_path fixé, l’exposition SECURITY DEFINER de `get_auth_and_row_id`, la révocation authentifiée désormais contrôlée, la protection des mots de passe divulgués désactivée et une mise à jour PostgreSQL disponible. Le corps inspecté de `get_auth_and_row_id` ne fait que renvoyer l’UID courant et l’identifiant fourni. La révocation authentifiée est intentionnellement maintenue avec sa garde.

La mise à jour PostgreSQL et la rotation/remise en place du secret du webhook restent à planifier avec les dépendances et une fenêtre adaptée. Les réaliser automatiquement risquerait une coupure ou une invalidation des intégrations existantes, contraire à la contrainte de compatibilité. Le secret du trigger n’est pas reproduit dans les fichiers du dépôt.

Ce déploiement est une sécurisation de la version actuellement utilisée, pas le déploiement complet du lot 6. Un correctif client ultérieur ajoute [la compatibilité avec le schéma actuel pour le test S25](s25-production-compatibility.md). Le nouveau protocole de synchronisation et l’historique serveur complet restent dépendants des migrations coordonnées.
