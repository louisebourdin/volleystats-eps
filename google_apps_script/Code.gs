/**
 * VolleyStats EPS — reçoit les services d'une série envoyés par le bouton
 * "Envoyer vers Google Sheets" de l'appli, et les ajoute en bas de l'onglet
 * correspondant à la classe de l'élève (un onglet par classe, créé
 * automatiquement au premier envoi avec les bons en-têtes).
 *
 * Installation :
 * 1. Ouvre ton Google Sheets > Extensions > Apps Script.
 * 2. Efface TOUT le code par défaut (y compris "function myFunction() { }"),
 *    puis colle tout le contenu de ce fichier et enregistre (Ctrl+S). Si le
 *    code est collé à l'intérieur de myFunction, Google répond
 *    "Fonction de script introuvable : doPost".
 * 3. Pas besoin de préparer d'en-têtes à la main : le script crée un onglet
 *    "2nde <n>" à la volée pour chaque classe qui envoie une série, avec la
 *    ligne d'en-tête déjà remplie (voir COLUMN_HEADERS ci-dessous, même
 *    ordre que le README du projet). Une seule ligne est ajoutée par série
 *    envoyée (résumé, pas le détail service par service — pour ça il y a
 *    l'export CSV) :
 *    Date | Classe | Eleve | Nombre de services | Objectif (zones) | Mode
 *    | Trajectoire dominante | Mordus | Services dans la zone visee
 *    | Ace ou bonne reception
 *
 *    Les colonnes "Mordus" (8), "Services dans la zone visee" (9) et "Ace
 *    ou bonne reception" (10) sont coloriées automatiquement à l'insertion
 *    (voir _mordusColor, _zoneColor et _receptionColor ci-dessous).
 * 4. Déployer > Nouveau déploiement > type "Application Web".
 *    - Exécuter en tant que : Moi
 *    - Qui a accès : Tous les utilisateurs
 * 5. Autorise l'accès quand Google le demande, puis copie l'URL fournie
 *    (se termine par /exec) dans l'appli, écran "Bilan de la série" >
 *    icône réglages à côté de "Envoyer vers Google Sheets".
 *
 * Si tu modifies ce script après un premier déploiement, utilise
 * Déployer > Gérer les déploiements > icône crayon > Nouvelle version,
 * sinon l'URL continuera d'exécuter l'ancienne version du code.
 */

var COLUMN_HEADERS = [
  'Date', 'Classe', 'Eleve', 'Nombre de services', 'Objectif (zones)', 'Mode',
  'Trajectoire dominante', 'Mordus', 'Services dans la zone visee', 'Ace ou bonne reception',
];

// Position (1-indexée) des colonnes utilisées pour router et colorier, selon
// l'ordre envoyé par l'appli (voir COLUMN_HEADERS).
var CLASS_COLUMN = 2;
var MORDUS_COLUMN = 8;
var ZONE_COLUMN = 9;
var RECEPTION_COLUMN = 10;

// À partir de combien de fautes de pied la colonne Mordus passe en rouge.
var MORDUS_ALERT_THRESHOLD = 2;

var COLOR_RED = '#F4CCCC';
var COLOR_ORANGE = '#FCE5CD';
var COLOR_GREEN = '#D9EAD3';

function doPost(e) {
  try {
    var payload = JSON.parse(e.postData.contents);
    var rows = payload.rows;

    if (!rows || rows.length === 0) {
      return _jsonResponse({status: 'ok', inserted: 0});
    }

    var spreadsheet = SpreadsheetApp.getActiveSpreadsheet();

    for (var i = 0; i < rows.length; i++) {
      var row = rows[i];
      var sheet = _sheetForClass(spreadsheet, row[CLASS_COLUMN - 1]);
      var rowNum = sheet.getLastRow() + 1;
      var range = sheet.getRange(rowNum, 1, 1, row.length);
      // Texte brut : sinon Sheets convertit "2e2" (classe) en 200, notation scientifique.
      range.setNumberFormat('@');
      range.setValues([row]);

      var mordusColor = _mordusColor(row[MORDUS_COLUMN - 1]);
      if (mordusColor) sheet.getRange(rowNum, MORDUS_COLUMN).setBackground(mordusColor);
      var zoneColor = _zoneColor(row[ZONE_COLUMN - 1]);
      if (zoneColor) sheet.getRange(rowNum, ZONE_COLUMN).setBackground(zoneColor);
      var receptionColor = _receptionColor(row[RECEPTION_COLUMN - 1]);
      if (receptionColor) sheet.getRange(rowNum, RECEPTION_COLUMN).setBackground(receptionColor);
    }

    return _jsonResponse({status: 'ok', inserted: rows.length});
  } catch (err) {
    return _jsonResponse({status: 'error', message: err.message || String(err)});
  }
}

// Renvoie l'onglet "2nde <classNumber>", en le créant (avec les en-têtes)
// s'il n'existe pas encore.
function _sheetForClass(spreadsheet, classNumber) {
  var name = '2nde ' + classNumber;
  var sheet = spreadsheet.getSheetByName(name);
  if (!sheet) {
    sheet = spreadsheet.insertSheet(name);
    var headerRange = sheet.getRange(1, 1, 1, COLUMN_HEADERS.length);
    headerRange.setValues([COLUMN_HEADERS]);
    headerRange.setFontWeight('bold');
  }
  return sheet;
}

// "3 / 10" -> rouge dès MORDUS_ALERT_THRESHOLD fautes de pied ou plus dans
// la série, vert en dessous. Valeur non reconnue -> pas de couleur.
function _mordusColor(text) {
  var m = /^(\d+)\s*\/\s*(\d+)$/.exec(String(text || ''));
  if (!m) return null;
  var faults = parseInt(m[1], 10);
  return faults >= MORDUS_ALERT_THRESHOLD ? COLOR_RED : COLOR_GREEN;
}

// "8 / 10" -> plus de la moitié de la série dans la zone visée = vert,
// exactement la moitié = orange, moins de la moitié = rouge.
function _zoneColor(text) {
  var m = /^(\d+)\s*\/\s*(\d+)$/.exec(String(text || ''));
  if (!m) return null;
  var hits = parseInt(m[1], 10);
  var total = parseInt(m[2], 10);
  if (total === 0) return null;
  var ratio = hits / total;
  if (ratio > 0.5) return COLOR_GREEN;
  if (ratio === 0.5) return COLOR_ORANGE;
  return COLOR_RED;
}

// "2 Ace / 1 Bonne réception" -> plus d'ace que de bonne réception = vert,
// autant des deux = orange, plus de bonne réception que d'ace = rouge.
// Case vide (mode sans réception) -> pas de couleur.
function _receptionColor(text) {
  var m = /^(\d+)\s*Ace\s*\/\s*(\d+)\s*Bonne/.exec(String(text || ''));
  if (!m) return null;
  var ace = parseInt(m[1], 10);
  var bonne = parseInt(m[2], 10);
  if (ace > bonne) return COLOR_GREEN;
  if (ace === bonne) return COLOR_ORANGE;
  return COLOR_RED;
}

function _jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
