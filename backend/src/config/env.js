require("dotenv").config();

module.exports = {
  PORT: process.env.PORT || 10000,
  NODE_ENV: process.env.NODE_ENV || "development",

  DATABASE_URL: process.env.DATABASE_URL || "",
  REDIS_URL: process.env.REDIS_URL || "",

  STORAGE_PATH: process.env.STORAGE_PATH || "./storage",
};
