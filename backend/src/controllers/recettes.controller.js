const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /recettes → liste des recettes
// ----------------------------------------------------
async function list(req, res, next) {
  try {
    const [rows] = await db.query(`
      SELECT r.id,
       r.titre,
       r.description,
       r.image_url,
       r.note_cache,
       r.date_creation,
       r.auteur_id,                     -- ✔ important
       u.prenom AS auteur_prenom,
       u.nom AS auteur_nom,
       COUNT(ri.ingredient_id) AS nb_ingredients,
       ROUND(AVG(a.note), 2) AS note_moyenne
FROM recette r
JOIN utilisateur u ON u.id = r.auteur_id

      LEFT JOIN recette_ingredient ri ON ri.recette_id = r.id
      LEFT JOIN avis a ON a.recette_id = r.id
      WHERE r.publie = 1
      GROUP BY r.id
      ORDER BY r.date_creation DESC
    `);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// GET /recettes/:id → détail complet
// ----------------------------------------------------
async function getById(req, res, next) {
  try {
    const recetteId = req.params.id;

    // Récupération de la recette principale
    const [recetteRows] = await db.query(
      `
      SELECT r.*, u.nom AS auteur_nom, u.prenom AS auteur_prenom
      FROM recette r
      JOIN utilisateur u ON u.id = r.auteur_id
      WHERE r.id = ?
    `,
      [recetteId]
    );

    if (recetteRows.length === 0) {
      return res.status(404).json({ message: "Recette introuvable" });
    }

    const recette = recetteRows[0];

    // Ingrédients
    const [ingredients] = await db.query(
      `
      SELECT i.id, i.nom, i.image_url, ri.quantite, ri.unite_code
      FROM recette_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recette_id = ?
    `,
      [recetteId]
    );

    // Étapes
    const [etapes] = await db.query(
      `
      SELECT ord, description
      FROM etape_recette
      WHERE recette_id = ?
      ORDER BY ord ASC
    `,
      [recetteId]
    );

    // Avis (si présents)
    const [avis] = await db.query(
      `
      SELECT a.note, a.commentaire, u.prenom, u.nom
      FROM avis a
      JOIN utilisateur u ON u.id = a.utilisateur_id
      WHERE a.recette_id = ?
    `,
      [recetteId]
    );

    res.json({
      ...recette,
      ingredients,
      etapes,
      avis,
    });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// POST /recettes → création (ADMIN)
// ----------------------------------------------------
async function create(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const {
    titre,
    description,
    image_url,
    personnes_defaut,
    ingredients,
    etapes,
  } = req.body;

  try {
    await db.query("START TRANSACTION");

    // Insertion de la recette
    const [result] = await db.query(
      `
      INSERT INTO recette (auteur_id, titre, description, image_url, personnes_defaut)
      VALUES (?, ?, ?, ?, COALESCE(?, 2))
    `,
      [
        req.user.id,
        titre,
        description || null,
        image_url || null,
        personnes_defaut,
      ]
    );

    const recetteId = result.insertId;

    // Insertion des ingrédients
    if (Array.isArray(ingredients)) {
      for (const ing of ingredients) {
        await db.query(
          `
          INSERT INTO recette_ingredient (recette_id, ingredient_id, quantite, unite_code)
          VALUES (?, ?, ?, ?)
        `,
          [recetteId, ing.ingredient_id, ing.quantite, ing.unite_code]
        );
      }
    }

    // Insertion des étapes
    if (Array.isArray(etapes)) {
      for (const [index, etape] of etapes.entries()) {
        await db.query(
          `
          INSERT INTO etape_recette (recette_id, ord, description)
          VALUES (?, ?, ?)
        `,
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
// PUT /recettes/:id → modification (ADMIN)
// ----------------------------------------------------
async function update(req, res, next) {
  const { id } = req.params;
  const {
    titre,
    description,
    image_url,
    personnes_defaut,
    ingredients,
    etapes,
  } = req.body;

  try {
    await db.query("START TRANSACTION");

    const [result] = await db.query(
      `
      UPDATE recette
      SET titre = COALESCE(?, titre),
          description = COALESCE(?, description),
          image_url = COALESCE(?, image_url),
          personnes_defaut = COALESCE(?, personnes_defaut)
      WHERE id = ?
    `,
      [titre, description, image_url, personnes_defaut, id]
    );

    if (result.affectedRows === 0) {
      await db.query("ROLLBACK");
      return res.status(404).json({ message: "Recette introuvable" });
    }

    // Mise à jour des ingrédients
    if (Array.isArray(ingredients)) {
      await db.query("DELETE FROM recette_ingredient WHERE recette_id = ?", [
        id,
      ]);
      for (const ing of ingredients) {
        await db.query(
          `
          INSERT INTO recette_ingredient (recette_id, ingredient_id, quantite, unite_code)
          VALUES (?, ?, ?, ?)
        `,
          [id, ing.ingredient_id, ing.quantite, ing.unite_code]
        );
      }
    }

    // Mise à jour des étapes
    if (Array.isArray(etapes)) {
      await db.query("DELETE FROM etape_recette WHERE recette_id = ?", [id]);
      for (const [index, etape] of etapes.entries()) {
        await db.query(
          `
          INSERT INTO etape_recette (recette_id, ord, description)
          VALUES (?, ?, ?)
        `,
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
// DELETE /recettes/:id → suppression (ADMIN)
// ----------------------------------------------------
async function remove(req, res, next) {
  try {
    const [result] = await db.query("DELETE FROM recette WHERE id = ?", [
      req.params.id,
    ]);
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
