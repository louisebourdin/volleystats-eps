/**
 * VolleyStats EPS — reçoit les services d'une série envoyés par le bouton
 * "Envoyer vers Google Sheets" de l'appli, et les ajoute en bas de la feuille.
 *
 * Installation :
 * 1. Ouvre ton Google Sheets > Extensions > Apps Script.
 * 2. Efface TOUT le code par défaut (y compris "function myFunction() { }"),
 *    puis colle tout le contenu de ce fichier et enregistre (Ctrl+S). Si le
 *    code est collé à l'intérieur de myFunction, Google répond
 *    "Fonction de script introuvable : doPost".
 * 3. En haut de la feuille (ligne 1), renseigne les en-têtes exactement dans
 *    cet ordre (voir aussi le README du projet). Une seule ligne est ajoutée
 *    par série envoyée (résumé, pas le détail service par service — pour ça
 *    il y a l'export CSV) :
 *    Date | Classe | Eleve | Nombre de services | Objectif (zones) | Mode
 *    | Trajectoire dominante | Mordus | Services dans la zone visee
 *    | Ace ou bonne reception
 *
 *    Les colonnes "Mordus" (8) et "Ace ou bonne reception" (10) sont
 *    coloriées automatiquement à l'insertion (voir _mordusColor et
 *    _receptionColor ci-dessous).
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

// Position (1-indexée) des colonnes coloriées, selon l'ordre envoyé par l'appli.
var MORDUS_COLUMN = 8;
var RECEPTION_COLUMN = 10;

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

    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    var startRow = sheet.getLastRow() + 1;
    var range = sheet.getRange(startRow, 1, rows.length, rows[0].length);
    // Texte brut : sinon Sheets convertit "2e2" (classe) en 200, notation scientifique.
    range.setNumberFormat('@');
    range.setValues(rows);

    for (var i = 0; i < rows.length; i++) {
      var rowNum = startRow + i;
      var mordusColor = _mordusColor(rows[i][MORDUS_COLUMN - 1]);
      if (mordusColor) sheet.getRange(rowNum, MORDUS_COLUMN).setBackground(mordusColor);
      var receptionColor = _receptionColor(rows[i][RECEPTION_COLUMN - 1]);
      if (receptionColor) sheet.getRange(rowNum, RECEPTION_COLUMN).setBackground(receptionColor);
    }

    return _jsonResponse({status: 'ok', inserted: rows.length});
  } catch (err) {
    return _jsonResponse({status: 'error', message: err.message || String(err)});
  }
}

// "3 / 10" -> plus de la moitié de mordus = rouge, exactement la moitié =
// orange, moins de la moitié = vert. Valeur non reconnue -> pas de couleur.
function _mordusColor(text) {
  var m = /^(\d+)\s*\/\s*(\d+)$/.exec(String(text || ''));
  if (!m) return null;
  var faults = parseInt(m[1], 10);
  var total = parseInt(m[2], 10);
  if (total === 0) return null;
  var ratio = faults / total;
  if (ratio > 0.5) return COLOR_RED;
  if (ratio === 0.5) return COLOR_ORANGE;
  return COLOR_GREEN;
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
