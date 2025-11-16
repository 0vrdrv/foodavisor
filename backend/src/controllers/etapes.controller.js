const db = require("../config/db");

exports.list = async (req, res) => {
  const { recette_id } = req.params;
  const [rows] = await db.query(
    `SELECT ord, description FROM etape_recette WHERE recette_id = ? ORDER BY ord`,
    [recette_id]
  );
  res.json(rows);
};

exports.create = async (req, res) => {
  const { recette_id } = req.params;
  const { ord, description } = req.body;
  await db.query(
    `INSERT INTO etape_recette (recette_id, ord, description) VALUES (?, ?, ?)`,
    [recette_id, ord, description]
  );
  res.json({ message: "Étape ajoutée." });
};

exports.update = async (req, res) => {
  const { recette_id, ord } = req.params;
  const { description } = req.body;
  await db.query(
    `UPDATE etape_recette SET description = ? WHERE recette_id = ? AND ord = ?`,
    [description, recette_id, ord]
  );
  res.json({ message: "Étape modifiée." });
};

exports.remove = async (req, res) => {
  const { recette_id, ord } = req.params;
  await db.query(
    `DELETE FROM etape_recette WHERE recette_id = ? AND ord = ?`,
    [recette_id, ord]
  );
  res.json({ message: "Étape supprimée." });
};
