const express = require('express');
process.env.GRPC_SSL_CIPHER_SUITES = 'HIGH+ECDSA';
const cors = require('cors');
const dotenv = require('dotenv');
const bodyParser = require('body-parser');

// Load env vars
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes (To be implemented)
// const farmerRoutes = require('./src/routes/farmer');
const logisticsRoutes = require('./src/routes/logistics');
const laboratoryRoutes = require('./src/routes/laboratory');
const manufacturingRoutes = require('./src/routes/manufacturing');
const harvestingRoutes = require('./src/routes/harvesting');
const ussdRoutes = require('./src/routes/ussd');

// app.use('/api/v1/farmer', farmerRoutes);
app.use('/api/v1/logistics', logisticsRoutes);
app.use('/api/v1/laboratory', laboratoryRoutes);
app.use('/api/v1/manufacturing', manufacturingRoutes);
app.use('/api/v1/harvesting', harvestingRoutes);
app.use('/api/v1/ussd', ussdRoutes); // For Africa's Talking

const fabricService = require('./src/services/fabric-service');

// Basic health check
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'success', message: 'Farm2Formula API Gateway is running' });
});

// Start server
app.listen(port, async () => {
    console.log(`🚀 API Gateway running on http://localhost:${port}`);
    try {
        await fabricService.init();
    } catch (err) {
        console.error('❌ Failed to connect to Fabric:', err.message);
    }
});
