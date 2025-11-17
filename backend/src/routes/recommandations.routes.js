const express = require("express");
const { authRequired } = require("../middlewares/auth");
const controller = require("../controllers/recommandations.controller");

const router = express.Router();

router.get("/", authRequired, controller.list);

module.exports = router;
