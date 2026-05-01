const { connect, signers } = require('@hyperledger/fabric-gateway');
const fs = require('fs-extra');
const path = require('path');
const crypto = require('crypto');
const grpc = require('@grpc/grpc-js');

// Configuration for Org1 - Matches fabric-service.js exactly
const mspId = 'Org1MSP';
const cryptoPath = path.resolve('..', 'fabric-samples', 'test-network', 'organizations', 'peerOrganizations', 'org1.example.com');
const keyPath = path.resolve(cryptoPath, 'users', 'User1@org1.example.com', 'msp', 'keystore');
const certPath = path.resolve(cryptoPath, 'users', 'User1@org1.example.com', 'msp', 'signcerts', 'cert.pem');
const tlsCertPath = path.resolve(cryptoPath, 'peers', 'peer0.org1.example.com', 'tls', 'ca.crt');
const peerEndpoint = 'localhost:7051';
const peerHostAlias = 'peer0.org1.example.com';

async function diagnose() {
    console.log('--- TLS DIAGNOSTIC START ---');
    console.log('📍 Current Directory:', process.cwd());
    console.log('📍 Peer Endpoint:', peerEndpoint);
    
    try {
        const tlsRootCert = await fs.readFile(tlsCertPath);
        const credentials = await fs.readFile(certPath);
        const files = await fs.readdir(keyPath);
        const keyFile = files.find(f => f.endsWith('_sk')) || files[0];
        const privateKeyPem = await fs.readFile(path.resolve(keyPath, keyFile));

        console.log('✅ Found TLS Root Cert:', tlsRootCert.length, 'bytes');
        console.log('✅ Found User Credentials:', credentials.length, 'bytes');

        // Test RAW gRPC connection to check the certificate presenting by server
        console.log('🔄 Attempting gRPC handshake...');
        const sslCreds = grpc.credentials.createSsl(tlsRootCert);
        const client = new grpc.Client(peerEndpoint, sslCreds, {
            'grpc.ssl_target_name_override': peerHostAlias,
        });

        const deadline = Date.now() + 5000;
        client.waitForReady(deadline, (err) => {
            if (err) {
                console.error('❌ gRPC handshake FAILED:', err.message);
                if (err.message.includes('unable to verify the first certificate')) {
                    console.log('💡 DIAGNOSIS: The CA certificate (ca.crt) does not trust the peer. This usually happens if the network was partially rebuilt but certificates on the host were not flushed.');
                }
            } else {
                console.log('🚀 gRPC handshake SUCCESS! Connection is healthy.');
                client.close();
            }
        });

    } catch (e) {
        console.error('❌ Initialization Error:', e.message);
    }
}

diagnose();
