const { PinataSDK } = require("pinata-web3");
const fs = require("fs");

class IpfsService {
    constructor() {
        this.pinata = new PinataSDK({
            pinataJwt: process.env.PINATA_JWT,
            pinataGateway: process.env.PINATA_GATEWAY,
        });
    }

    async uploadFile(filePath, fileName) {
        try {
            console.log(`📤 Uploading ${fileName} to IPFS...`);
            const blob = new Blob([fs.readFileSync(filePath)]);
            const file = new File([blob], fileName, { type: "image/png" });
            
            const upload = await this.pinata.upload.file(file);
            console.log(`✅ IPFS CID: ${upload.IpfsHash}`);
            return upload.IpfsHash;
        } catch (error) {
            console.error("❌ IPFS Upload Error:", error);
            throw error;
        }
    }

    async uploadJSON(metadata) {
        try {
            const upload = await this.pinata.upload.json(metadata);
            return upload.IpfsHash;
        } catch (error) {
            console.error("❌ IPFS JSON Upload Error:", error);
            throw error;
        }
    }
}

module.exports = new IpfsService();
