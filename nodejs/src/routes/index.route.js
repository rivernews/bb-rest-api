let express = require("express");
let router = express.Router();

router.get(`/`, (req, res) => {
    res.sendFile(path.join(__dirname, '../static/index.html'))
})

module.exports = router;