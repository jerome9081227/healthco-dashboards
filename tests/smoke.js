// ⚠️ AI-GENERATED SCRIPT - REQUIRES MANUAL REVIEW ⚠️
// k6-assistant-provenance: {"sources":["manual"]}

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import tempo from 'https://jslib.k6.io/http-instrumentation-tempo/1.0.0/index.js';
import pyroscope from 'https://jslib.k6.io/http-instrumentation-pyroscope/1.0.1/index.js';

const BASE_URL = __ENV.TARGET_URL || 'http://localhost:6789';

export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 2,
      duration: '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

// Distributed tracing — propagates trace context to the service under test
tempo.instrumentHTTP({ propagator: 'w3c' });

export function setup() {
  pyroscope.instrumentHTTP(); // profiling — must be last in setup()
  return {};
}

export default function () {
  group('Health', function () {
    const res = http.get(`${BASE_URL}/health`, {
      tags: { name: 'GET /health' },
    });
    check(res, {
      'health: status 200': (r) => r.status === 200,
      'health: response < 500ms': (r) => r.timings.duration < 500,
    });
  });

  sleep(0.5);

  group('Orders', function () {
    // TODO: verify this path exists on your service
    const listRes = http.get(http.url`${BASE_URL}/api/v1/orders`, {
      tags: { name: 'GET /api/v1/orders' },
    });
    check(listRes, {
      'orders list: status 200': (r) => r.status === 200,
      'orders list: response < 500ms': (r) => r.timings.duration < 500,
    });

    sleep(0.5);

    // TODO: replace with a real request body — schema not inferred from current context
    const createRes = http.post(
      `${BASE_URL}/api/v1/orders`,
      JSON.stringify({
        customerId: 'customer-123', // TODO: parameterize with realistic IDs
        items: [],                   // TODO: replace with real item structure
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'POST /api/v1/orders' },
      }
    );
    check(createRes, {
      'create order: status 201': (r) => r.status === 201,
      'create order: response < 500ms': (r) => r.timings.duration < 500,
    });
  });

  sleep(1);
}
