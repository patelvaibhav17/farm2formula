const express = require('express');
const router = express.Router();
const harvestingController = require('../controllers/harvesting-controller');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + file.originalname);
    }
});
const upload = multer({ storage: storage });

router.post('/register', upload.single('image'), harvestingController.registerBatch);
router.get('/all', harvestingController.getAllBatches);
router.get('/by-status/:status', harvestingController.getBatchesByStatus);
router.get('/batch/:id', harvestingController.getBatch);

module.exports = router;
