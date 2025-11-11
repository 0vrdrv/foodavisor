const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /api/ingredients
// ----------------------------------------------------
async function list(req, res, next) {
  try {
    const [rows] = await db.query(`
      SELECT i.id, i.nom, c.libelle AS categorie,
             i.kcal_100g, i.prot_100g, i.gluc_100g, i.lip_100g, i.prix_unitaire
      FROM ingredient i
      JOIN categorie_ingredient c ON c.id = i.categorie_id
      ORDER BY i.nom ASC
    `);

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// GET /api/ingredients/:id
// ----------------------------------------------------
async function getById(req, res, next) {
  try {
    const [rows] = await db.query(
      `
      SELECT i.*, c.libelle AS categorie
      FROM ingredient i
      JOIN categorie_ingredient c ON c.id = i.categorie_id
      WHERE i.id = ?
    `,
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "Ingrédient introuvable" });
    }

    // récupérer les allergènes liés
    const [allergenes] = await db.query(
      `
      SELECT a.id, a.libelle
      FROM ingredient_allergene ia
      JOIN allergene a ON a.id = ia.allergene_id
      WHERE ia.ingredient_id = ?
    `,
      [req.params.id]
    );

    // récupérer l’historique des prix
    const [prix] = await db.query(
      `
      SELECT date_effet, prix_unitaire
      FROM prix_ingredient
      WHERE ingredient_id = ?
      ORDER BY date_effet DESC
      LIMIT 5
    `,
      [req.params.id]
    );

    const ingredient = rows[0];
    ingredient.allergenes = allergenes;
    ingredient.historique_prix = prix;

    res.json(ingredient);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// POST /api/ingredients
// ----------------------------------------------------
async function create(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const {
    nom,
    categorie_id,
    kcal_100g,
    prot_100g,
    gluc_100g,
    lip_100g,
    prix_unitaire,
    allergenes,
  } = req.body;

  try {
    await db.query("START TRANSACTION");

    const [result] = await db.query(
      `
      INSERT INTO ingredient (nom, categorie_id, kcal_100g, prot_100g, gluc_100g, lip_100g, prix_unitaire)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `,
      [nom, categorie_id, kcal_100g, prot_100g, gluc_100g, lip_100g, prix_unitaire]
    );

    const ingredient_id = result.insertId;

    // associer allergènes s’ils existent
    if (Array.isArray(allergenes)) {
      for (const id of allergenes) {
        await db.query(
          "INSERT INTO ingredient_allergene (ingredient_id, allergene_id) VALUES (?, ?)",
          [ingredient_id, id]
        );
      }
    }

    await db.query("COMMIT");

    res.status(201).json({ message: "Ingrédient ajouté", id: ingredient_id });
  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
}

// ----------------------------------------------------
// PUT /api/ingredients/:id
// ----------------------------------------------------
async function update(req, res, next) {
  const {
    nom,
    categorie_id,
    kcal_100g,
    prot_100g,
    gluc_100g,
    lip_100g,
    prix_unitaire,
    allergenes,
  } = req.body;

  try {
    await db.query("START TRANSACTION");

    const [result] = await db.query(
      `
      UPDATE ingredient
      SET nom = COALESCE(?, nom),
          categorie_id = COALESCE(?, categorie_id),
          kcal_100g = COALESCE(?, kcal_100g),
          prot_100g = COALESCE(?, prot_100g),
          gluc_100g = COALESCE(?, gluc_100g),
          lip_100g = COALESCE(?, lip_100g),
          prix_unitaire = COALESCE(?, prix_unitaire)
      WHERE id = ?
    `,
      [
        nom,
        categorie_id,
        kcal_100g,
        prot_100g,
        gluc_100g,
        lip_100g,
        prix_unitaire,
        req.params.id,
      ]
    );

    if (result.affectedRows === 0) {
      await db.query("ROLLBACK");
      return res.status(404).json({ message: "Ingrédient introuvable" });
    }

    // mettre à jour les allergènes
    if (Array.isArray(allergenes)) {
      await db.query(
        "DELETE FROM ingredient_allergene WHERE ingredient_id = ?",
        [req.params.id]
      );
      for (const id of allergenes) {
        await db.query(
          "INSERT INTO ingredient_allergene (ingredient_id, allergene_id) VALUES (?, ?)",
          [req.params.id, id]
        );
      }
    }

    await db.query("COMMIT");
    res.json({ message: "Ingrédient mis à jour" });
  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
}

// ----------------------------------------------------
// DELETE /api/ingredients/:id
// ----------------------------------------------------
async function remove(req, res, next) {
  try {
    const [result] = await db.query("DELETE FROM ingredient WHERE id = ?", [
      req.params.id,
    ]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Ingrédient introuvable" });
    }

    res.json({ message: "Ingrédient supprimé" });
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
