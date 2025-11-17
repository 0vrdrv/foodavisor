const { validationResult } = require("express-validator");
const db = require("../config/db");

// --------------------------------------------------
// Helpers
// --------------------------------------------------
function handleValidation(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(422).json({ errors: errors.array() });
    return false;
  }
  return true;
}

// --------------------------------------------------
// GET /preferences  → tout d'un coup
// --------------------------------------------------
exports.getAllPreferences = async (req, res, next) => {
  const userId = req.user.id;

  try {
    const [[user]] = await db.query(
      `SELECT ville, date_naissance, sexe
       FROM utilisateur
       WHERE id = ?`,
      [userId]
    );

    const [allergies] = await db.query(
      `SELECT a.id, a.libelle
       FROM utilisateur_allergie ua
       JOIN allergene a ON a.id = ua.allergene_id
       WHERE ua.utilisateur_id = ?
       ORDER BY a.libelle`,
      [userId]
    );

    const [regimes] = await db.query(
      `SELECT r.id, r.code, r.libelle
       FROM utilisateur_regime ur
       JOIN regime r ON r.id = ur.regime_id
       WHERE ur.utilisateur_id = ?
       ORDER BY r.libelle`,
      [userId]
    );

    const [exclusions] = await db.query(
      `SELECT i.id, i.nom
       FROM utilisateur_aliment_exclu ue
       JOIN ingredient i ON i.id = ue.ingredient_id
       WHERE ue.utilisateur_id = ?
       ORDER BY i.nom`,
      [userId]
    );

    const [favoris] = await db.query(
      `SELECT r.id, r.titre
       FROM utilisateur_favori uf
       JOIN recette r ON r.id = uf.recette_id
       WHERE uf.utilisateur_id = ?
       ORDER BY r.titre`,
      [userId]
    );

    res.json({
      general: user || { ville: null, date_naissance: null, sexe: null },
      allergies,
      regimes,
      aliments_exclus: exclusions,
      favoris,
    });
  } catch (err) {
    next(err);
  }
};

// --------------------------------------------------
// General
// --------------------------------------------------
exports.getGeneral = async (req, res, next) => {
  const userId = req.user.id;

  try {
    const [[user]] = await db.query(
      `SELECT ville, date_naissance, sexe
       FROM utilisateur
       WHERE id = ?`,
      [userId]
    );

    res.json(user || { ville: null, date_naissance: null, sexe: null });
  } catch (err) {
    next(err);
  }
};

exports.updateGeneral = async (req, res, next) => {
  if (!handleValidation(req, res)) return;
  const userId = req.user.id;
  const { ville, date_naissance, sexe } = req.body;

  try {
    await db.query(
      `UPDATE utilisateur
       SET ville = COALESCE(?, ville),
           date_naissance = COALESCE(?, date_naissance),
           sexe = COALESCE(?, sexe)
       WHERE id = ?`,
      [ville, date_naissance, sexe, userId]
    );

    res.json({ message: "Informations générales mises à jour." });
  } catch (err) {
    next(err);
  }
};

