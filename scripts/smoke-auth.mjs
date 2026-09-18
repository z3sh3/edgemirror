import worker from "../src/index.js";

const BASE_URL = "https://edge.example.com";
const TOKEN = "smoke-configured-token";
const ENV = { AUTH_TOKEN: TOKEN };

const realFetch = globalThis.fetch;
const fetchCalls = [];

// Controlled upstream: registries challenge anonymous calls with a Bearer realm,
// auth.docker.io issues an anonymous token, and the registry serves the manifest
// once a valid bearer is attached.
globalThis.fetch = async (input, init = {}) => {
  const request = input instanceof Request ? input : new Request(input, init);
  fetchCalls.push({
    authorization: request.headers.get("authorization"),
    cache: init.cache,
    method: request.method,
    url: request.url,
  });

  if (request.url.startsWith("https://registry-1.docker.io/")) {
    if (request.headers.get("authorization") === "Bearer upstream-anonymous-token") {
      return new Response("docker-manifest-payload", {
        headers: { "Content-Type": "application/vnd.oci.image.manifest.v1+json" },
      });
    }
    return new Response("unauthorized", {
      status: 401,
      headers: {
        "Www-Authenticate":
          'Bearer realm="https://auth.docker.io/token",service="registry.docker.io",scope="repository:library/nginx:pull"',
      },
    });
  }

  if (request.url.startsWith("https://auth.docker.io/token")) {
    return jsonResponse({ token: "upstream-anonymous-token", expires_in: 300 });
  }

  if (request.url === "https://s3.amazonaws.com/example-blob") {
    return new Response("blob-bytes");
  }

  return new Response("repository-payload", {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
};

try {
  await runAuthDisabledCompatibility();
  await runPublicPathsStayPublic();
  await runProtectedRoutesRequireToken();
  await runTokenCarriers();
  await runCredentialSanitization();
  await runDockerAuthFlow();
  console.log("ok auth gate, token carriers, credential sanitization, and docker token flow");
} finally {
  globalThis.fetch = realFetch;
}

async function runAuthDisabledCompatibility() {
  const response = await worker.fetch(new Request(`${BASE_URL}/repo/debian/dists/stable/InRelease`));
  assert(response.status === 200, "auth disabled: repository route should work without a token");
  assert(fetchCalls.length === 1, "auth disabled: exactly one upstream call expected");
  fetchCalls.length = 0;
  console.log("ok auth disabled keeps legacy behaviour");
}

async function runPublicPathsStayPublic() {
  // Only health probes and ads.txt stay open while the gate is enabled.
  for (const path of ["/health", "/healthz", "/__health", "/ads.txt"]) {
    const response = await worker.fetch(new Request(`${BASE_URL}${path}`), ENV);
    assert(response.status === 200, `health/ads path should stay open: ${path} (got ${response.status})`);
  }
  assert(fetchCalls.length === 0, "public paths must not trigger upstream calls");

  const health = await worker.fetch(new Request(`${BASE_URL}/health`), ENV);
  const healthBody = await health.json();
  assert(healthBody.auth?.enabled === true, "health should report auth enabled");

  fetchCalls.length = 0;
  console.log("ok health and ads.txt stay public without a token");

  // Every UI page and data route now requires the token.
  const nowProtected = [
    "/",
    "/edgemirror",
    "/help",
    "/catalog",
    "/pypi",
    "/hf",
    "/github",
    "/docker",
    "/mirrors",
    "/proxy",
    "/npm",
    "/go",
    "/maven",
    "/crates",
    "/downloads",
  ];

  for (const path of nowProtected) {
    const denied = await worker.fetch(new Request(`${BASE_URL}${path}`), ENV);
    assert(denied.status === 401, `UI page should reject without a token: ${path} (got ${denied.status})`);

    const granted = await worker.fetch(new Request(`${BASE_URL}${path}`, {
      headers: { Authorization: basicAuth(TOKEN, "anything") },
    }), ENV);
    assert(granted.status === 200, `UI page should render with a token: ${path} (got ${granted.status})`);
  }

  assert(fetchCalls.length === 0, "UI pages must not trigger upstream calls");
  console.log(`ok ${nowProtected.length} UI pages require the token`);
}

async function runProtectedRoutesRequireToken() {
  const protectedPaths = [
    "/repo/debian/dists/stable/InRelease",
    "/pypi/simple/",
    "/proxy/https://nodejs.org/dist/x/example.msi",
    "/v2/",
    "/docker/v2/library/nginx/manifests/latest",
    "/npm/lodash",
    "/go/github.com/example/mod/@v/list",
    "/pkg/npm/is-number",
    "/oci/docker/v2/library/nginx/manifests/latest",
    "/git/github/vercel/next.js.git/info/refs?service=git-upload-pack",
    "/token?service=registry.docker.io",
  ];

  for (const path of protectedPaths) {
    fetchCalls.length = 0;
    const response = await worker.fetch(new Request(`${BASE_URL}${path}`), ENV);
    assert(response.status === 401, `protected route must reject without a token: ${path} (got ${response.status})`);
    assert(fetchCalls.length === 0, `protected route must not call upstream without a token: ${path}`);
    assert(response.headers.get("www-authenticate"), `401 should carry a WWW-Authenticate challenge: ${path}`);
  }

  console.log(`ok ${protectedPaths.length} protected routes reject missing tokens`);
}

async function runTokenCarriers() {
  const url = `${BASE_URL}/repo/debian/dists/stable/InRelease`;

  const cases = [
    { name: "Bearer header", headers: { Authorization: `Bearer ${TOKEN}` } },
    { name: "Basic username", headers: { Authorization: basicAuth(TOKEN, "anything") } },
    { name: "Basic password", headers: { Authorization: basicAuth("edgemirror", TOKEN) } },
    { name: "X-Auth-Token header", headers: { "X-Auth-Token": TOKEN } },
    { name: "query parameter", query: `?token=${TOKEN}` },
  ];

  for (const testCase of cases) {
    fetchCalls.length = 0;
    const target = `${url}${testCase.query ?? ""}`;
    const response = await worker.fetch(new Request(target, { headers: testCase.headers }), ENV);
    await response.arrayBuffer();
    assert(
      response.status === 200,
      `${testCase.name} should authenticate (got ${response.status})`,
    );
  }
  console.log(`ok ${cases.length} token carriers accepted`);

  const rejected = [
    { name: "wrong Bearer", headers: { Authorization: "Bearer nope" } },
    { name: "wrong Basic user+pass", headers: { Authorization: basicAuth("nope", "nope") } },
    { name: "wrong query token", query: "?token=nope" },
  ];
  for (const testCase of rejected) {
    fetchCalls.length = 0;
    const response = await worker.fetch(
      new Request(`${url}${testCase.query ?? ""}`, { headers: testCase.headers }),
      ENV,
    );
    assert(response.status === 401, `${testCase.name} should be rejected (got ${response.status})`);
  }
  console.log(`ok ${rejected.length} wrong tokens rejected`);
}

async function runCredentialSanitization() {
  // The mirror token must never reach an upstream, and the ?token= query
  // parameter must be removed before any upstream URL is built.
  fetchCalls.length = 0;
  const authorized = await worker.fetch(
    new Request(`${BASE_URL}/repo/debian/dists/stable/InRelease?channel=stable&token=${TOKEN}`, {
      headers: { Authorization: `Bearer ${TOKEN}`, "X-Auth-Token": TOKEN },
    }),
    ENV,
  );
  await authorized.arrayBuffer();
  assert(authorized.status === 200, "authorized repository request should succeed");
  assert(fetchCalls.length === 1, "exactly one upstream call expected");
  assert(
    fetchCalls[0].url === "https://deb.debian.org/debian/dists/stable/InRelease?channel=stable",
    `query token must be stripped before upstream: ${fetchCalls[0].url}`,
  );
  assert(
    !fetchCalls[0].authorization && !fetchCalls[0].url.includes("token"),
    "mirror credentials must not reach the upstream",
  );
  console.log("ok credentials and token query stripped before upstream");

  // auth disabled: query token must pass through untouched (legacy behaviour)
  fetchCalls.length = 0;
  const legacy = await worker.fetch(
    new Request(`${BASE_URL}/repo/debian/dists/stable/InRelease?channel=stable&token=legacy-value`),
  );
  await legacy.arrayBuffer();
  assert(
    fetchCalls[0]?.url === "https://deb.debian.org/debian/dists/stable/InRelease?channel=stable&token=legacy-value",
    "auth disabled must preserve the query string",
  );
  fetchCalls.length = 0;
  console.log("ok auth disabled preserves query string");
}

async function runDockerAuthFlow() {
  // docker login handshake: the /token endpoint issues the mirror token itself,
  // without contacting auth.docker.io.
  fetchCalls.length = 0;
  const tokenResponse = await worker.fetch(
    new Request(`${BASE_URL}/docker/token?service=registry.docker.io&scope=repository:library/nginx:pull`, {
      headers: { Authorization: basicAuth(TOKEN, "anything") },
    }),
    ENV,
  );
  const tokenBody = await tokenResponse.json();
  assert(tokenResponse.status === 200, "docker token endpoint should succeed with auth");
  assert(tokenBody.token === TOKEN, "docker token endpoint must issue the configured token");
  assert(tokenBody.access_token === TOKEN, "docker token endpoint must expose access_token");
  assert(
    fetchCalls.every((call) => !call.url.startsWith("https://auth.docker.io")),
    "synthetic token path must not call auth.docker.io",
  );
  console.log("ok docker token endpoint issues the local token");

  // manifest request with the issued token as Bearer: never forwarded upstream.
  // Runs before the ping so the upstream challenge realm is exercised for real.
  fetchCalls.length = 0;
  const manifest = await worker.fetch(
    new Request(`${BASE_URL}/v2/library/nginx/manifests/latest`, {
      headers: { Authorization: `Bearer ${TOKEN}` },
    }),
    ENV,
  );
  const manifestBody = await manifest.text();
  assert(manifest.status === 200, `docker manifest should stream (got ${manifest.status})`);
  assert(manifestBody === "docker-manifest-payload", "docker manifest body mismatch");
  assert(
    fetchCalls.every((call) => call.authorization !== `Bearer ${TOKEN}`),
    "the mirror token must never be forwarded to registry-1.docker.io",
  );
  assert(
    fetchCalls.some((call) => call.authorization === "Bearer upstream-anonymous-token"),
    "the upstream must see the anonymous registry token",
  );
  const tokenCall = fetchCalls.find((call) => call.url.startsWith("https://auth.docker.io/token"));
  assert(tokenCall, "upstream token must be resolved from the challenge realm");
  assert(
    tokenCall.url.includes("scope=repository%3Alibrary%2Fnginx%3Apull") ||
      tokenCall.url.includes("scope=repository:library/nginx:pull"),
    `challenge scope must be forwarded to the token service: ${tokenCall.url}`,
  );
  console.log("ok docker manifest pulls with edge-side upstream token");

  // /v2/ ping with valid Basic credentials: the edge accepts the mirror token and
  // the upstream challenge is resolved with the cached anonymous token.
  fetchCalls.length = 0;
  const ping = await worker.fetch(
    new Request(`${BASE_URL}/v2/`, { headers: { Authorization: basicAuth(TOKEN, "anything") } }),
    ENV,
  );
  assert(ping.status === 200, `docker ping should succeed via upstream token rescue (got ${ping.status})`);
  console.log("ok docker ping authenticated through the edge");

  // blob proxy: the mirror token is stripped even when attached.
  fetchCalls.length = 0;
  const blob = await worker.fetch(
    new Request(`${BASE_URL}/_worker_blob_proxy?url=${encodeURIComponent("https://s3.amazonaws.com/example-blob")}`, {
      headers: { Authorization: `Bearer ${TOKEN}` },
    }),
    ENV,
  );
  const blobBody = await blob.text();
  assert(blob.status === 200 && blobBody === "blob-bytes", "blob proxy should stream the S3 payload");
  assert(!fetchCalls[0].authorization, "blob proxy must strip the mirror token before S3");
  console.log("ok docker blob proxy strips credentials");
}

function basicAuth(user, pass) {
  return `Basic ${btoa(`${user}:${pass}`)}`;
}

function jsonResponse(body) {
  return new Response(JSON.stringify(body), {
    headers: { "Content-Type": "application/json" },
  });
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}