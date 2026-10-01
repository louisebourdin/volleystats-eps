/**
 * VolleyStats EPS — reçoit les services d'une série envoyés par le bouton
 * "Envoyer vers Google Sheets" de l'appli, et les ajoute en bas de la feuille.
 *
 * Installation :
 * 1. Ouvre ton Google Sheets > Extensions > Apps Script.
 * 2. Colle tout le contenu de ce fichier (remplace le code par défaut).
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
    sheet.getRange(startRow, 1, rows.length, rows[0].length).setValues(rows);

    return _jsonResponse({status: 'ok', inserted: rows.length});
  } catch (err) {
    return _jsonResponse({status: 'error', message: err.message || String(err)});
  }
}

function _jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
