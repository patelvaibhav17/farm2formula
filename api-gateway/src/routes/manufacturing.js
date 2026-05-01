const express = require('express');
const router = express.Router();
const manufacturingController = require('../controllers/manufacturing-controller');

router.post('/create-lot', manufacturingController.createProductLot);
router.get('/', manufacturingController.getAllLots);

module.exports = router;
