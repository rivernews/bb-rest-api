let express = require("express");
let router = express.Router();

router.get('/example', (req, res) => {
    // you can also pass param in url (for GET)
    if (req.query.someQueryKeyName) {
        res.send(`You've requested /example with a query key "someQueryKeyName" value: ${req.query.someQueryKeyName}`);
    }
    else {
        res.send("You have requested /example");
    }
});

router.get(`/example/:objectID`, (req, res) => {
    res.send(`You've request /example with parameter ${req.params.objectID}`)
})

router.get(`/error`, (req, res) => {
    throw new Error("Error: this is an example triggering a 500 server error.");
})

module.exports = router;