let express = require("express");
let bodyParser = require("body-parser");

require('dotenv').config({
    path: "credentials.env"
});

let path = require("path");

// import external js
let exampleRoute = require("./routes/example-route");
let indexRoute = require("./routes/index.route");
let diningHallRoute = require("./routes/dining-hall.route");


let app = express();
const PORT = process.env.PORT || 3000;


// middlewares
app.use(express.static('static'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended: false
}));

// register route
app.use(exampleRoute);
app.use('/dining-halls', diningHallRoute);
app.use('/', indexRoute);

// last middleware will handle error page
app.use((req, res, next) => {
    res.status(404).send("404: Oh-oh, no no no such page.");
})
// handle 500
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.sendFile(path.join(__dirname, '../static/500.html'))
})



// setup database
const mongoose = require("mongoose");
let mongoDB = process.env.MONGODB_URI;
mongoose.connect(mongoDB, { useNewUrlParser: true });
mongoose.Promise = global.Promise;
let db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));




app.listen(PORT, () => {
    console.log(`== Checking environment variable ==`);
    console.log(`PORT: ${PORT}, DB: ${process.env.MONGODB_URI}`);
    console.info(`Hey, server is running & listening on http://localhost:${PORT}`);
})