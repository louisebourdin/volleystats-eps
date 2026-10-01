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
 *    cet ordre (voir aussi le README du projet) :
 *    Eleve | Classe | Date | Mode | Numero | Resultat | Zone | Type de service
 *    | Trajectoire | Ligne de fond mordue | Qualite du lancer | Qualite de la reception
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

    return _jsonResponse({status: 'ok', inserted: rows.length});
  } catch (err) {
    return _jsonResponse({status: 'error', message: err.message || String(err)});
  }
}

function _jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
