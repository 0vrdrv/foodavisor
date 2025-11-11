const express = require("express");
const controller = require("../controllers/stats.controller");
const { authRequired, requireRole } = require("../middlewares/auth");

const router = express.Router();

router.get("/user", authRequired, controller.userStats);

router.get("/global", authRequired, requireRole("ADMIN"), controller.globalStats);

module.exports = router;
