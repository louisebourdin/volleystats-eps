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
  prend 2 à 4 minutes.
- Pour vérifier qu'un déploiement a réussi : dashboard Netlify du projet → onglet
  "Deploys" → dernier déploiement → logs.

**Workflow pour modifier l'app depuis n'importe quelle session Claude Code** (y compris
depuis un autre appareil) :

1. `git clone https://github.com/louisebourdin/volleystats-eps.git`
2. Faire les modifications, tester localement (`flutter analyze`, `flutter test`,
   `flutter run -d chrome`)
3. `git add -A && git commit -m "..." && git push`
4. Le site public se met à jour tout seul en 1-4 minutes.

## Utilisation rapide

Depuis l'accueil : **Nouvelle série** → renseigner l'élève → toucher le terrain après
chaque service → **Enregistrer le service** → bilan automatique après le 10e service.
Le bouton **Charger une démonstration** remplit deux séries fictives (élève "Alex") pour
présenter l'application sans taper 10 services réels.

## Architecture

```
lib/
  main.dart                 point d'entrée, initialise Hive puis Riverpod
  theme/                     couleurs et thème Material 3
  models/                    Student, Session, Serve, ServeDraft, ServeAnalysis, Recommendation
  services/                  StorageService (Hive), StatisticsService, RecommendationEngine, DemoDataService
  providers/                 sessionProvider (série en cours), historyProvider (séries sauvegardées)
  screens/                   home, new_session, serve, results, history, help
  widgets/
    court/                   terrain interactif (CustomPainter + GestureDetector), géométrie partagée
    serve_form.dart          formulaire rapide d'un service
    result_charts.dart       graphiques (fl_chart)
    statistic_card.dart, recommendation_card.dart, serve_progress_indicator.dart, confirm_dialog.dart
  utils/                     responsive breakpoints, génération d'id, formatage de date FR
```

- **State management** : Riverpod (`StateNotifierProvider`). La série en cours reste
  disponible pendant toute la navigation tant qu'elle n'est pas explicitement quittée.
- **Stockage** : Hive en local (`StorageService`), avec des modèles qui se sérialisent
  eux-mêmes en `Map` (`toJson`/`fromJson`). Remplacer `StorageService` par une
  implémentation Firebase/Supabase/API ne demande de toucher qu'à ce seul fichier — les
  écrans et providers n'en dépendent qu'à travers son interface.
- **Terrain interactif** : `CourtGeometry` définit une seule fois la géométrie des zones
  (fractions 0..1 de la largeur/hauteur), utilisée à la fois par le `CustomPainter` et par
  le détecteur de gestes. Les impacts sont stockés en coordonnées normalisées : la carte
  reste juste quelle que soit la taille d'écran.
- **Responsive** : `ResponsiveBuilder` (breakpoints mobile / tablette / desktop) bascule
  entre mise en page verticale (terrain puis formulaire) et mise en page à deux colonnes
  (terrain à gauche, formulaire à droite ; côté résultats, statistiques à gauche et carte
  d'impacts à droite).

## Ce qui est déjà fait (MVP, §33 du cahier des charges)

Accueil, création de série, terrain interactif (zones 1-6 + Piscine + OUT + FILET),
saisie des 10 services (résultat, zone, ligne mordue, type de service, trajectoire,
caractéristiques facultatives), bilan (régularité, précision, variété, trajectoire, carte
des 10 impacts), moteur de conseils à règles, comparaison automatique avec la série
précédente du même élève, historique local, mode démonstration, responsive mobile /
tablette / desktop / web.

## Prochaines étapes (non incluses dans ce premier lot)

- **Mode professeur** : vue d'ensemble multi-élèves/multi-classes (bouton déjà présent à
  l'accueil, affiche pour l'instant un message "bientôt disponible").
- **Écran de comparaison dédié** : la comparaison existe déjà (badges +X % / +Y zones sur
  le bilan), mais un écran dédié pour comparer deux séries côte à côte reste à faire.
- **Synchronisation cloud** (Firebase/Supabase/API) : l'architecture (`StorageService`,
  modèles `toJson`/`fromJson`) est prête pour ça, l'implémentation reste à brancher.
- **PWA avancée** : `web/manifest.json` par défaut de Flutter est fonctionnel ; icônes
  dédiées, mode hors-ligne (service worker personnalisé) restent à affiner.
- Renommer l'application : changer `VolleyStats EPS` dans `lib/main.dart` et
  `lib/screens/home_screen.dart` (le nom du package `volleystats_eps` dans `pubspec.yaml`
  peut rester tel quel, ou être changé avec l'outil `rename` si besoin d'un vrai rebrand).
