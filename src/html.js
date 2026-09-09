export function hasNativeHtmlRewriter() {
  return typeof HTMLRewriter === "function";
}

export async function rewriteHtmlResponse(response, rewrite) {
  const headers = new Headers(response.headers);
  headers.delete("Content-Length");
  headers.delete("content-length");

  return new Response(rewrite(await response.text()), {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export function rewriteHtmlAttributes(html, rewriteAttribute) {
  return html.replace(/\s(href|src)=("([^"]*)"|'([^']*)')/gi, (match, attr, raw, doubleQuoted, singleQuoted) => {
    const value = doubleQuoted ?? singleQuoted ?? "";
    const rewritten = rewriteAttribute(attr.toLowerCase(), value);
    if (!rewritten || rewritten === value) {
      return match;
    }
    const quote = raw.startsWith("'") ? "'" : '"';
    return ` ${attr}=${quote}${escapeHtmlAttribute(rewritten)}${quote}`;
  });
}

function escapeHtmlAttribute(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}
