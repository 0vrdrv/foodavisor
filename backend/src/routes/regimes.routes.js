const express = require("express");
const router = express.Router();
const db = require("../config/db");
const { authRequired } = require("../middlewares/auth");

router.get("/", authRequired, async (req, res, next) => {
  try {
    const [rows] = await db.query(`SELECT id, code, libelle FROM regime ORDER BY libelle`);
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
