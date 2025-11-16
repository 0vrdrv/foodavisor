const express = require("express");
const authRoutes = require("./auth.routes");
const usersRoutes = require("./users.routes");
const ingredientsRoutes = require("./ingredients.routes");
const recettesRoutes = require("./recettes.routes");
const stocksRoutes = require("./stocks.routes");
const avisRoutes = require("./avis.routes");
const cuissonsRoutes = require("./cuissons.routes");
const listesRoutes = require("./listes.routes");
const statsRoutes = require("./stats.routes");
const preferencesRoutes = require("./preferences.routes");
const allergenesRoutes = require("./allergenes.routes");
const etapesRoutes = require("./etapes.routes");
const recommandationsRoutes = require("./recommandations.routes");
const searchRoutes = require("./search.routes");
const recettesIngredientsRoutes = require("./recettesIngredients.routes");
const categoriesRoutes = require("./categories.routes");
const unitesRoutes = require("./unites.routes");



const router = express.Router();

router.use("/auth", authRoutes);
router.use("/users", usersRoutes);
router.use("/ingredients", ingredientsRoutes);
router.use("/recettes", recettesRoutes);
router.use("/stocks", stocksRoutes);
router.use("/avis", avisRoutes);
router.use("/cuissons", cuissonsRoutes);
router.use("/listes", listesRoutes);
router.use("/stats", statsRoutes);
router.use("/preferences", preferencesRoutes);
router.use("/allergenes", allergenesRoutes);
router.use("/etapes", etapesRoutes);
router.use("/recommandations", recommandationsRoutes);
router.use("/search", searchRoutes);
router.use("/recettes-ingredients", recettesIngredientsRoutes);
router.use("/categories", categoriesRoutes);
router.use("/unites", unitesRoutes);



module.exports = router;
