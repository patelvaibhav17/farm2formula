const fabricService = require('../services/fabric-service');
const ipfsService = require('../services/ipfs-service');

/**
 * Register a new harvest batch on the blockchain
 * POST /api/v1/harvesting/register
 */
exports.registerBatch = async (req, res) => {
    try {
        const { batchId, herbName, farmerId, location, weight, harvestDate } = req.body;
        let metadata = req.body.metadata;

        if (!batchId || !herbName || !farmerId) {
            return res.status(400).json({ status: 'error', message: 'Missing required fields' });
        }

        let parsedMetadata = {};
        if (metadata) {
            try {
                parsedMetadata = typeof metadata === 'string' ? JSON.parse(metadata) : metadata;
            } catch (e) {
                console.warn('Metadata parsing failed, using directly');
            }
        }

        // Handle uploaded image
        if (req.file) {
            try {
                // Upload to IPFS
                const cid = await ipfsService.uploadFile(req.file.path, req.file.filename);
                parsedMetadata.ipfsImageHash = cid;
                parsedMetadata.localImagePath = `/uploads/${req.file.filename}`;
            } catch (ipfsErr) {
                console.warn('⚠️ [HarvestingController] IPFS upload failed, saving local path only:', ipfsErr.message);
                parsedMetadata.localImagePath = `/uploads/${req.file.filename}`;
            }
        }

        // Call Fabric Smart Contract
        // mintRawBatch(ctx, batchId, herbName, farmerId, location, weight, harvestDate, metadata)
        const result = await fabricService.submitTransaction(
            'mintRawBatch',
            batchId,
            herbName,
            farmerId,
            location || 'Unknown',
            weight.toString(),
            harvestDate,
            JSON.stringify(parsedMetadata)
        );

        res.status(201).json({
            status: 'success',
            message: 'Batch registered successfully on blockchain',
            data: result
        });
    } catch (err) {
        // If the batch already exists, consider it a successful sync
        if (err.message && err.message.includes('already exists')) {
            const safeBatchId = req.body && req.body.batchId ? req.body.batchId : 'unknown';
            console.log(`⚠️ [HarvestingController] Batch ${safeBatchId} already exists, returning 200 OK.`);
            return res.status(200).json({ status: 'success', message: 'Batch already exists on blockchain' });
        }

        console.error('❌ [HarvestingController] Error:', err.message);
        res.status(500).json({ status: 'error', message: err.message });
    }
};

/**
 * Get batch details by ID
 * GET /api/v1/harvesting/batch/:id
 */
exports.getBatch = async (req, res) => {
    try {
        const result = await fabricService.evaluateTransaction('getBatchHistory', req.params.id);
        res.status(200).json({ status: 'success', data: result });
    } catch (err) {
        res.status(500).json({ status: 'error', message: err.message });
    }
};

/**
 * Get ALL assets from the blockchain ledger
 * GET /api/v1/harvesting/all
 */
exports.getAllBatches = async (req, res) => {
    try {
        const result = await fabricService.evaluateTransaction('GetAllAssets');
        // result may be a JSON string or already parsed array
        let batches = [];
        if (Array.isArray(result)) {
            batches = result;
        } else if (typeof result === 'string') {
            try { batches = JSON.parse(result); } catch(e) { batches = []; }
        }

        // Standardize: Ensure every batch has 'batchId' (UI compatibility)
        const standardized = batches.map(b => ({
            ...b,
            batchId: b.batchId || b.id || b.ID || 'Unknown'
        }));

        res.status(200).json({ status: 'success', data: standardized });
    } catch (err) {
        console.error('❌ [HarvestingController] GetAll Error:', err.message);
        // Return empty array instead of crashing the app
        res.status(200).json({ status: 'success', data: [], warning: err.message });
    }
};

/**
 * Get batches filtered by status
 * GET /api/v1/harvesting/by-status/:status
 * Supports: CREATED | PICKED | IN_TRANSIT | DELIVERED_TO_LAB | VERIFIED | QA_FAILED | MANUFACTURED
 * HARVESTED is treated as alias for CREATED (backward compat with old chaincode data)
 */
exports.getBatchesByStatus = async (req, res) => {
    try {
        const { status } = req.params;
        const result = await fabricService.evaluateTransaction('GetAllAssets');

        // Normalize result (may be already parsed or may be a JSON string)
        let all = [];
        if (Array.isArray(result)) {
            all = result;
        } else if (typeof result === 'string') {
            try { all = JSON.parse(result); } catch(e) { all = []; }
        }

        const statusAliases = {
            'CREATED': ['CREATED', 'HARVESTED'],
        };
        const matchStatuses = statusAliases[status] || [status];

        const filtered = all
            .filter(a => {
                const assetStatus = a.status || a.Status || '';
                return matchStatuses.includes(assetStatus);
            })
            .map(a => ({
                ...a,
                batchId: a.batchId || a.id || a.ID || 'Unknown'
            }));

        res.status(200).json({ status: 'success', data: filtered });
    } catch (err) {
        console.error('❌ [HarvestingController] GetByStatus Error:', err.message);
        // Return empty array instead of crashing the app
        res.status(200).json({ status: 'success', data: [], warning: err.message });
    }
};
