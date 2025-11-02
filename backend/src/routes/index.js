const express = require("express");
const authRoutes = require("./auth.routes");
const usersRoutes = require("./users.routes");
// const ingredientsRoutes = require("./ingredients.routes");
const recettesRoutes = require("./recettes.routes");
// const stocksRoutes = require("./stocks.routes");
// const listesRoutes = require("./listes.routes");
// const statsRoutes = require("./stats.routes");

const router = express.Router();

router.use("/auth", authRoutes);
router.use("/users", usersRoutes);
// router.use("/ingredients", ingredientsRoutes);
router.use("/recettes", recettesRoutes);
// router.use("/stocks", stocksRoutes);
// router.use("/listes", listesRoutes);
// router.use("/stats", statsRoutes);

module.exports = router;
