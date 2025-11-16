const db = require("../config/db");

exports.list = async (req, res) => {
  const [rows] = await db.query(`SELECT id, libelle FROM allergene ORDER BY libelle`);
  res.json(rows);
};

exports.create = async (req, res) => {
  const { libelle } = req.body;
  await db.query(`INSERT INTO allergene (libelle) VALUES (?)`, [libelle]);
  res.json({ message: "Allergène ajouté." });
};

exports.remove = async (req, res) => {
  await db.query(`DELETE FROM allergene WHERE id = ?`, [req.params.id]);
  res.json({ message: "Allergène supprimé." });
};

exports.addToIngredient = async (req, res) => {
  const { ingredient_id } = req.params;
  const { allergene_id } = req.body;
  await db.query(
    `INSERT IGNORE INTO ingredient_allergene (ingredient_id, allergene_id) VALUES (?, ?)`,
    [ingredient_id, allergene_id]
  );
  res.json({ message: "Lien ajouté." });
};

exports.removeFromIngredient = async (req, res) => {
  const { ingredient_id, allergene_id } = req.params;
  await db.query(
    `DELETE FROM ingredient_allergene WHERE ingredient_id = ? AND allergene_id = ?`,
    [ingredient_id, allergene_id]
  );
  res.json({ message: "Lien supprimé." });
};
