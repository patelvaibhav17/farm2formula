const fabricService = require('../services/fabric-service');

const createProductLot = async (req, res) => {
    const { lotId, parentBatchIds, productType, manufacturerId, quantity } = req.body;

    try {
        console.log(`🏭 Manufacturing Product Lot: ${lotId} from batches: ${parentBatchIds}`);

        // In the chaincode, this will link the parent batches to the new product lot
        // establishing the ultimate lineage
        await fabricService.submitTransaction(
            'createProductLot', // This should be added to chaincode if not present
            lotId,
            JSON.stringify(parentBatchIds),
            productType,
            manufacturerId,
            quantity.toString()
        );

        res.status(200).json({
            status: 'success',
            message: `Product Lot ${lotId} created successfully.`,
        });
    } catch (error) {
        console.error('❌ Manufacturing Error:', error);
        res.status(500).json({ status: 'error', message: error.message });
    }
};

const getAllLots = async (req, res) => {
    try {
        console.log('📦 Fetching all Manufactured Product Lots...');
        const result = await fabricService.evaluateTransaction('GetAllAssets');
        
        let all = [];
        if (Array.isArray(result)) {
            all = result;
        } else if (typeof result === 'string') {
            try { all = JSON.parse(result); } catch(e) { all = []; }
        }

        const lots = all
            .filter(asset => asset.docType === 'productLot')
            .map(l => ({
                ...l,
                lotId: l.lotId || l.id || l.ID || 'Unknown'
            }));

        res.status(200).json({
            status: 'success',
            data: lots,
        });
    } catch (error) {
        console.error('❌ Fetch Lots Error:', error.message);
        res.status(200).json({ status: 'success', data: [], warning: error.message });
    }
};

module.exports = {
    createProductLot,
    getAllLots
};
