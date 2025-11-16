const db = require("../config/db");

// ======================================================
// GET /preferences
// ======================================================
exports.getPreferences = async (req, res) => {
  const userId = req.user.id;

  const [allergies] = await db.query(
    `SELECT allergene_id FROM utilisateur_allergie WHERE utilisateur_id = ?`,
    [userId]
  );

  const [exclusions] = await db.query(
    `SELECT ingredient_id FROM utilisateur_aliment_exclu WHERE utilisateur_id = ?`,
    [userId]
  );

  const [favoris] = await db.query(
    `SELECT recette_id FROM utilisateur_favori WHERE utilisateur_id = ?`,
    [userId]
  );

  res.json({
    allergies: allergies.map(a => a.allergene_id),
    aliments_exclus: exclusions.map(e => e.ingredient_id),
    favoris: favoris.map(f => f.recette_id),
  });
};

// ======================================================
// PUT /preferences
// ======================================================
exports.updatePreferences = async (req, res) => {
  const userId = req.user.id;
  const { allergies = [], exclus = [], favoris = [] } = req.body;

  await db.query(`DELETE FROM utilisateur_allergie WHERE utilisateur_id = ?`, [userId]);
  await db.query(`DELETE FROM utilisateur_aliment_exclu WHERE utilisateur_id = ?`, [userId]);
  await db.query(`DELETE FROM utilisateur_favori WHERE utilisateur_id = ?`, [userId]);

  for (const a of allergies)
    await db.query(
      `INSERT INTO utilisateur_allergie (utilisateur_id, allergene_id) VALUES (?, ?)`,
      [userId, a]
    );

  for (const ing of exclus)
    await db.query(
      `INSERT INTO utilisateur_aliment_exclu (utilisateur_id, ingredient_id) VALUES (?, ?)`,
      [userId, ing]
    );

  for (const r of favoris)
    await db.query(
      `INSERT INTO utilisateur_favori (utilisateur_id, recette_id) VALUES (?, ?)`,
      [userId, r]
    );

  res.json({ message: "Préférences mises à jour." });
};
