const db = require("../config/db");

exports.add = async (req, res) => {
  const { recette_id } = req.params;
  const { ingredient_id, quantite, unite_code } = req.body;

  await db.query(
    `INSERT INTO recette_ingredient (recette_id, ingredient_id, quantite, unite_code)
     VALUES (?, ?, ?, ?)`,
    [recette_id, ingredient_id, quantite, unite_code]
  );

  res.json({ message: "Ingrédient ajouté à la recette." });
};

exports.update = async (req, res) => {
  const { recette_id, ingredient_id } = req.params;
  const { quantite, unite_code } = req.body;

  await db.query(
    `UPDATE recette_ingredient
     SET quantite = COALESCE(?, quantite),
         unite_code = COALESCE(?, unite_code)
     WHERE recette_id = ? AND ingredient_id = ?`,
    [quantite, unite_code, recette_id, ingredient_id]
  );

  res.json({ message: "Ingrédient mis à jour." });
};

exports.remove = async (req, res) => {
  const { recette_id, ingredient_id } = req.params;

  await db.query(
    `DELETE FROM recette_ingredient WHERE recette_id = ? AND ingredient_id = ?`,
    [recette_id, ingredient_id]
  );

  res.json({ message: "Ingrédient retiré de la recette." });
};
