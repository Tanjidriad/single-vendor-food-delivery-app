const { MapsService } = require('./dist/src/modules/delivery-fee/maps.service.js');
require('dotenv').config();

// Mock ConfigService
class MockConfigService {
  get(key) {
    if (key === 'googleMapsApiKey') return null; // Force fallback to Mapbox for testing
    if (key === 'mapboxAccessToken') return process.env.MAPBOX_ACCESS_TOKEN; 
    return null;
  }
}

async function run() {
  const mapsService = new MapsService(new MockConfigService());
  
  console.log("--- Testing Mapbox Geocoding (Mirpur 10, Dhaka) ---");
  try {
    const res = await mapsService.geocode("Mirpur 10, Dhaka");
    console.log(res);
  } catch(e) {
    console.log("Error:", e.message);
  }

  console.log("\n--- Testing Mapbox Routing Matrix (Dhaka to Gazipur) ---");
  try {
    const res = await mapsService.getRouteQuote(23.81, 90.41, 23.99, 90.42);
    console.log(res);
  } catch(e) {
    console.log("Error:", e.message);
  }
}

run();
