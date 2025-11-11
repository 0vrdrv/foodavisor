const db = require("../config/db");

// ----------------------------------------------------
// GET /api/stats/user
// ----------------------------------------------------
async function userStats(req, res, next) {
  try {
    const utilisateur_id = req.user.id;

    // 1️⃣ Nombre total de recettes publiées par l'utilisateur
    const [recettesCreees] = await db.query(
      `SELECT COUNT(*) AS nb_recettes
       FROM recette
       WHERE auteur_id = ?`,
      [utilisateur_id]
    );

    // 2️⃣ Nombre total de cuissons effectuées
    const [cuissons] = await db.query(
      `SELECT COUNT(*) AS nb_cuissons
       FROM historique_cuisson
       WHERE utilisateur_id = ?`,
      [utilisateur_id]
    );

    // 3️⃣ Moyenne des notes données
    const [notes] = await db.query(
      `SELECT AVG(note) AS moyenne_notes, COUNT(*) AS nb_avis
       FROM avis
       WHERE utilisateur_id = ?`,
      [utilisateur_id]
    );

    // 4️⃣ Ingrédients les plus utilisés dans ses cuissons
    const [ingredients] = await db.query(
      `
      SELECT i.nom, ABS(SUM(ms.delta)) AS quantite_utilisee, ms.unite_code
      FROM mvt_stock ms
      JOIN ingredient i ON i.id = ms.ingredient_id
      WHERE ms.utilisateur_id = ? AND ms.raison = 'cuisson'
      GROUP BY i.id, ms.unite_code
      ORDER BY quantite_utilisee DESC
      LIMIT 5
    `,
      [utilisateur_id]
    );

    res.json({
      utilisateur_id,
      nb_recettes: recettesCreees[0].nb_recettes,
      nb_cuissons: cuissons[0].nb_cuissons,
      nb_avis: notes[0].nb_avis,
      moyenne_notes: notes[0].moyenne_notes
        ? Number(notes[0].moyenne_notes.toFixed(2))
        : null,
      top_ingredients: ingredients
    });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// GET /api/stats/global
// ----------------------------------------------------
async function globalStats(req, res, next) {
  try {
    // 1️⃣ Nombre total d'utilisateurs et d'actifs
    const [users] = await db.query(`
      SELECT COUNT(*) AS total, SUM(actif) AS actifs
      FROM utilisateur
    `);

    // 2️⃣ Nombre total de recettes
    const [recettes] = await db.query(`
      SELECT COUNT(*) AS total_recettes, AVG(note_cache) AS note_moyenne
      FROM recette
    `);

    // 3️⃣ Recettes les plus cuisinées
    const [topRecettes] = await db.query(`
      SELECT r.titre, COUNT(hc.id) AS nb_cuissons
      FROM historique_cuisson hc
      JOIN recette r ON r.id = hc.recette_id
      GROUP BY r.id
      ORDER BY nb_cuissons DESC
      LIMIT 5
    `);

    // 4️⃣ Recettes les mieux notées
    const [bestRated] = await db.query(`
      SELECT r.titre, AVG(a.note) AS moyenne
      FROM avis a
      JOIN recette r ON r.id = a.recette_id
      GROUP BY r.id
      HAVING COUNT(a.id) >= 2
      ORDER BY moyenne DESC
      LIMIT 5
    `);

    // 5️⃣ Ingrédients les plus utilisés globalement
    const [topIngredients] = await db.query(`
      SELECT i.nom, ABS(SUM(ms.delta)) AS quantite_utilisee, ms.unite_code
      FROM mvt_stock ms
      JOIN ingredient i ON i.id = ms.ingredient_id
      WHERE ms.raison = 'cuisson'
      GROUP BY i.id, ms.unite_code
      ORDER BY quantite_utilisee DESC
      LIMIT 5
    `);

    res.json({
      utilisateurs: {
        total: users[0].total,
        actifs: users[0].actifs
      },
      recettes: {
        total: recettes[0].total_recettes,
        note_moyenne: recettes[0].note_moyenne
          ? Number(recettes[0].note_moyenne.toFixed(2))
          : null
      },
      top_recettes: topRecettes,
      meilleures_recettes: bestRated,
      ingredients_plus_utilises: topIngredients
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  userStats,
  globalStats
};
