const express = require("express");
const cors = require("cors");

const routes = require("./routes");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Superior backend running");
});

app.use("/api", routes);

module.exports = app;
