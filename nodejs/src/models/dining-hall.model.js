let mongoose = require("mongoose");

let DiningHallSchema = new mongoose.Schema({
    name: String,
    address: {
        type: String,
        required: false
    }
})

module.exports = mongoose.model('DiningHall', DiningHallSchema);
