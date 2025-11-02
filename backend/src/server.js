const app = require("./app");
const dotenv = require("dotenv");
const db = require("./config/db");

dotenv.config();

const PORT = process.env.PORT || 4000;

async function start() {
  try {
    await db.query("SELECT 1");
    console.log("✅ Connexion MySQL OK");

    app.listen(PORT, () => {
      console.log(`🚀 API FoodAdvisor lancée sur http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error("❌ Erreur connexion MySQL :", err);
    process.exit(1);
  }
}

start();
