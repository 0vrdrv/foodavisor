const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /avis/recette/:recette_id
// ----------------------------------------------------
async function listForRecipe(req, res, next) {
  try {
    const recette_id = req.params.recette_id;

    // Récupérer les avis avec l'auteur
    const [rows] = await db.query(
      `
      SELECT a.id, a.note, a.utilisateur_id,a.commentaire, a.ts, 
             u.nom, u.prenom
      FROM avis a
      JOIN utilisateur u ON u.id = a.utilisateur_id
      WHERE a.recette_id = ?
      ORDER BY a.ts DESC
    `,
      [recette_id]
    );

    // Calculer la moyenne
    const [avg] = await db.query(
      `SELECT AVG(note) AS moyenne, COUNT(*) AS nb_avis FROM avis WHERE recette_id = ?`,
      [recette_id]
    );

    res.json({
      recette_id,
      moyenne: avg[0].moyenne !== null ? Number(parseFloat(avg[0].moyenne).toFixed(2)) : null,
      nb_avis: avg[0].nb_avis,
      avis: rows
    });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// POST /avis/recette/:recette_id
// ----------------------------------------------------
async function create(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const utilisateur_id = req.user.id;
  const recette_id = req.params.recette_id;
  const { note, commentaire } = req.body;

  try {
    // Vérifier s’il existe déjà un avis pour ce user sur cette recette
    const [exist] = await db.query(
      "SELECT id FROM avis WHERE utilisateur_id = ? AND recette_id = ?",
      [utilisateur_id, recette_id]
    );

    if (exist.length > 0) {
      return res.status(400).json({ message: "Avis déjà existant pour cette recette" });
    }

    await db.query(
      `INSERT INTO avis (utilisateur_id, recette_id, note, commentaire)
       VALUES (?, ?, ?, ?)`,
      [utilisateur_id, recette_id, note, commentaire || null]
    );

    res.status(201).json({ message: "Avis ajouté" });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// PUT /avis/recette/:recette_id
// ----------------------------------------------------
async function update(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const utilisateur_id = req.user.id;
  const recette_id = req.params.recette_id;
  const { note, commentaire } = req.body;

  try {
    const [result] = await db.query(
      `
      UPDATE avis
      SET note = COALESCE(?, note),
          commentaire = COALESCE(?, commentaire),
          ts = CURRENT_TIMESTAMP
      WHERE utilisateur_id = ? AND recette_id = ?
    `,
      [note, commentaire, utilisateur_id, recette_id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Aucun avis trouvé à modifier" });
    }

    res.json({ message: "Avis mis à jour" });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// DELETE /api/avis/recette/:recette_id
// ----------------------------------------------------
async function remove(req, res, next) {
  const utilisateur_id = req.user.id;
  const recette_id = req.params.recette_id;

  try {
    const [result] = await db.query(
      `DELETE FROM avis WHERE utilisateur_id = ? AND recette_id = ?`,
      [utilisateur_id, recette_id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Avis introuvable" });
    }

    res.json({ message: "Avis supprimé" });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listForRecipe,
  create,
  update,
  remove,
};
