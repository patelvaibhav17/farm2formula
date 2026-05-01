const fabricService = require('../services/fabric-service');
const ipfsService = require('../services/ipfs-service');

/**
 * Submit QA test results for a batch
 * POST /api/v1/laboratory/submit
 */
const submitQAResults = async (req, res) => {
    const { batchId, testerId, results, certificateCID } = req.body;

    try {
        console.log(`🔬 Submitting QA Results for ${batchId}`);
        
        // ✅ Fixed typo: was 'submitQALesults' (broken)
        await fabricService.submitTransaction(
            'submitQAResults',
            batchId,
            testerId,
            JSON.stringify(results),
            certificateCID || 'QAMockCID'
        );

        res.status(200).json({
            status: 'success',
            message: `QA results recorded for ${batchId}`,
        });
    } catch (error) {
        console.error('❌ Laboratory QA Error:', error);
        res.status(500).json({ status: 'error', message: error.message });
    }
};

/**
 * Upload Certificate of Analysis to IPFS
 * POST /api/v1/laboratory/upload
 */
const uploadCertificate = async (req, res) => {
   if (!req.file) return res.status(400).send('No file uploaded.');
   
   try {
       const cid = await ipfsService.uploadFile(req.file.path, req.file.originalname);
       res.status(200).json({ status: 'success', cid });
   } catch (error) {
       res.status(500).json({ status: 'error', message: error.message });
   }
};

/**
 * Get all batches waiting for QA testing (status = DELIVERED_TO_LAB)
 * GET /api/v1/laboratory/pending
 */
const getPendingBatches = async (req, res) => {
    try {
        const result = await fabricService.evaluateTransaction('GetAllAssets');
        const all = Array.isArray(result) ? result : [];
        // Include both raw batches that are DELIVERED and those still as CREATED (for demo)
        const pending = all.filter(a =>
            a.status === 'DELIVERED_TO_LAB' ||
            a.Status === 'DELIVERED_TO_LAB'
        );
        res.status(200).json({ status: 'success', data: pending });
    } catch (error) {
        console.error('❌ GetPendingBatches Error:', error);
        res.status(500).json({ status: 'error', message: error.message });
    }
};

module.exports = {
    submitQAResults,
    uploadCertificate,
    getPendingBatches
};
