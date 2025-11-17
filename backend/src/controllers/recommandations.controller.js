const db = require("../config/db");

/**
 * GET /recommandations
 *
 * Query params :
 *  - stock_only=1
 *  - order=note|cout|recent
 */
async function list(req, res, next) {
  const userId = req.user.id;
  const { stock_only, order } = req.query;

  try {
    // Charger préférences utilisateur
    const [allergiesRows] = await db.query(
      "SELECT allergene_id FROM utilisateur_allergie WHERE utilisateur_id = ?",
      [userId]
    );
    const [exclusRows] = await db.query(
      "SELECT ingredient_id FROM utilisateur_aliment_exclu WHERE utilisateur_id = ?",
      [userId]
    );

    const allergies = allergiesRows.map(a => a.allergene_id);
    const ingredientsExclus = exclusRows.map(e => e.ingredient_id);

    //
    // ----- Construction dynamique du WHERE -----
    //
    let where = "WHERE r.publie = 1";
    const params = [];

    // Allergies
    if (allergies.length > 0) {
      where += `
        AND NOT EXISTS (
          SELECT 1
          FROM recette_ingredient ri
          JOIN ingredient_allergene ia ON ia.ingredient_id = ri.ingredient_id
          WHERE ri.recette_id = r.id
            AND ia.allergene_id IN (${allergies.map(() => "?").join(",")})
        )
      `;
      params.push(...allergies);
    }

    // Aliments exclus
    if (ingredientsExclus.length > 0) {
      where += `
        AND NOT EXISTS (
          SELECT 1
          FROM recette_ingredient ri
          WHERE ri.recette_id = r.id
            AND ri.ingredient_id IN (${ingredientsExclus
              .map(() => "?")
              .join(",")})
        )
      `;
      params.push(...ingredientsExclus);
    }

    // Seulement réalisables avec stock
    if (stock_only === "1") {
      where += `
        AND NOT EXISTS (
          SELECT 1
          FROM recette_ingredient ri
          LEFT JOIN stock s
            ON s.ingredient_id = ri.ingredient_id
           AND s.utilisateur_id = ?
          WHERE ri.recette_id = r.id
            AND (s.ingredient_id IS NULL OR s.quantite < ri.quantite)
        )
      `;
      params.push(userId);
    }

    //
    // ----- Tri -----
    //
    let orderBy = "ORDER BY r.date_creation DESC";

    if (order === "note") {
      orderBy = `
        ORDER BY
          note_moyenne IS NULL,
          note_moyenne DESC,
          r.date_creation DESC
      `;
    }

    if (order === "cout") {
      orderBy = `
        ORDER BY
          r.cout_cache IS NULL,
          r.cout_cache ASC
      `;
    }

    //
    // ----- Requête finale -----
    //
    const [rows] = await db.query(
      `
      SELECT
        r.id,
        r.titre,
        r.description,
        r.image_url,
        r.cout_cache,
        r.personnes_defaut,
        u.prenom AS auteur_prenom,
        u.nom AS auteur_nom,
        COUNT(DISTINCT ri.ingredient_id) AS nb_ingredients,
        ROUND(AVG(a.note), 2) AS note_moyenne
      FROM recette r
      JOIN utilisateur u ON u.id = r.auteur_id
      LEFT JOIN recette_ingredient ri ON ri.recette_id = r.id
      LEFT JOIN avis a ON a.recette_id = r.id
      ${where}
      GROUP BY r.id
      ${orderBy}
      LIMIT 100
    `,
      params
    );

    res.json(rows);

  } catch (err) {
    next(err);
  }
}

module.exports = { list };
