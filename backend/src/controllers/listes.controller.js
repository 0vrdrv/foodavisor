const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /api/listes → toutes les listes de l'utilisateur
// ----------------------------------------------------
async function list(req, res, next) {
  try {
    const [rows] = await db.query(
      `SELECT id, libelle, ts FROM liste_course WHERE utilisateur_id = ? ORDER BY ts DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// GET /api/listes/:liste_id → détail d'une liste
// ----------------------------------------------------
async function getById(req, res, next) {
  try {
    const { liste_id } = req.params;
    const utilisateur_id = req.user.id;

    const [liste] = await db.query(
      `SELECT id, libelle, ts FROM liste_course WHERE id = ? AND utilisateur_id = ?`,
      [liste_id, utilisateur_id]
    );
    if (liste.length === 0) return res.status(404).json({ message: "Liste introuvable" });

    const [items] = await db.query(
      `SELECT lci.ingredient_id, i.nom AS ingredient, lci.quantite, lci.unite_code
       FROM liste_course_item lci
       JOIN ingredient i ON i.id = lci.ingredient_id
       WHERE lci.liste_id = ?`,
      [liste_id]
    );

    res.json({
      ...liste[0],
      items
    });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// POST /api/listes → créer une liste (option : depuis recette)
// ----------------------------------------------------
async function create(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

  const utilisateur_id = req.user.id;
  const { libelle, recette_id } = req.body;

  try {
    await db.query("START TRANSACTION");

    const [result] = await db.query(
      `INSERT INTO liste_course (utilisateur_id, libelle) VALUES (?, ?)`,
      [utilisateur_id, libelle]
    );
    const liste_id = result.insertId;

    // Si on veut générer depuis une recette
    if (recette_id) {
      const [ingredients] = await db.query(
        `SELECT ingredient_id, quantite, unite_code FROM recette_ingredient WHERE recette_id = ?`,
        [recette_id]
      );

      for (const ing of ingredients) {
        await db.query(
          `INSERT INTO liste_course_item (liste_id, ingredient_id, quantite, unite_code)
           VALUES (?, ?, ?, ?)`,
          [liste_id, ing.ingredient_id, ing.quantite, ing.unite_code]
        );
      }
    }

    await db.query("COMMIT");
    res.status(201).json({ message: "Liste créée", id: liste_id });
  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
}

// ----------------------------------------------------
// POST /api/listes/:liste_id/item → ajouter un ingrédient
// ----------------------------------------------------
async function addItem(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

  const { liste_id } = req.params;
  const utilisateur_id = req.user.id;
  const { ingredient_id, quantite, unite_code } = req.body;

  try {
    // Vérifie que la liste appartient à l'utilisateur
    const [liste] = await db.query(
      `SELECT id FROM liste_course WHERE id = ? AND utilisateur_id = ?`,
      [liste_id, utilisateur_id]
    );
    if (liste.length === 0) return res.status(403).json({ message: "Accès refusé" });

    await db.query(
      `INSERT INTO liste_course_item (liste_id, ingredient_id, quantite, unite_code)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE quantite = quantite + VALUES(quantite)`,
      [liste_id, ingredient_id, quantite, unite_code]
    );

    res.status(201).json({ message: "Ingrédient ajouté à la liste" });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// DELETE /api/listes/:liste_id/item/:ingredient_id
// ----------------------------------------------------
async function removeItem(req, res, next) {
  try {
    const { liste_id, ingredient_id } = req.params;
    const utilisateur_id = req.user.id;

    // Vérifie la propriété
    const [check] = await db.query(
      `SELECT id FROM liste_course WHERE id = ? AND utilisateur_id = ?`,
      [liste_id, utilisateur_id]
    );
    if (check.length === 0) return res.status(403).json({ message: "Accès refusé" });

    const [result] = await db.query(
      `DELETE FROM liste_course_item WHERE liste_id = ? AND ingredient_id = ?`,
      [liste_id, ingredient_id]
    );

    if (result.affectedRows === 0) return res.status(404).json({ message: "Élément introuvable" });

    res.json({ message: "Ingrédient supprimé de la liste" });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// DELETE /api/listes/:liste_id → supprimer une liste complète
// ----------------------------------------------------
async function removeList(req, res, next) {
  try {
    const { liste_id } = req.params;
    const utilisateur_id = req.user.id;

    const [result] = await db.query(
      `DELETE FROM liste_course WHERE id = ? AND utilisateur_id = ?`,
      [liste_id, utilisateur_id]
    );

    if (result.affectedRows === 0) return res.status(404).json({ message: "Liste introuvable" });

    res.json({ message: "Liste supprimée" });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  getById,
  create,
  addItem,
  removeItem,
  removeList,
};
