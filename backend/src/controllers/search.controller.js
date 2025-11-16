const db = require("../config/db");

exports.searchRecettes = async (req, res) => {
  const { titre, categorie, cout_max, kcal_max } = req.query;

  let query = `
    SELECT r.id, r.titre, r.description,
           v.note_moy, c.cout_estime
    FROM recette r
      LEFT JOIN v_recette_note v ON v.recette_id = r.id
      LEFT JOIN v_cout_recette c ON c.recette_id = r.id
    WHERE r.publie = 1
  `;

  if (titre) query += ` AND r.titre LIKE '%${titre}%' `;
  if (cout_max) query += ` AND c.cout_estime <= ${db.escape(cout_max)} `;
  if (kcal_max) query += ` AND r.id IN (
      SELECT ri.recette_id
      FROM recette_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      GROUP BY ri.recette_id
      HAVING SUM(ri.quantite * i.kcal_100g / 100) <= ${db.escape(kcal_max)}
    )`;

  if (categorie) query += `
    AND r.id IN (
      SELECT recette_id
      FROM recette_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE i.categorie_id = ${db.escape(categorie)}
    )
  `;

  const [rows] = await db.query(query);
  res.json(rows);
};
