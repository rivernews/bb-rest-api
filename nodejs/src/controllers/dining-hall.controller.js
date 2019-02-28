// import model
const DiningHall = require("../models/dining-hall.model");

// controller function (similar to dhango "views")
exports.listDiningHalls = function(req, res) {
    DiningHall.find(
        {},
        (err, diningHalls) => {
            if (err) {
                return next(err);
            }
            res.send(diningHalls);
        }
    );
}

exports.detailDiningHall = (req, res) => {
    DiningHall.findById(
        req.params.id,
        (err, diningHall) => {
            if (err) {
                return next(err);
            }
            res.send(diningHall);
        }
    )
}

exports.createDiningHall = (req, res) => {
    let diningHall = new DiningHall(
        {
            name: req.body.name,
            address: req.body.address,
        }
    );

    diningHall.save((err) => {
        if (err) {
            return next(err);
        }
        else {
            res.send("Dining Hall created successfully");
        }
    })
}

exports.updateDiningHall = (req, res) => {
    DiningHall.findByIdAndUpdate(
        req.params.id,
        {
            $set: req.body
        },
        (err, diningHall) => {
            if (err) {
                next(err);
            }
            res.send("Dining Hall updated.");
        }
    )
}

exports.deleteDiningHall = (req, res) => {
    DiningHall.findByIdAndDelete(
        req.params.id,
        (err, diningHall) => {
            if (err) {
                next(err);
            }
            res.send("Deleted successfully.");
        }
    )
}