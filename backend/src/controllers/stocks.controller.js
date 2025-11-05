const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /stocks  → Stock de l’utilisateur connecté
// ----------------------------------------------------
async function list(req, res, next) {
  try {
    const [rows] = await db.query(`
      SELECT s.ingredient_id, i.nom AS ingredient, s.quantite, s.unite_code, s.date_peremption
      FROM stock s
      JOIN ingredient i ON i.id = s.ingredient_id
      WHERE s.utilisateur_id = ?
      ORDER BY i.nom ASC
    `, [req.user.id]);

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// GET /stocks/:ingredient_id
// ----------------------------------------------------
async function getById(req, res, next) {
  try {
    const [rows] = await db.query(`
      SELECT s.ingredient_id, i.nom AS ingredient, s.quantite, s.unite_code, s.date_peremption
      FROM stock s
      JOIN ingredient i ON i.id = s.ingredient_id
      WHERE s.utilisateur_id = ? AND s.ingredient_id = ?
    `, [req.user.id, req.params.ingredient_id]);

    if (rows.length === 0) {
      return res.status(404).json({ message: "Ingrédient non trouvé dans le stock" });
    }

    const [mouvements] = await db.query(`
      SELECT id, ts, raison, delta, unite_code
      FROM mvt_stock
      WHERE utilisateur_id = ? AND ingredient_id = ?
      ORDER BY ts DESC
      LIMIT 30
    `, [req.user.id, req.params.ingredient_id]);

    res.json({
      ...rows[0],
      mouvements
    });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// POST /stocks/mvt
// ----------------------------------------------------
async function addMovement(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const { ingredient_id, delta, unite_code, raison } = req.body;
  const utilisateur_id = req.user.id;

  try {
    await db.query("START TRANSACTION");

    // Vérifier si une ligne de stock existe déjà
    const [exist] = await db.query(
      "SELECT quantite FROM stock WHERE utilisateur_id = ? AND ingredient_id = ?",
      [utilisateur_id, ingredient_id]
    );

    let quantite = 0;
    if (exist.length > 0) {
      quantite = exist[0].quantite + delta;
      if (quantite < 0) quantite = 0; // pas de stock négatif
      await db.query(
        "UPDATE stock SET quantite = ?, unite_code = ? WHERE utilisateur_id = ? AND ingredient_id = ?",
        [quantite, unite_code, utilisateur_id, ingredient_id]
      );
    } else {
      await db.query(
        "INSERT INTO stock (utilisateur_id, ingredient_id, quantite, unite_code) VALUES (?, ?, ?, ?)",
        [utilisateur_id, ingredient_id, Math.max(delta, 0), unite_code]
      );
    }

    // Enregistrer le mouvement
    await db.query(
      `INSERT INTO mvt_stock (utilisateur_id, ingredient_id, delta, unite_code, raison)
       VALUES (?, ?, ?, ?, ?)`,
      [utilisateur_id, ingredient_id, delta, unite_code, raison]
    );

    await db.query("COMMIT");

    res.status(201).json({
      message: "Mouvement enregistré",
      nouvelle_quantite: quantite
    });
  } catch (err) {
    await db.query("ROLLBACK");
    next(err);
  }
}

// ----------------------------------------------------
// PUT /stocks/:ingredient_id
// ----------------------------------------------------
async function update(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const utilisateur_id = req.user.id;
  const { ingredient_id } = req.params;
  const { quantite, unite_code, date_peremption } = req.body;

  try {
    const [result] = await db.query(`
      UPDATE stock 
      SET quantite = ?, 
          unite_code = COALESCE(?, unite_code),
          date_peremption = COALESCE(?, date_peremption)
      WHERE utilisateur_id = ? AND ingredient_id = ?
    `, [quantite, unite_code, date_peremption, utilisateur_id, ingredient_id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Ingrédient introuvable dans le stock" });
    }

    // Historiser la correction
    await db.query(`
      INSERT INTO mvt_stock (utilisateur_id, ingredient_id, delta, unite_code, raison)
      VALUES (?, ?, ?, ?, 'correction')
    `, [utilisateur_id, ingredient_id, 0, unite_code || ""]);

    res.json({ message: "Stock mis à jour" });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  getById,
  addMovement,
  update
};
