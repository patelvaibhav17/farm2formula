'use strict';

const { Contract } = require('fabric-contract-api');

class TraceabilityContract extends Contract {

    _getTxDate(ctx) {
        const ts = ctx.stub.getTxTimestamp();
        let seconds = 0;
        if (ts.seconds.low !== undefined) {
            seconds = ts.seconds.low;
        } else if (typeof ts.seconds === 'object' && ts.seconds.toNumber) {
            seconds = ts.seconds.toNumber();
        } else {
            seconds = Number(ts.seconds);
        }
        return new Date(seconds * 1000).toISOString();
    }

    async initLedger(ctx) {
        console.log('============= START : Initialize Ledger ===========');
        const batches = [
            {
                batchId: 'BATCH000',
                herbName: 'Initial Seed Batch',
                farmerId: 'SYSTEM',
                harvestDate: this._getTxDate(ctx),
                location: '0,0',
                status: 'CREATED',
                docType: 'batch',
                owner: 'SYSTEM',
                timeline: []
            },
        ];

        for (const batch of batches) {
            await ctx.stub.putState(batch.batchId, Buffer.from(JSON.stringify(batch)));
        }
        console.log('============= END : Initialize Ledger ===========');
    }

    // 1. Farmer/Collector registers a harvested batch
    async mintRawBatch(ctx, batchId, herbName, farmerId, location, weight, harvestDate, metadata) {
        console.info('============= START : Mint Raw Batch ===========');

        const exists = await this.assetExists(ctx, batchId);
        if (exists) {
            throw new Error(`The batch ${batchId} already exists`);
        }

        const batch = {
            docType: 'batch',
            batchId,
            herbName,
            farmerId,
            location, // GPS coords
            weight,
            harvestDate,
            metadata, // Includes image CIDs from IPFS
            status: 'CREATED',     // ✅ Use CREATED (matches Flutter filter)
            owner: farmerId,
            timeline: [{
                status: 'CREATED',
                timestamp: harvestDate,
                user: farmerId,
                details: 'Batch registered at source'
            }]
        };

        await ctx.stub.putState(batchId, Buffer.from(JSON.stringify(batch)));
        console.info('============= END : Mint Raw Batch ===========');
    }

    // 2. State transition: Update Custody (Logistics)
    // ✅ Now accepts newStatus parameter to support PICKED, IN_TRANSIT, DELIVERED_TO_LAB
    async transferCustody(ctx, batchId, newOwner, newStatus) {
        const batchJSON = await ctx.stub.getState(batchId);
        if (!batchJSON || batchJSON.length === 0) {
            throw new Error(`The batch ${batchId} does not exist`);
        }

        const batch = JSON.parse(batchJSON.toString());
        batch.owner = newOwner;
        // Use the provided status, default to IN_TRANSIT for backward-compat
        batch.status = newStatus || 'IN_TRANSIT';
        batch.timeline.push({
            status: batch.status,
            timestamp: this._getTxDate(ctx),
            user: newOwner,
            details: `Custody transferred. Status: ${batch.status}`
        });

        await ctx.stub.putState(batchId, Buffer.from(JSON.stringify(batch)));
    }

    // 3. Lab results submission (✅ FIXED: submitQAResults - no typo)
    async submitQAResults(ctx, batchId, testerId, results, certificateCID) {
        const batchJSON = await ctx.stub.getState(batchId);
        if (!batchJSON || batchJSON.length === 0) {
            throw new Error(`The batch ${batchId} does not exist`);
        }

        const batch = JSON.parse(batchJSON.toString());

        // Automated AYUSH Compliance Check
        let parsedResults = {};
        try {
            parsedResults = typeof results === 'string' ? JSON.parse(results) : results;
        } catch (e) {
            parsedResults = { raw: results };
        }

        let compliant = true;
        // AYUSH limits: Pb<10, As<3, Hg<1, Cd<0.3
        if ((parsedResults.lead    || 0) > 10.0) compliant = false;
        if ((parsedResults.arsenic || 0) > 3.0)  compliant = false;
        if ((parsedResults.mercury || 0) > 1.0)  compliant = false;
        if ((parsedResults.cadmium || 0) > 0.3)  compliant = false;

        batch.qaStatus = compliant ? 'PASSED' : 'FAILED';
        batch.qaResults = parsedResults;
        batch.certificateCID = certificateCID;
        // ✅ VERIFIED = passed, QA_FAILED = failed (matches filter logic)
        batch.status = compliant ? 'VERIFIED' : 'QA_FAILED';

        batch.timeline.push({
            status: batch.status,
            timestamp: this._getTxDate(ctx),
            user: testerId,
            details: compliant
                ? 'All AYUSH heavy metal limits passed. Batch VERIFIED.'
                : 'Quality check FAILED: Contaminants exceed AYUSH permissible limits.'
        });

        await ctx.stub.putState(batchId, Buffer.from(JSON.stringify(batch)));
    }

    // Legacy alias for backward compatibility
    async submitQALesults(ctx, batchId, testerId, results, certificateCID) {
        return this.submitQAResults(ctx, batchId, testerId, results, certificateCID);
    }

    // 4. Query full history of a batch
    async getBatchHistory(ctx, batchId) {
        let resultsIterator = await ctx.stub.getHistoryForKey(batchId);
        let results = [];
        let res = await resultsIterator.next();
        while (!res.done) {
            if (res.value) {
                const obj = JSON.parse(res.value.value.toString('utf8'));
                results.push({
                    txId: res.value.txId,
                    timestamp: res.value.timestamp,
                    isDelete: res.value.isDelete,
                    value: obj
                });
            }
            res = await resultsIterator.next();
        }
        await resultsIterator.close();
        return JSON.stringify(results);
    }

    // 5. Create a finished product lot from multiple parent batches (Lineage Inheritance)
    async createProductLot(ctx, lotId, parentBatchIds, productType, manufacturerId, quantity) {
        const exists = await this.assetExists(ctx, lotId);
        if (exists) {
            throw new Error(`The product lot ${lotId} already exists`);
        }

        const parents = JSON.parse(parentBatchIds);
        const lot = {
            docType: 'productLot',
            lotId,
            parentBatchIds: parents,
            productType,
            manufacturerId,
            quantity,
            status: 'MANUFACTURED',
            owner: manufacturerId,
            timeline: [{
                status: 'MANUFACTURED',
                timestamp: this._getTxDate(ctx),
                user: manufacturerId,
                details: `Product lot created from parent batches: ${parentBatchIds}`
            }]
        };

        await ctx.stub.putState(lotId, Buffer.from(JSON.stringify(lot)));
    }

    async assetExists(ctx, assetId) {
        const assetJSON = await ctx.stub.getState(assetId);
        return assetJSON && assetJSON.length > 0;
    }

    // 6. Generic query to get all assets for dashboard populating
    async GetAllAssets(ctx) {
        const allResults = [];
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();

        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            try {
                const record = JSON.parse(strValue);
                if (record && record.docType) {
                    allResults.push(record);
                }
            } catch (err) {
                console.log(`Skipping non-JSON state item: ${strValue}`);
            }
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }
}

module.exports = TraceabilityContract;
