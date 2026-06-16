import { Http } from 'k6/experimental/tracing';
import { check, sleep } from 'k6';

export const options = {
  vus: 5,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

const TARGET_URL = __ENV.TARGET_URL || 'https://test-api.k6.io';

// Injects W3C traceparent header into every request so correlated traces
// appear in Tempo when the target service is OTel-instrumented
const http = new Http({
  propagator: 'w3c',
});

export default function () {
  const res = http.get(`${TARGET_URL}/`);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
