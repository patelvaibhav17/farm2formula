const express = require('express');
const router = express.Router();
const logisticsController = require('../controllers/logistics-controller');

router.post('/transfer', logisticsController.transferCustody);
router.post('/accept', logisticsController.acceptBatch);
router.post('/update-status', logisticsController.updateTransportStatus);
router.get('/batch/:batchId', logisticsController.getBatchStatus);

module.exports = router;
