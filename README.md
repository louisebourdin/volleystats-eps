# VolleyStats EPS

**Analyse et améliore ton service** — application Flutter multiplateforme (Android, iOS,
Web, Windows, macOS) pour analyser des séries de 10 services au volley-ball en cours d'EPS.

## Lancer le projet

```bash
flutter pub get
flutter run            # choisit un device connecté (téléphone, Chrome, Windows...)
flutter run -d chrome   # web
flutter run -d windows  # application Windows
```

Sur Windows, générer un exécutable desktop nécessite que le **Mode développeur** soit
activé (Paramètres > Confidentialité et sécurité > Pour les développeurs), sans quoi
`flutter pub get`/`flutter run -d windows` échoue avec une erreur de lien symbolique.

## Déploiement (mise à jour automatique de l'app en ligne)

Ce dépôt GitHub est connecté à Netlify (site `moonlit-youtiao-44fcd5.netlify.app`,
alias public : https://moonlit-youtiao-44fcd5.netlify.app) en déploiement continu :

- **Chaque `git push` sur la branche `main` déclenche automatiquement** un nouveau
  build et republie le site — pas besoin de builder ni déployer manuellement.
- Netlify n'a pas Flutter préinstallé : la commande de build (configurée dans les
  paramètres du site Netlify, onglet "Build & deploy") clone le SDK Flutter stable à
  chaque build avant de lancer `flutter build web`. C'est normal si un déploiement
  prend 2 à 4 minutes. La commande nettoie d'abord le dossier `_flutter_sdk` avant de
  cloner (`rm -rf _flutter_sdk && git clone ...`) pour éviter un échec si un build
  précédent a été interrompu en cours de clonage.
- Pour vérifier qu'un déploiement a réussi : dashboard Netlify du projet → onglet
  "Deploys" → dernier déploiement → logs.

**Workflow pour modifier l'app depuis n'importe quelle session Claude Code** (y compris
depuis un autre appareil) :

1. `git clone https://github.com/louisebourdin/volleystats-eps.git`
2. Faire les modifications, tester localement (`flutter analyze`, `flutter test`,
   `flutter run -d chrome`)
3. `git add -A && git commit -m "..." && git push` sur une branche `claude/...`
4. `.github/workflows/open-pr-claude.yml` ouvre automatiquement une Pull Request vers
   `main` dès que cette branche est poussée sur GitHub — il suffit de cliquer
   "Merge" pour publier.
5. Le site public se met à jour tout seul en 1-4 minutes après le merge sur `main`.

## Historique partagé par classe (Supabase)

La classe se choisit dans un menu déroulant (2e1 à 2e5, liste `kSchoolClasses` dans
`lib/models/student.dart`). Chaque série terminée est envoyée dans une base Supabase ;
l'écran Historique affiche toutes les séries de la classe choisie, quel que soit
l'appareil qui les a enregistrées. Hors ligne, les séries restent sur l'appareil (Hive)
et partent à la prochaine synchronisation. Les séries de démonstration ne sont jamais
envoyées.

Projet Supabase actuel (déjà configuré dans `lib/config/supabase_config.dart`) :

| | |
|---|---|
| Organisation / projet | `VolleyStats EPS` / `volleystats-eps` (plan gratuit, compte GitHub louisebourdin) |
| Dashboard | https://supabase.com/dashboard/project/ugduqwhfabtmmhnbvcdx |
| URL de l'API | https://ugduqwhfabtmmhnbvcdx.supabase.co |
| Clé publishable (publique) | `sb_publishable_aaVJ2LPwXJZ0kKytEgaPJg_UCYK5Tim` |

La clé publishable peut être publique : la table `sessions` est fermée à l'accès direct,
tout passe par les fonctions de `supabase/schema.sql`. **Ne jamais committer** la clé
`sb_secret_…`/`service_role` ni le mot de passe Postgres : ils donnent un accès
administrateur complet à la base.

Pour repartir d'un nouveau projet : SQL Editor → coller `supabase/schema.sql` → Run, puis
mettre la nouvelle URL et la clé publishable dans `lib/config/supabase_config.dart` (ou au
build : `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`).

## Utilisation rapide

Depuis l'accueil : **Nouvelle série** → renseigner l'élève → choisir le **mode
d'analyse** (voir ci-dessous) → toucher le terrain après chaque service → bilan
automatique après le 10e service. Le bouton **Charger une démonstration** remplit deux
séries fictives (élève "Alex") pour présenter l'application sans taper 10 services réels.

### Deux modes d'analyse

- **Sans réception** (par défaut) : analyse classique du service seul (résultat, zone,
  régularité, précision, variété).
- **Avec réception** : en plus, pour chaque service réussi, on note où repart la
  réception adverse (zone d'arrivée + "Bonne réception" si la balle repart haute vers
  le milieu de terrain, ou "Ace" si le point est direct ou la réception ratée). Le
  bilan affiche alors un taux de **"danger provoqué"** au service. On peut aussi
  indiquer (facultatif, informatif) les postes occupés par les réceptionneurs.

### Zone(s) à travailler

