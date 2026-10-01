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

L'appli est publiée à deux adresses, toutes deux reliées à ce dépôt GitHub et mises à
jour à chaque `git push` sur `main` :

| Hébergeur | Adresse | Rôle |
|---|---|---|
| **Cloudflare Workers** | https://volleystats-eps.louisebourdin8.workers.dev | **Adresse principale** (à donner aux élèves) — toujours à jour |
| Netlify | https://moonlit-youtiao-44fcd5.netlify.app | Copie de secours — peut avoir du retard (voir quotas ci-dessous) |

Un déploiement prend 2 à 4 minutes : aucun des deux n'a Flutter préinstallé,
`scripts/build_web.sh` clone le SDK Flutter stable puis lance
`flutter build web --release` (sortie dans `build/web`).

### Cloudflare (Worker avec ressources statiques)

C'est un **Worker** Cloudflare (pas un projet "Pages") nommé `volleystats-eps`, compte
louisebourdin8, relié au dépôt via Workers Builds. Réglages (dashboard Cloudflare →
Workers & Pages → `volleystats-eps` → Paramètres → Builds) :

- Commande de build : `bash scripts/build_web.sh`
- Commande de déploiement : `npx wrangler deploy`
- Répertoire racine : `/`
- Branche de production : `main`

`wrangler.jsonc` (à la racine du dépôt) indique à `wrangler deploy` de servir le contenu
de `build/web` comme site statique — sans ce fichier, le déploiement "réussit" mais la
page est blanche (rien à servir). Pour vérifier un déploiement : onglet "Déploiements"
du Worker → dernier déploiement → logs.

Pour le recréer depuis zéro : https://dash.cloudflare.com → Workers & Pages → Créer →
Importer un dépôt Git → `louisebourdin/volleystats-eps` → renseigner les réglages
ci-dessus.

### Netlify (quota de crédits)

Le compte Netlify (équipe louisebourdin8, plan gratuit) fonctionne par **crédits
mensuels** ; chaque déploiement de production en consomme. Période de facturation : du
16 au 15 du mois suivant. Quand le quota est épuisé, Netlify **met en pause les
déploiements de production** : le site reste en ligne mais figé sur l'ancienne version
(les nouveaux push sont marqués "Skipped due to account credit usage exceeded").

- C'est arrivé le 1er octobre 2026 (25 builds en septembre, une dizaine en deux jours) :
  Netlify est resté sur `49a3d3e`.
- Après la remise à zéro des crédits (le 16), aller dans Netlify → le projet → Deploys
  → **Trigger deploy** pour republier la dernière version de `main` d'un coup.
- Pour économiser les crédits : **fusionner dans `main` par lots** (une fusion = un
  déploiement), pas après chaque petite modification.

**Workflow pour modifier l'app depuis n'importe quelle session Claude Code** (y compris
depuis un autre appareil) :

1. `git clone https://github.com/louisebourdin/volleystats-eps.git`
2. Faire les modifications, tester localement (`flutter analyze`, `flutter test`,
   `flutter run -d chrome`)
3. `git add -A && git commit -m "..." && git push` sur une branche `claude/...`
4. `.github/workflows/open-pr-claude.yml` ouvre automatiquement une Pull Request vers
   `main` dès que cette branche est poussée sur GitHub — il suffit de cliquer
   "Merge" pour publier.
5. Les sites publics (Cloudflare et Netlify) se mettent à jour tout seuls en 2-4 minutes
   après le merge sur `main`. Regrouper les modifications avant de fusionner pour ne pas
   épuiser les crédits Netlify.

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

## Export vers Google Sheets

Depuis le bilan d'une série, le bouton **"Envoyer vers Google Sheets"** ajoute les 10
services en bas d'un tableur, via un Web App Apps Script (`google_apps_script/Code.gs`).
L'URL du Web App se configure une fois dans l'appli (icône réglages à côté du bouton,
champ sauvegardé en local sur l'appareil) — voir les instructions d'installation en tête
de `Code.gs`. Les colonnes envoyées (en-tête à renseigner sur la ligne 1 du tableur, même
ordre que l'export CSV) :

```
Eleve | Classe | Date | Mode | Numero | Resultat | Zone | Type de service
| Trajectoire | Ligne de fond mordue | Qualite du lancer | Qualite de la reception
```

## Utilisation rapide

Depuis l'accueil : **Nouvelle série** → renseigner l'élève → choisir le **mode
d'analyse** (voir ci-dessous) → toucher le terrain après chaque service → bilan
automatique après le 10e service. Le bouton **Charger une démonstration** remplit deux
séries fictives (élève "Alex") pour présenter l'application sans taper 10 services réels.

### Deux modes d'analyse

- **Sans réception** (par défaut) : analyse classique du service seul (résultat, zone,
  régularité, précision, variété).
- **Avec réception** : en plus, pour chaque service réussi, on note la qualité de la
  réception adverse ("Bonne réception" si la balle repart haute vers le milieu de
  terrain, ou "Ace" si le point est direct ou la réception ratée). Le
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
élève, export CSV d'une série, export vers Google Sheets (Web App Apps Script), historique
local avec partage par classe (Supabase), mode démonstration, responsive mobile / tablette /
desktop / web, publication continue via Cloudflare Workers et Netlify + Pull Request automatique
pour chaque branche de travail.

## Prochaines étapes (non incluses dans ce lot)

- **Écran de comparaison dédié** : la comparaison existe déjà (badges +X % / +Y zones sur
  le bilan), mais un écran dédié pour comparer deux séries côte à côte reste à faire.
- **PWA avancée** : `web/manifest.json` par défaut de Flutter est fonctionnel ; mode
  hors-ligne (service worker personnalisé) reste à affiner.
- Renommer l'application : changer `VolleyStats EPS` dans `lib/main.dart` et
  `lib/screens/home_screen.dart` (le nom du package `volleystats_eps` dans `pubspec.yaml`
  peut rester tel quel, ou être changé avec l'outil `rename` si besoin d'un vrai rebrand).
