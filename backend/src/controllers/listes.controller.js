const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /listes  → listes de courses de l'utilisateur
// ----------------------------------------------------
async function list(req, res, next) {
  const userId = req.user.id;

  try {
    const [rows] = await db.query(`
      SELECT id, libelle, ts
      FROM liste_course
      WHERE utilisateur_id = ?
      ORDER BY ts DESC
    `, [userId]);

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// GET /listes/:liste_id  → détail + items
// ----------------------------------------------------
async function getById(req, res, next) {
  const userId = req.user.id;
  const listeId = req.params.liste_id;

  try {
    const [listes] = await db.query(`
      SELECT id, libelle, ts
      FROM liste_course
      WHERE id = ? AND utilisateur_id = ?
    `, [listeId, userId]);

    if (listes.length === 0)
      return res.status(404).json({ message: "Liste introuvable" });

    const [items] = await db.query(`
      SELECT
        lci.ingredient_id,
        i.nom AS ingredient,
        lci.quantite,
        lci.unite_code
      FROM liste_course_item lci
      JOIN ingredient i ON i.id = lci.ingredient_id
      WHERE lci.liste_id = ?
      ORDER BY i.nom ASC
    `, [listeId]);

    res.json({ ...listes[0], items });

  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// POST /listes
// body: { libelle?, recette_id? }
// ----------------------------------------------------
async function create(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty())
    return res.status(422).json({ errors: errors.array() });

  const userId = req.user.id;
  const { libelle, recette_id } = req.body;

  try {
    await db.query("START TRANSACTION");

    let titreListe = libelle || "Liste de courses";
    let listeId;

    // Avec génération automatique depuis une recette
    if (recette_id) {
      const [recetteRows] = await db.query(
        "SELECT titre FROM recette WHERE id = ?", [recette_id]
      );

      if (recetteRows.length === 0) {
        await db.query("ROLLBACK");
        return res.status(404).json({ message: "Recette introuvable" });
      }

      titreListe = libelle || `Courses pour ${recetteRows[0].titre}`;

      const [result] = await db.query(`
        INSERT INTO liste_course (utilisateur_id, libelle)
        VALUES (?, ?)
      `, [userId, titreListe]);

      listeId = result.insertId;

      // Ingrédients de la recette
      const [ingredients] = await db.query(`
        SELECT ingredient_id, quantite, unite_code
        FROM recette_ingredient
        WHERE recette_id = ?
      `, [recette_id]);

      for (const ing of ingredients) {
        const [stockRows] = await db.query(`
          SELECT quantite
          FROM stock
          WHERE utilisateur_id = ? AND ingredient_id = ?
        `, [userId, ing.ingredient_id]);

        const stockQte = stockRows.length ? Number(stockRows[0].quantite) : 0;
        const missing = Math.max(0, Number(ing.quantite) - stockQte);

        if (missing > 0) {
          await db.query(`
            INSERT INTO liste_course_item (liste_id, ingredient_id, quantite, unite_code)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE quantite = quantite + VALUES(quantite)
          `, [listeId, ing.ingredient_id, missing, ing.unite_code]);
        }
      }

    } else {
      // Simple liste vide
      const [result] = await db.query(`
        INSERT INTO liste_course (utilisateur_id, libelle)
        VALUES (?, ?)
      `, [userId, titreListe]);

      listeId = result.insertId;
    }

    await db.query("COMMIT");
    res.status(201).json({ id: listeId, libelle: titreListe });

  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
}

// ----------------------------------------------------
// POST /listes/:liste_id/items
// ----------------------------------------------------
async function addItem(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty())
    return res.status(422).json({ errors: errors.array() });

  const userId = req.user.id;
  const listeId = req.params.liste_id;
  const { ingredient_id, quantite, unite_code } = req.body;

  try {
    const [listes] = await db.query(`
      SELECT id FROM liste_course WHERE id = ? AND utilisateur_id = ?
    `, [listeId, userId]);

    if (listes.length === 0)
      return res.status(404).json({ message: "Liste introuvable" });

    await db.query(`
      INSERT INTO liste_course_item (liste_id, ingredient_id, quantite, unite_code)
      VALUES (?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE quantite = quantite + VALUES(quantite)
    `, [listeId, ingredient_id, quantite, unite_code]);

    res.status(201).json({ message: "Ingrédient ajouté" });

  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// PUT /listes/:liste_id/items/:ingredient_id
// ----------------------------------------------------
async function updateItem(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty())
    return res.status(422).json({ errors: errors.array() });

  const userId = req.user.id;
  const listeId = req.params.liste_id;
  const ingredientId = req.params.ingredient_id;
  const { quantite, unite_code } = req.body;

  try {
    const [listes] = await db.query(`
      SELECT id FROM liste_course WHERE id = ? AND utilisateur_id = ?
    `, [listeId, userId]);

    if (listes.length === 0)
      return res.status(404).json({ message: "Liste introuvable" });

    const [result] = await db.query(`
      UPDATE liste_course_item
      SET quantite = ?, unite_code = COALESCE(?, unite_code)
      WHERE liste_id = ? AND ingredient_id = ?
    `, [quantite, unite_code, listeId, ingredientId]);

    if (result.affectedRows === 0)
      return res.status(404).json({ message: "Ingrédient non présent" });

    res.json({ message: "Ingrédient mis à jour" });

  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// DELETE /listes/:liste_id/items/:ingredient_id
// ----------------------------------------------------
async function removeItem(req, res, next) {
  const userId = req.user.id;
  const listeId = req.params.liste_id;
  const ingredientId = req.params.ingredient_id;

  try {
    const [listes] = await db.query(`
      SELECT id FROM liste_course WHERE id = ? AND utilisateur_id = ?
    `, [listeId, userId]);

    if (listes.length === 0)
      return res.status(404).json({ message: "Liste introuvable" });

    await db.query(`
      DELETE FROM liste_course_item
      WHERE liste_id = ? AND ingredient_id = ?
    `, [listeId, ingredientId]);

    res.json({ message: "Ingrédient retiré" });

  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// DELETE /listes/:liste_id
// ----------------------------------------------------
async function remove(req, res, next) {
  const userId = req.user.id;
  const listeId = req.params.liste_id;

  try {
    const [result] = await db.query(`
      DELETE FROM liste_course WHERE id = ? AND utilisateur_id = ?
    `, [listeId, userId]);

    if (result.affectedRows === 0)
      return res.status(404).json({ message: "Liste introuvable" });

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
  updateItem,
  removeItem,
  remove,
};