À la création d'une série, on peut choisir une ou plusieurs zones à viser (Piscine
comprise). Pendant la saisie, un service qui atterrit dans le terrain mais hors de ces
zones choisies s'affiche en rouge (comme un service raté), en aide visuelle immédiate —
sans jamais changer le résultat réellement enregistré dans les statistiques.

## Architecture

```
lib/
  main.dart                 point d'entrée, initialise Hive puis Riverpod
  theme/                     couleurs et thème Material 3
  models/
    student.dart             Student
    session.dart              Session, SessionMode (sans/avec réception)
    serve.dart, serve_draft.dart   Serve (enregistré), ServeDraft (en cours de saisie)
    serve_enums.dart          ServeResult, ServeTrajectory, TossQuality, ReceptionQuality...
    court_zone.dart           CourtZones (1-6 + Piscine), classification courts/longs
    serve_analysis.dart, recommendation.dart
  services/
    storage_service.dart      persistance locale (Hive)
    statistics_service.dart   calcul du bilan à partir des Serve bruts
    recommendation_engine.dart moteur de conseils à règles
    demo_data_service.dart    séries fictives pour la démonstration
    csv_export_service.dart   génère le contenu CSV d'une série
    csv_downloader/            téléchargement du CSV (implémentation par plateforme)
  providers/                 sessionProvider (série en cours), historyProvider (séries sauvegardées)
  screens/                   home, new_session, serve, results, history
  widgets/
    court/                   terrain interactif (CustomPainter + GestureDetector), géométrie partagée
    serve_form.dart          formulaire rapide d'un service
    statistic_card.dart, recommendation_card.dart, serve_progress_indicator.dart, confirm_dialog.dart
  utils/                     responsive breakpoints, génération d'id, formatage de date FR
```

- **State management** : Riverpod (`StateNotifierProvider`). La série en cours reste
  disponible pendant toute la navigation tant qu'elle n'est pas explicitement quittée.
- **Stockage** : Hive en local (`StorageService`), avec des modèles qui se sérialisent
  eux-mêmes en `Map` (`toJson`/`fromJson`). Les données restent sur l'appareil/navigateur
  par défaut (pas de compte) ; en choisissant une classe, l'historique de cette classe est
  en plus synchronisé via Supabase — voir "Historique partagé par classe" plus bas.
- **Terrain interactif** : `CourtGeometry` définit une seule fois la géométrie des zones
  (fractions 0..1 de la largeur/hauteur), utilisée à la fois par le `CustomPainter` et par
  le détecteur de gestes. Les impacts sont stockés en coordonnées normalisées : la carte
  reste juste quelle que soit la taille d'écran. La Piscine se sélectionne comme les 6
  autres zones partout où on choisit des zones au tactile.
- **Export CSV** : `CsvExportService` génère le contenu (séparateur `;`, BOM UTF-8 pour
  Excel FR) indépendamment de la plateforme ; `csv_downloader/` choisit l'implémentation
  au moment de la compilation (import conditionnel `dart:html` sur le web pour déclencher
  un téléchargement navigateur, `dart:io` + `path_provider` sur mobile/desktop pour
  enregistrer le fichier), sans dépendance tierce ajoutée.
- **Responsive** : `ResponsiveBuilder` (breakpoints mobile / tablette / desktop) bascule
  entre mise en page verticale (terrain puis formulaire) et mise en page à deux colonnes
  (terrain à gauche, formulaire à droite ; côté résultats, statistiques à gauche et carte
  d'impacts à droite).

## Ce qui est déjà fait (MVP + évolutions)

Accueil, création de série (élève, classe 2e1-2e5, mode d'analyse, zone(s) à travailler,
réceptionneurs), terrain interactif (zones 1-6 + Piscine + OUT + FILET, Piscine
sélectionnable partout), saisie des 10 services (ligne de fond mordue, type de service,
trajectoire "Tendu"/"Cloche", qualité du lancer de balle, qualité de réception en mode
avec réception), alerte visuelle rouge si un service tombe hors de la zone visée, bilan
présenté sous forme de statistiques simples (sans graphique) + carte des 10 impacts, suivi
d'une réflexion guidée où l'élève répond lui-même à une série de questions à l'aide de ces
statistiques avant de voir l'axe prioritaire généré par l'appli (sans exercices tout faits,
ça reste le rôle de l'enseignant), comparaison automatique avec la série précédente du même
élève, export CSV d'une série, historique local avec partage par classe (Supabase),
mode démonstration, responsive mobile / tablette / desktop / web, publication continue via
Netlify + Pull Request automatique pour chaque branche de travail.

## Prochaines étapes (non incluses dans ce lot)

- **Écran de comparaison dédié** : la comparaison existe déjà (badges +X % / +Y zones sur
  le bilan), mais un écran dédié pour comparer deux séries côte à côte reste à faire.
- **PWA avancée** : `web/manifest.json` par défaut de Flutter est fonctionnel ; mode
  hors-ligne (service worker personnalisé) reste à affiner.
- Renommer l'application : changer `VolleyStats EPS` dans `lib/main.dart` et
  `lib/screens/home_screen.dart` (le nom du package `volleystats_eps` dans `pubspec.yaml`
  peut rester tel quel, ou être changé avec l'outil `rename` si besoin d'un vrai rebrand).
