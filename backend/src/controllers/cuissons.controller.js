const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /api/cuissons
// ----------------------------------------------------
async function list(req, res, next) {
  try {
    const utilisateur_id = req.user.id;

    const [rows] = await db.query(`
      SELECT hc.id, hc.recette_id, r.titre, hc.personnes, hc.ts
      FROM historique_cuisson hc
      JOIN recette r ON r.id = hc.recette_id
      WHERE hc.utilisateur_id = ?
      ORDER BY hc.ts DESC
      LIMIT 50
    `, [utilisateur_id]);

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// POST /api/cuissons  (lancer une cuisson)
// ----------------------------------------------------
async function cook(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const utilisateur_id = req.user.id;
  const { recette_id, personnes } = req.body;

  try {
    await db.query("START TRANSACTION");

    // 1️⃣ Vérifier la recette
    const [recette] = await db.query(
      "SELECT id, titre, personnes_defaut FROM recette WHERE id = ?",
      [recette_id]
    );

    if (recette.length === 0) {
      await db.query("ROLLBACK");
      return res.status(404).json({ message: "Recette introuvable" });
    }

    const personnes_defaut = recette[0].personnes_defaut || 1;
    const facteur = parseFloat(personnes) / parseFloat(personnes_defaut);

    if (isNaN(facteur) || facteur <= 0) {
      await db.query("ROLLBACK");
      return res.status(400).json({ message: "Nombre de personnes invalide." });
    }

    // 2️⃣ Récupérer les ingrédients de la recette
    const [ingredients] = await db.query(`
      SELECT ingredient_id, quantite, unite_code
      FROM recette_ingredient
      WHERE recette_id = ?
    `, [recette_id]);

    if (ingredients.length === 0) {
      await db.query("ROLLBACK");
      return res.status(400).json({ message: "Cette recette ne contient aucun ingrédient." });
    }

    // 3️⃣ Déduction des stocks
    for (const ing of ingredients) {

      const quantiteRecette = parseFloat(ing.quantite);
      if (isNaN(quantiteRecette) || quantiteRecette <= 0) {
        await db.query("ROLLBACK");
        return res.status(400).json({
          message: "Un ingrédient de la recette possède une quantité invalide.",
        });
      }

      if (!ing.unite_code) {
        await db.query("ROLLBACK");
        return res.status(400).json({
          message: "Un ingrédient de la recette possède une unité invalide.",
        });
      }

      const qte_utilisee = quantiteRecette * facteur * -1;

      // Vérifier le stock existant
      const [stock] = await db.query(
        "SELECT quantite FROM stock WHERE utilisateur_id = ? AND ingredient_id = ?",
        [utilisateur_id, ing.ingredient_id]
      );

      let nouvelleQuantite = 0;

      if (stock.length > 0) {
        const quantiteStock = parseFloat(stock[0].quantite);
        nouvelleQuantite = Math.max(0, quantiteStock + qte_utilisee);

        await db.query(
          `UPDATE stock
           SET quantite = ?, unite_code = ?
           WHERE utilisateur_id = ? AND ingredient_id = ?`,
          [nouvelleQuantite, ing.unite_code, utilisateur_id, ing.ingredient_id]
        );
      } else {
        await db.query(
          `INSERT INTO stock (utilisateur_id, ingredient_id, quantite, unite_code)
           VALUES (?, ?, 0, ?)`,
          [utilisateur_id, ing.ingredient_id, ing.unite_code]
        );
      }

      // MOUVEMENT
      await db.query(
        `INSERT INTO mvt_stock (utilisateur_id, ingredient_id, delta, unite_code, raison)
         VALUES (?, ?, ?, ?, 'cuisson')`,
        [utilisateur_id, ing.ingredient_id, qte_utilisee, ing.unite_code]
      );
    }

    // 4️⃣ Ajout historique
    await db.query(
      `INSERT INTO historique_cuisson (utilisateur_id, recette_id, personnes)
       VALUES (?, ?, ?)`,
      [utilisateur_id, recette_id, personnes]
    );

    await db.query("COMMIT");
    res.status(201).json({ message: "Cuisson enregistrée", recette_id });
  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
}

module.exports = {
  list,
  cook,
};
