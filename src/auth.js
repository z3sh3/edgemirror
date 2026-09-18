import { HEALTH_PATHS } from "./config.js";

/**
 * Optional access-token gate.
 *
 * The gate is opt-in: it only activates when the `AUTH_TOKEN` secret/variable is
 * present in the runtime environment. Without it, every route behaves exactly as
 * before, so existing public deployments keep working unchanged.
 *
 * While enabled, ALL access to the service requires the token — UI pages and data
 * routes alike — so a leaked domain name does not open the proxy to mass use.
 * Only health probes skip the gate (the router also answers `/ads.txt` before the
 * gate, since ad-network verification must be able to read it anonymously).
 *
 * Accepted token carriers (checked in this order):
 *   1. `Authorization: Bearer <token>`
 *   2. `Authorization: Basic <base64>` where either the username or the password
 *      equals the token. Docker and several package managers only speak Basic auth,
 *      so `docker login <host>` (username arbitrary, password = token) works too, and
 *      browsers present a login dialog for the whole site.
 *   3. `X-Auth-Token: <token>`
 *   4. `?token=<token>` for clients that cannot set request headers. The router
 *      removes this parameter before forwarding, so it never reaches an upstream.
 */

const TOKEN_QUERY_PARAM = "token";

// Credential headers that only authenticate the caller to EdgeMirror. They must
// never be forwarded to an upstream once the mirror token has been verified.
const MIRROR_ONLY_HEADERS = ["authorization", "proxy-authorization", "x-auth-token", "cookie"];

export function getConfiguredToken(env) {
  const value = env?.AUTH_TOKEN;
  return typeof value === "string" && value.length > 0 ? value : null;
}

export function isAuthEnabled(env) {
  return getConfiguredToken(env) !== null;
}

export function isPublicPath(pathname) {
  // Health probes are the only anonymous endpoints while the gate is enabled.
  return HEALTH_PATHS.has(pathname);
}

export function hasValidToken(request, env) {
  const expected = getConfiguredToken(env);
  if (expected === null) {
    return true;
  }

  const provided = extractProvidedToken(request);
  if (typeof provided === "string") {
    return constantTimeEqual(provided, expected);
  }
  if (provided !== null) {
    return constantTimeEqual(provided.user, expected) || constantTimeEqual(provided.pass, expected);
  }

  return false;
}

/**
 * Remove mirror credentials from a verified request so no tool can forward them
 * to an upstream. Called only after the token has been validated.
 */
export async function sanitizeAuthorizedRequest(request) {
  let url;
  try {
    url = new URL(request.url);
  } catch {
    return request;
  }

  const hasQueryToken = url.searchParams.has(TOKEN_QUERY_PARAM);
  const headers = new Headers(request.headers);
  const hasMirrorHeader = MIRROR_ONLY_HEADERS.some((name) => headers.has(name));

  if (!hasQueryToken && !hasMirrorHeader) {
    return request;
  }

  if (hasQueryToken) {
    url.searchParams.delete(TOKEN_QUERY_PARAM);
  }
  for (const name of MIRROR_ONLY_HEADERS) {
    headers.delete(name);
  }

  return new Request(url.toString(), {
    method: request.method,
    headers,
    body: request.method === "GET" || request.method === "HEAD" ? null : await request.blob(),
    redirect: request.redirect,
  });
}

export function authFailureResponse(request) {
  let origin = "";
  try {
    origin = new URL(request.url).origin;
  } catch {
    // The gateway is reachable even when the request URL cannot be parsed;
    // fall back to a bare challenge so the client can still retry.
  }
  return new Response("Unauthorized: missing or invalid access token", {
    status: 401,
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
      // Basic makes browsers show a login dialog for the whole site; Bearer is
      // what API clients and the Docker token flow expect.
      "WWW-Authenticate": `Basic realm="edgemirror", Bearer realm="${origin}/token",service="edgemirror"`,
    },
  });
}

function extractProvidedToken(request) {
  const authorization = request.headers.get("Authorization") || "";

  const bearer = /^Bearer\s+(.+)$/i.exec(authorization);
  if (bearer) {
    const value = bearer[1].trim();
    return value.length > 0 ? value : null;
  }

  const basic = /^Basic\s+(.+)$/i.exec(authorization);
  if (basic) {
    return decodeBasicCredentials(basic[1].trim());
  }

  const headerToken = request.headers.get("X-Auth-Token");
  if (headerToken && headerToken.trim().length > 0) {
    return headerToken.trim();
  }

  let queryToken = null;
  try {
    queryToken = new URL(request.url).searchParams.get(TOKEN_QUERY_PARAM);
  } catch {
    return null;
  }
  if (queryToken && queryToken.trim().length > 0) {
    return queryToken.trim();
  }

  return null;
}

function decodeBasicCredentials(encoded) {
  try {
    const decoded = atob(encoded);
    const separator = decoded.indexOf(":");
    if (separator === -1) {
      return { user: decoded, pass: "" };
    }
    return {
      user: decoded.slice(0, separator),
      pass: decoded.slice(separator + 1),
    };
  } catch {
    return null;
  }
}

function constantTimeEqual(a, b) {
  const left = String(a ?? "");
  const right = String(b ?? "");
  if (left.length !== right.length) {
    return false;
  }

  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}
