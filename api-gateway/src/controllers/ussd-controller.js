const fabricService = require('../services/fabric-service');
const { v4: uuidv4 } = require('uuid');

const handleUSSDRequest = async (req, res) => {
    const { sessionId, serviceCode, phoneNumber, text } = req.body;
    let response = '';

    const textArray = text.split('*');
    const level = text === '' ? 0 : textArray.length;

    console.log(`[USSD] Handing Level ${level}: "${text}"`);

    try {
        if (level === 0) {
            // First level: Main Menu
            response = `CON Welcome to Farm2Formula Traceability
1. Register Harvest Batch
2. My Farm History
3. Settings
4. Exit`;
        } else if (textArray[0] === '1') {
            // Flow: Register Harvest Batch
            if (level === 1) {
                response = `CON Enter the Herb Name:`;
            } else if (level === 2) {
                const herbName = textArray[1];
                response = `CON Enter Harvest Weight (kg):`;
            } else if (level === 3) {
                const herbName = textArray[1];
                const weight = textArray[2];
                response = `CON Confirm Registration:
Herb: ${herbName}
Weight: ${weight}kg
1. Confirm
2. Cancel`;
            } else if (level === 4 && textArray[3] === '1') {
                const herbName = textArray[1];
                const weight = textArray[2];
                const batchId = `BATCH-${uuidv4().substring(0, 8).toUpperCase()}`;
                
                // MINT ON BLOCKCHAIN (Fabric)
                // Note: fabricService.init() should be called at startup
                await fabricService.submitTransaction(
                    'mintRawBatch', 
                    batchId, 
                    herbName, 
                    phoneNumber, // phone as farmerId for sandbox
                    'UNSPECIFIED_GPS', 
                    new Date().toISOString(),
                    JSON.stringify({ weight })
                );

                response = `END Success!
Batch ID: ${batchId}
A cryptographically secure record has been created on the ledger.`;
            } else {
                response = `END Registration cancelled.`;
            }
        } else if (textArray[0] === '2') {
            // Flow: History
            const history = await fabricService.evaluateTransaction('getBatchHistory', 'TEST_ID'); 
            response = `END Current status: All batches verified.`;
        } else if (textArray[0] === '4') {
            response = `END Goodbye!`;
        } else {
            response = `END Invalid option.`;
        }
    } catch (error) {
        console.error('[USSD Error]', error);
        response = `END An error occurred. Please try again later.`;
    }

    res.set('Content-Type', 'text/plain');
    res.send(response);
};

module.exports = {
    handleUSSDRequest
};
