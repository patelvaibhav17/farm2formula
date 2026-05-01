const { connect, signers } = require('@hyperledger/fabric-gateway');
const fs = require('fs-extra');
const path = require('path');
const crypto = require('crypto');
const grpc = require('@grpc/grpc-js');

// Configuration for Org1
const mspId = 'Org1MSP';
const cryptoPath = path.resolve(__dirname, '..', '..', '..', 'fabric-samples', 'test-network', 'organizations', 'peerOrganizations', 'org1.example.com');
const keyPath = path.resolve(cryptoPath, 'users', 'User1@org1.example.com', 'msp', 'keystore');
const certPath = path.resolve(cryptoPath, 'users', 'User1@org1.example.com', 'msp', 'signcerts', 'cert.pem');
const tlsCertPath = path.resolve(cryptoPath, 'peers', 'peer0.org1.example.com', 'tls', 'ca.crt');
const peerEndpoint = 'localhost:7051';
const peerHostAlias = 'peer0.org1.example.com';

class FabricService {
    constructor() {
        this.gateway = null;
        this.network = null;
        this.contract = null;
    }

    async init(retryCount = 0) {
        if (this.gateway) return;

        console.log(`🔗 Connecting to Hyperledger Fabric (Attempt ${retryCount + 1}/5)...`);
        
        try {
            // Check if certs exist before reading
            if (!await fs.pathExists(tlsCertPath) || !await fs.pathExists(certPath) || !await fs.pathExists(keyPath)) {
                throw new Error('Certificates not found yet');
            }

            const tlsRootCert = await fs.readFile(tlsCertPath);
            const credentials = await fs.readFile(certPath);
            const files = await fs.readdir(keyPath);
            const keyFile = files.find(f => f.endsWith('_sk')) || files[0];
            const privateKeyPem = await fs.readFile(path.resolve(keyPath, keyFile));
            
            const client = await this.newGrpcConnection(tlsRootCert);
            
            this.gateway = connect({
                client,
                identity: { mspId, credentials },
                signer: signers.newPrivateKeySigner(crypto.createPrivateKey(privateKeyPem)),
                evaluateOptions: () => ({ deadline: Date.now() + 5000 }),
                submitOptions: () => ({ deadline: Date.now() + 30000 }),
            });

            this.network = this.gateway.getNetwork('mychannel');
            this.contract = this.network.getContract('farm2formula');
            
            console.log('✅ Fabric Gateway initialized successfully');
        } catch (err) {
            if (retryCount < 5) {
                console.warn(`⏳ Fabric files not ready or connection failed, retrying in 2s... (${err.message})`);
                await new Promise(resolve => setTimeout(resolve, 2000));
                return this.init(retryCount + 1);
            }
            console.error('❌ Failed to initialize Fabric after multiple attempts:', err.message);
            throw err;
        }
    }

    async newGrpcConnection(tlsRootCert) {
        return new grpc.Client(peerEndpoint, grpc.credentials.createSsl(tlsRootCert), {
            'grpc.ssl_target_name_override': peerHostAlias,
            'grpc.default_authority': peerHostAlias,
            'grpc.keepalive_time_ms': 120000,
            'grpc.http2.min_time_between_pings_ms': 120000,
            'grpc.keepalive_timeout_ms': 20000,
            'grpc.http2.max_pings_without_data': 0,
            'grpc.keepalive_permit_without_calls': 1,
        });
    }

    async submitTransaction(functionName, ...args) {
        await this.init();
        try {
            console.log(`📡 [Fabric] Submitting: ${functionName}`, args);
            const result = await this.contract.submitTransaction(functionName, ...args);
            if (!result || result.length === 0) return null;
            // The result is a Uint8Array in the new fabric-gateway SDK
            const str = new TextDecoder().decode(result);
            try {
                return str.trim() ? JSON.parse(str) : null;
            } catch (e) {
                console.warn('⚠️ submitTransaction result is not JSON:', str.substring(0, 100));
                return str;
            }
        } catch (err) {
            if (err.details && err.details.length > 0) {
                console.error('❌ [Fabric Error Details]:', JSON.stringify(err.details, null, 2));
            }
            throw err;
        }
    }

    async evaluateTransaction(functionName, ...args) {
        await this.init();
        try {
            console.log(`🔍 [Fabric] Evaluating: ${functionName}`, args);
            const result = await this.contract.evaluateTransaction(functionName, ...args);
            if (!result || result.length === 0) return null;
            // The result is a Uint8Array in the new fabric-gateway SDK
            const str = new TextDecoder().decode(result);
            try {
                return str.trim() ? JSON.parse(str) : null;
            } catch (e) {
                console.warn('⚠️ evaluateTransaction result is not JSON:', str.substring(0, 100));
                return str;
            }
        } catch (err) {
            if (err.details && err.details.length > 0) {
                console.error('❌ [Fabric Error Details]:', JSON.stringify(err.details, null, 2));
            }
            throw err;
        }
    }
}

module.exports = new FabricService();
