const db = require("../config/db");
const { validationResult } = require("express-validator");

// Vérifie si une entrée existe dans la DB
async function checkExists(query, params) {
  const [rows] = await db.query(query, params);
  return rows.length > 0;
}

// -------------------
// Ajouter un ingrédient
// -------------------
exports.add = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const { recette_id } = req.params;
  const { ingredient_id, quantite, unite_code } = req.body;

  // Vérifier existence ingrédient
  const ingredientExiste = await checkExists(
    "SELECT id FROM ingredient WHERE id = ?",
    [ingredient_id]
  );

  if (!ingredientExiste) {
    return res.status(400).json({ message: "Ingrédient inexistant." });
  }

  // Vérifier existence unité
  const uniteExiste = await checkExists(
    "SELECT code FROM unite WHERE code = ?",
    [unite_code]
  );

  if (!uniteExiste) {
    return res.status(400).json({ message: "Unité invalide." });
  }

  // Insérer
  await db.query(
    `INSERT INTO recette_ingredient (recette_id, ingredient_id, quantite, unite_code)
     VALUES (?, ?, ?, ?)`,
    [recette_id, ingredient_id, parseFloat(quantite), unite_code]
  );

  res.json({ message: "Ingrédient ajouté à la recette." });
};

// -------------------
// Modifier un ingrédient
// -------------------
exports.update = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const { recette_id, ingredient_id } = req.params;
  const { quantite, unite_code } = req.body;

  // Vérifier existence de la ligne
  const existe = await checkExists(
    `SELECT ingredient_id FROM recette_ingredient WHERE recette_id = ? AND ingredient_id = ?`,
    [recette_id, ingredient_id]
  );

  if (!existe) {
    return res.status(404).json({ message: "Ingrédient non présent dans la recette." });
  }

  // Validation unite si envoyée
  if (unite_code) {
    const uniteExiste = await checkExists(
      "SELECT code FROM unite WHERE code = ?",
      [unite_code]
    );
    if (!uniteExiste) {
      return res.status(400).json({ message: "Unité invalide." });
    }
  }

  await db.query(
    `UPDATE recette_ingredient
     SET quantite = COALESCE(?, quantite),
         unite_code = COALESCE(?, unite_code)
     WHERE recette_id = ? AND ingredient_id = ?`,
    [quantite ? parseFloat(quantite) : null, unite_code, recette_id, ingredient_id]
  );

  res.json({ message: "Ingrédient mis à jour." });
};

// -------------------
exports.remove = async (req, res) => {
  const { recette_id, ingredient_id } = req.params;

  await db.query(
    `DELETE FROM recette_ingredient WHERE recette_id = ? AND ingredient_id = ?`,
    [recette_id, ingredient_id]
  );

  res.json({ message: "Ingrédient retiré de la recette." });
};
