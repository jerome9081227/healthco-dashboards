import { instrumentHTTP } from 'https://jslib.k6.io/http-instrumentation-tempo/1.0.0/index.js';
import http from 'k6/http';
import { check, sleep } from 'k6';

// Instrument the built-in http module with W3C traceparent header propagation
instrumentHTTP({ propagator: 'w3c' });

export const options = {
  vus: 5,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

const TARGET_URL = __ENV.TARGET_URL || 'https://test-api.k6.io';

export default function () {
  const res = http.get(`${TARGET_URL}/`);
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
