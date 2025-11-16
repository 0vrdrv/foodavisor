const express = require("express");
const { authRequired } = require("../middlewares/auth");
const controller = require("../controllers/search.controller");

const router = express.Router();

router.get("/recettes", authRequired, controller.searchRecettes);

module.exports = router;
