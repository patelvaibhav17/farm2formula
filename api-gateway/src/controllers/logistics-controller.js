const fabricService = require('../services/fabric-service');

/**
 * Transfer custody of a batch to a new owner
 * POST /api/v1/logistics/transfer
 */
const transferCustody = async (req, res) => {
    const { batchId, newOwner, details } = req.body;

    try {
        console.log(`🚚 Transferring custody of ${batchId} to ${newOwner}`);
        
        await fabricService.submitTransaction(
            'transferCustody',
            batchId,
            newOwner,
            details || 'Scan-based custody transfer'
        );

        res.status(200).json({
            status: 'success',
            message: `Batch ${batchId} custody transferred to ${newOwner}`,
        });
    } catch (error) {
        console.error('❌ Logistics Transfer Error:', error);
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
};

/**
 * Accept a batch for transport (transitions CREATED -> PICKED)
 * POST /api/v1/logistics/accept
 */
const acceptBatch = async (req, res) => {
    const { batchId, transporterId } = req.body;
    if (!batchId || !transporterId) {
        return res.status(400).json({ status: 'error', message: 'batchId and transporterId are required' });
    }
    try {
        console.log(`📦 Transporter ${transporterId} accepting batch ${batchId}`);
        await fabricService.submitTransaction(
            'transferCustody',
            batchId,
            transporterId,
            'PICKED'
        );
        res.status(200).json({ status: 'success', message: `Batch ${batchId} accepted by ${transporterId}` });
    } catch (error) {
        console.error('❌ AcceptBatch Error:', error);
        res.status(500).json({ status: 'error', message: error.message });
    }
};

/**
 * Update transport status (PICKED | IN_TRANSIT | DELIVERED_TO_LAB)
 * POST /api/v1/logistics/update-status
 */
const updateTransportStatus = async (req, res) => {
    const { batchId, newStatus, transporterId } = req.body;
    if (!batchId || !newStatus) {
        return res.status(400).json({ status: 'error', message: 'batchId and newStatus are required' });
    }
    try {
        console.log(`🚧 Updating batch ${batchId} to status ${newStatus}`);
        await fabricService.submitTransaction(
            'transferCustody',
            batchId,
            transporterId || 'TRANSPORTER',
            newStatus
        );
        res.status(200).json({ status: 'success', message: `Batch ${batchId} updated to ${newStatus}` });
    } catch (error) {
        console.error('❌ UpdateStatus Error:', error);
        res.status(500).json({ status: 'error', message: error.message });
    }
};

/**
 * Get batch status/history by batch ID
 * GET /api/v1/logistics/batch/:batchId
 */
const getBatchStatus = async (req, res) => {
    const { batchId } = req.params;
    try {
        const history = await fabricService.evaluateTransaction('getBatchHistory', batchId);
        res.status(200).json({ status: 'success', data: history });
    } catch (error) {
        res.status(404).json({ status: 'error', message: 'Batch not found' });
    }
};

module.exports = {
    transferCustody,
    acceptBatch,
    updateTransportStatus,
    getBatchStatus
};
