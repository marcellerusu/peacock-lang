const express = require("express");
const app = express();
const path = require("path");

const port = 3000;

app.use("/public", express.static("public"));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public/index.html"));
});

app.listen(port, () => {
  console.log(`Server listening on ${port}`);
});
