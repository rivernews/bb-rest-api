// always import these for route js files
const express = require('express');
const router = express.Router();

// import controllers here
const diningHallController = require("../controllers/dining-hall.controller");

// register the route
router.get('/', diningHallController.listDiningHalls);

router.get('/:id', diningHallController.detailDiningHall);

router.post('/', diningHallController.createDiningHall);

router.patch('/:id', diningHallController.updateDiningHall);

router.delete('/:id', diningHallController.deleteDiningHall);

module.exports = router;