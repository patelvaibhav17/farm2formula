# Farm2Formula: Blockchain-Enabled Botanical Traceability

A decentralized supply chain solution for the Ayurvedic industry, ensuring transparency from the farm (raw herb collection) to the formula (finished product). Built with Hyperledger Fabric, Node.js (Express), and Flutter.

## 🏗️ Project Architecture

- **Blockchain Layer**: Hyperledger Fabric (Local test-network) for immutable audit trails.
- **Backend API Gateway**: Node.js Express server with Pinata IPFS integration and USSD handlers.
- **Frontend**: Flutter cross-platform mobile app (Offline-first with Hive).

---

## 🗄️ Data Storage Architecture

To ensure trust and scalability, data is distributed across three layers:

1. **Local Persistent Storage (Hive)**:
    - **Location**: `farm2formula/`
    - **Purpose**: Stores harvest batches locally on the device (offline-first). This ensures data is never lost, even in areas with no internet.

2. **Decentralized Files (IPFS)**:
    - **Location**: **Pinata IPFS Gateway**
    - **Purpose**: Large binary data like "Certificate of Analysis" (PDFs) and high-res harvest images. The blockchain stores only the 46-character "CID" (hash) pointing to these files.

3. **Immutable Ledger (Blockchain)**:
    - **Location**: **Hyperledger Fabric (WSL2)**
    - **Purpose**: The "Source of Truth." Stores batch metadata, ownership history, weights, and QA status. Once committed, this data is immutable.

---

## 🚀 Installation & Setup

### 1. Prerequisites

- **OS**: Windows with WSL2 (Ubuntu 22.04 recommended).
- **Docker**: Docker Desktop with **WSL2 based engine** enabled.
- **Node.js**: v18.17+ or v20+.
- **Flutter**: v3.10+ (Channel stable).

### 2. Hyperledger Fabric Setup (WSL2)

1. Navigate to the fabric samples directory in your **WSL2 terminal**:

    ```bash
    cd /mnt/d/Vaibhav/fabric-samples/test-network
    ```

2. Start the network with `mychannel`:

    ```bash
    ./network.sh up createChannel -c mychannel -ca
    ```

3. Deploy the chaincode (using the provided script in the root):

    ```bash
    cd /mnt/d/Vaibhav
    ./deploy_chaincode.sh
    ```

    > [!NOTE]
    > Current chaincode version is `v1.3`. If you make changes, increment the version in `./deploy_chaincode.sh`.

### 3. API Gateway Setup

1. Navigate to `d:/Vaibhav/api-gateway`.

2. Install dependencies:

    ```bash
    npm install
    ```

3. Configure Environment:
    - Rename `.env.example` to `.env`.
    - Add your `PINATA_JWT`, `PINATA_GATEWAY`, and `AT_API_KEY`.

4. Start the server:

    ```bash
    node index.js
    ```

### 4. Flutter Mobile App Setup

1. Navigate to `d:/Vaibhav/farm2formula`.

2. Install dependencies:

    ```bash
    flutter pub get
    ```

3. Generate Hive database adapters:

    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4. Run the app:

    ```bash
    flutter run
    ```

---

## 🗺️ Navigation & Feature Flow

### 👨‍🌾 Farmer Flow

- **Registration**: User registers via USSD (`*384#`) or App.
- **Harvest**: Logger inputs herb type, weight, and captures **Hardware GPS**.
- **Sync**: Tapping "Sync" pushes local Hive data to the Node.js Gateway.

### 🚚 Logistics Flow

- **Scan for Pickup**: QR scanner verifies origin on the blockchain.
- **Transfer**: Transaction records the change of ownership to the transporter.

### 🔬 Laboratory Flow

- **QA Results**: Automated check against botanical standards.
- **IPFS Upload**: CoA certificates are pinned to IPFS for transparency.

### 🛒 Consumer Flow

- **Lineage Verification**: Scan product lot to see the full timeline from the blockchain.

---

## 🧪 Manual Testing Steps

1. Stop everything and restart the API Gateway (`node index.js`).
2. Open the Flutter App (Harvesting Dashboard).
3. **Add a New Batch**: Input "Cotton" or "Soya" and tap **Capture GPS**.
4. **Perform Sync**: Wait for the "Synced" status icon to turn blue.
5. **View Blockchain Record**:
    - Open your browser to: `http://localhost:3000/api/v1/harvesting/batch/[BATCH_ID]`
    - Or use the **Consumer Timeline** in the app.

---

## 🛠️ Troubleshooting

- **"10 ABORTED" Error**: This usually means the chaincode didn't start. Redeploying specifically through WSL (`bash deploy_chaincode.sh`) fixes this.
- **Connection Refused (3000)**: Ensure `localhost` is used for Web/Desktop and `10.0.2.2` for Android Emulators in `sync_service.dart`.
- **Docker Errors**: Ensure the `test-network` is completely down before restarting (`./network.sh down`).