// --------------------------------------------------
// Allergies
// --------------------------------------------------
exports.getAllergies = async (req, res, next) => {
  const userId = req.user.id;

  try {
    const [rows] = await db.query(
      `SELECT a.id, a.libelle
       FROM utilisateur_allergie ua
       JOIN allergene a ON a.id = ua.allergene_id
       WHERE ua.utilisateur_id = ?
       ORDER BY a.libelle`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
};

exports.addAllergie = async (req, res, next) => {
  if (!handleValidation(req, res)) return;
  const userId = req.user.id;
  const { allergene_id } = req.body;

  try {
    await db.query(
      `INSERT IGNORE INTO utilisateur_allergie (utilisateur_id, allergene_id)
       VALUES (?, ?)`,
      [userId, allergene_id]
    );
    res.json({ message: "Allergie ajoutée." });
  } catch (err) {
    next(err);
  }
};

exports.removeAllergie = async (req, res, next) => {
  const userId = req.user.id;
  const { allergene_id } = req.params;

  try {
    await db.query(
      `DELETE FROM utilisateur_allergie
       WHERE utilisateur_id = ? AND allergene_id = ?`,
      [userId, allergene_id]
    );
    res.json({ message: "Allergie supprimée." });
  } catch (err) {
    next(err);
  }
};

// --------------------------------------------------
// Régimes
// --------------------------------------------------
exports.getRegimes = async (req, res, next) => {
  const userId = req.user.id;

  try {
    const [rows] = await db.query(
      `SELECT r.id, r.code, r.libelle
       FROM utilisateur_regime ur
       JOIN regime r ON r.id = ur.regime_id
       WHERE ur.utilisateur_id = ?
       ORDER BY r.libelle`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
};

exports.addRegime = async (req, res, next) => {
  if (!handleValidation(req, res)) return;
  const userId = req.user.id;
  const { regime_id } = req.body;

  try {
    await db.query(
      `INSERT IGNORE INTO utilisateur_regime (utilisateur_id, regime_id)
       VALUES (?, ?)`,
      [userId, regime_id]
    );
    res.json({ message: "Régime ajouté." });
  } catch (err) {
    next(err);
  }
};

exports.removeRegime = async (req, res, next) => {
  const userId = req.user.id;
  const { regime_id } = req.params;

  try {
    await db.query(
      `DELETE FROM utilisateur_regime
       WHERE utilisateur_id = ? AND regime_id = ?`,
      [userId, regime_id]
    );
    res.json({ message: "Régime supprimé." });
  } catch (err) {
    next(err);
  }
};

// --------------------------------------------------
// Aliments exclus
// --------------------------------------------------
exports.getExclusions = async (req, res, next) => {
  const userId = req.user.id;

  try {
    const [rows] = await db.query(
      `SELECT i.id, i.nom
       FROM utilisateur_aliment_exclu ue
       JOIN ingredient i ON i.id = ue.ingredient_id
       WHERE ue.utilisateur_id = ?
       ORDER BY i.nom`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
};

exports.addExclusion = async (req, res, next) => {
  if (!handleValidation(req, res)) return;
  const userId = req.user.id;
  const { ingredient_id } = req.body;

  try {
    await db.query(
      `INSERT IGNORE INTO utilisateur_aliment_exclu (utilisateur_id, ingredient_id)
       VALUES (?, ?)`,
      [userId, ingredient_id]
    );
    res.json({ message: "Aliment exclu ajouté." });
  } catch (err) {
    next(err);
  }
};

exports.removeExclusion = async (req, res, next) => {
  const userId = req.user.id;
  const { ingredient_id } = req.params;

  try {
    await db.query(
      `DELETE FROM utilisateur_aliment_exclu
       WHERE utilisateur_id = ? AND ingredient_id = ?`,
      [userId, ingredient_id]
    );
    res.json({ message: "Aliment exclu supprimé." });
  } catch (err) {
    next(err);
  }
};

// --------------------------------------------------
// Favoris
// --------------------------------------------------
exports.getFavoris = async (req, res, next) => {
  const userId = req.user.id;

  try {
    const [rows] = await db.query(
      `SELECT r.id, r.titre
       FROM utilisateur_favori uf
       JOIN recette r ON r.id = uf.recette_id
       WHERE uf.utilisateur_id = ?
       ORDER BY r.titre`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
};

exports.addFavori = async (req, res, next) => {
  if (!handleValidation(req, res)) return;
  const userId = req.user.id;
  const { recette_id } = req.body;

  try {
    await db.query(
      `INSERT IGNORE INTO utilisateur_favori (utilisateur_id, recette_id)
       VALUES (?, ?)`,
      [userId, recette_id]
    );
    res.json({ message: "Recette ajoutée aux favoris." });
  } catch (err) {
    next(err);
  }
};

exports.removeFavori = async (req, res, next) => {
  const userId = req.user.id;
  const { recette_id } = req.params;

  try {
    await db.query(
      `DELETE FROM utilisateur_favori
       WHERE utilisateur_id = ? AND recette_id = ?`,
      [userId, recette_id]
    );
    res.json({ message: "Recette retirée des favoris." });
  } catch (err) {
    next(err);
  }
};

exports.updateAllPreferences = async (req, res, next) => {
  const userId = req.user.id;
  const { allergies = [], exclus = [], favoris = [] } = req.body;

  try {
    await db.query("START TRANSACTION");

    await db.query(
      `DELETE FROM utilisateur_allergie WHERE utilisateur_id = ?`,
      [userId]
    );
    for (const id of allergies) {
      await db.query(
        `INSERT INTO utilisateur_allergie (utilisateur_id, allergene_id)
         VALUES (?, ?)`,
        [userId, id]
      );
    }

    await db.query(
      `DELETE FROM utilisateur_aliment_exclu WHERE utilisateur_id = ?`,
      [userId]
    );
    for (const id of exclus) {
      await db.query(
        `INSERT INTO utilisateur_aliment_exclu (utilisateur_id, ingredient_id)
         VALUES (?, ?)`,
        [userId, id]
      );
    }

    await db.query(`DELETE FROM utilisateur_favori WHERE utilisateur_id = ?`, [
      userId,
    ]);
    for (const id of favoris) {
      await db.query(
        `INSERT INTO utilisateur_favori (utilisateur_id, recette_id)
         VALUES (?, ?)`,
        [userId, id]
      );
    }

    await db.query("COMMIT");
    res.json({ message: "Préférences mises à jour" });
  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
};
