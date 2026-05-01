const express = require('express');
const router = express.Router();
const laboratoryController = require('../controllers/laboratory-controller');
const upload = require('../middleware/upload');

router.get('/pending', laboratoryController.getPendingBatches);
router.post('/submit', laboratoryController.submitQAResults);
router.post('/upload', upload.single('certificate'), laboratoryController.uploadCertificate);

module.exports = router;
