const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /api/recettes
// ----------------------------------------------------
async function list(req, res, next) {
  try {
    const [rows] = await db.query(`
      SELECT r.id, r.nom, r.description, r.difficulte, 
             r.temps_preparation, r.temps_cuisson, r.nb_personnes,
             COUNT(ri.ingredient_id) AS nb_ingredients,
             AVG(a.note) AS note_moyenne
      FROM recette r
      LEFT JOIN recette_ingredient ri ON ri.recette_id = r.id
      LEFT JOIN avis a ON a.recette_id = r.id
      GROUP BY r.id
      ORDER BY r.nom ASC
    `);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// GET /api/recettes/:id
// ----------------------------------------------------
async function getById(req, res, next) {
  try {
    const [rows] = await db.query(
      `SELECT * FROM recette WHERE id = ?`,
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "Recette introuvable" });
    }

    const recette = rows[0];

    // Ingrédients associés
    const [ingredients] = await db.query(
      `
      SELECT i.id, i.nom, ri.quantite, u.libelle AS unite
      FROM recette_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      LEFT JOIN unite u ON u.code = i.unite_code
      WHERE ri.recette_id = ?
    `,
      [req.params.id]
    );

    // Étapes
    const [etapes] = await db.query(
      `
      SELECT id, numero, description
      FROM etape_recette
      WHERE recette_id = ?
      ORDER BY numero ASC
    `,
      [req.params.id]
    );

    // Moyenne des avis
    const [avis] = await db.query(
      `SELECT note, commentaire FROM avis WHERE recette_id = ?`,
      [req.params.id]
    );

    recette.ingredients = ingredients;
    recette.etapes = etapes;
    recette.avis = avis;

    res.json(recette);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// POST /api/recettes
// ----------------------------------------------------
async function create(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const {
    nom,
    description,
    difficulte,
    temps_preparation,
    temps_cuisson,
    nb_personnes,
    ingredients,
    etapes
  } = req.body;

  try {
    await db.query("START TRANSACTION");

    const [result] = await db.query(
      `
      INSERT INTO recette (nom, description, difficulte, temps_preparation, temps_cuisson, nb_personnes)
      VALUES (?, ?, ?, ?, ?, ?)
    `,
      [nom, description, difficulte, temps_preparation, temps_cuisson, nb_personnes || null]
    );

    const recetteId = result.insertId;

    // Insertion des ingrédients (table recette_ingredient)
    if (Array.isArray(ingredients)) {
      for (const ing of ingredients) {
        await db.query(
          `INSERT INTO recette_ingredient (recette_id, ingredient_id, quantite)
           VALUES (?, ?, ?)`,
          [recetteId, ing.ingredient_id, ing.quantite]
        );
      }
    }

    // Insertion des étapes (table etape_recette)
    if (Array.isArray(etapes)) {
      for (const [index, etape] of etapes.entries()) {
        await db.query(
          `INSERT INTO etape_recette (recette_id, numero, description)
           VALUES (?, ?, ?)`,
          [recetteId, index + 1, etape.description]
        );
      }
    }

    await db.query("COMMIT");
    res.status(201).json({ message: "Recette créée", id: recetteId });
  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
}

// ----------------------------------------------------
// PUT /api/recettes/:id
// ----------------------------------------------------
async function update(req, res, next) {
  const { id } = req.params;
  const {
    nom,
    description,
    difficulte,
    temps_preparation,
    temps_cuisson,
    nb_personnes,
    ingredients,
    etapes
  } = req.body;

  try {
    await db.query("START TRANSACTION");

    const [result] = await db.query(
      `
      UPDATE recette
      SET nom = COALESCE(?, nom),
          description = COALESCE(?, description),
          difficulte = COALESCE(?, difficulte),
          temps_preparation = COALESCE(?, temps_preparation),
          temps_cuisson = COALESCE(?, temps_cuisson),
          nb_personnes = COALESCE(?, nb_personnes)
      WHERE id = ?
    `,
      [nom, description, difficulte, temps_preparation, temps_cuisson, nb_personnes, id]
    );

    if (result.affectedRows === 0) {
      await db.query("ROLLBACK");
      return res.status(404).json({ message: "Recette introuvable" });
    }

    // Mise à jour des ingrédients
    if (Array.isArray(ingredients)) {
      await db.query("DELETE FROM recette_ingredient WHERE recette_id = ?", [id]);
      for (const ing of ingredients) {
        await db.query(
          `INSERT INTO recette_ingredient (recette_id, ingredient_id, quantite)
           VALUES (?, ?, ?)`,
          [id, ing.ingredient_id, ing.quantite]
        );
      }
    }

    // Mise à jour des étapes
    if (Array.isArray(etapes)) {
      await db.query("DELETE FROM etape_recette WHERE recette_id = ?", [id]);
      for (const [index, etape] of etapes.entries()) {
        await db.query(
          `INSERT INTO etape_recette (recette_id, numero, description)
           VALUES (?, ?, ?)`,
          [id, index + 1, etape.description]
        );
      }
    }

    await db.query("COMMIT");
    res.json({ message: "Recette mise à jour" });
  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
}

// ----------------------------------------------------
// DELETE /api/recettes/:id
// ----------------------------------------------------
async function remove(req, res, next) {
  try {
    const [result] = await db.query("DELETE FROM recette WHERE id = ?", [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Recette introuvable" });
    }
    res.json({ message: "Recette supprimée" });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
};
