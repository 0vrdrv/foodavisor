const db = require("../config/db");

exports.recommander = async (req, res) => {
  const userId = req.user.id;
  const { stock_only = false, trier = "note", limite = 10 } = req.query;

  // Allergies utilisateur
  const [userAllergies] = await db.query(
    `SELECT allergene_id FROM utilisateur_allergie WHERE utilisateur_id = ?`,
    [userId]
  );

  // Aliments exclus
  const [userExclusions] = await db.query(
    `SELECT ingredient_id FROM utilisateur_aliment_exclu WHERE utilisateur_id = ?`,
    [userId]
  );

  // Dernière recette réalisée
  const [lastCook] = await db.query(
    `SELECT recette_id FROM historique_cuisson WHERE utilisateur_id = ? ORDER BY ts DESC LIMIT 1`,
    [userId]
  );

  const allergiesIds = userAllergies.map(a => a.allergene_id);
  const exclusionIds = userExclusions.map(e => e.ingredient_id);
  const lastRecetteId = lastCook[0]?.recette_id || null;

  let query = `
      SELECT r.id, r.titre, r.description,
             v.note_moy, c.cout_estime
      FROM recette r
        LEFT JOIN v_recette_note v ON v.recette_id = r.id
        LEFT JOIN v_cout_recette c ON c.recette_id = r.id
      WHERE r.publie = 1
  `;

  // Exclusion recette cuisinée récemment
  if (lastRecetteId) query += ` AND r.id <> ${lastRecetteId} `;

  // Exclusion allergènes
  if (allergiesIds.length > 0) {
    query += `
      AND r.id NOT IN (
        SELECT recette_id
        FROM recette_ingredient ri
        JOIN ingredient_allergene ia ON ia.ingredient_id = ri.ingredient_id
        WHERE ia.allergene_id IN (${allergiesIds.join(",")})
      )
    `;
  }

  // Exclusion aliments interdits
  if (exclusionIds.length > 0) {
    query += `
      AND r.id NOT IN (
        SELECT recette_id
        FROM recette_ingredient
        WHERE ingredient_id IN (${exclusionIds.join(",")})
      )
    `;
  }

  // Filtre “réalisable avec stock”
  if (stock_only === "true") {
    query += `
      AND r.id NOT IN (
        SELECT ri.recette_id
        FROM recette_ingredient ri
        JOIN stock s ON s.ingredient_id = ri.ingredient_id
                     AND s.utilisateur_id = ${userId}
        WHERE s.quantite < ri.quantite
      )
    `;
  }

  // Tri
  if (trier === "cout") query += ` ORDER BY c.cout_estime ASC `;
  else query += ` ORDER BY v.note_moy DESC `;

  query += ` LIMIT ${limite} `;

  const [rows] = await db.query(query);
  res.json(rows);
};
