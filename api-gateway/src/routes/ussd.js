const express = require('express');
const router = express.Router();
const ussdController = require('../controllers/ussd-controller');

// Webhook endpoint for Africa's Talking USSD
router.post('/callback', ussdController.handleUSSDRequest);

module.exports = router;

module.exports = router;
