<p align="center">
  <strong>English</strong> | <a href="README.es.md">Español</a> | <a href="README.zh-CN.md">中文</a>
</p>

<h1 align="center">EdgeMirror</h1>

<p align="center">
  A read-only, no-cache edge mirror gateway for operating-system repositories and developer sources.
</p>

<p align="center">
  One Cloudflare Worker, 35 system repositories, 13 developer adapters, 48 generated configurations, and all legacy routes preserved behind one clean domain.
</p>

<p align="center">
  <a href="https://deploy.workers.cloudflare.com/?url=https://github.com/tianrking/edgemirror">
    <img alt="Deploy to Cloudflare" src="https://img.shields.io/badge/Deploy%20to-Cloudflare-f38020?style=for-the-badge&logo=cloudflare&logoColor=white&labelColor=111827">
  </a>
  <a href="https://vercel.com/new/clone?repository-url=https://github.com/tianrking/edgemirror">
    <img alt="Deploy with Vercel" src="https://img.shields.io/badge/Deploy%20with-Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white&labelColor=111827">
  </a>
</p>

<p align="center">
  <img alt="Verify" src="https://img.shields.io/github/actions/workflow/status/tianrking/edgemirror/verify.yml?branch=main&style=for-the-badge&label=verify">
  <img alt="Runtime" src="https://img.shields.io/badge/runtime-Cloudflare%20Workers%20%7C%20Vercel%20Functions-0f172a?style=for-the-badge">
  <img alt="Language" src="https://img.shields.io/badge/language-JavaScript%20ESM-f7df1e?style=for-the-badge&labelColor=111827">
  <img alt="Package manager" src="https://img.shields.io/badge/package-npm-cb3837?style=for-the-badge">
  <img alt="Maintainer" src="https://img.shields.io/badge/maintainer-tianrking-2563eb?style=for-the-badge">
</p>

## Why EdgeMirror

EdgeMirror is a single-domain edge mirror gateway for common developer sources. The recommended production model is one public `YOUR_DOMAIN` with canonical namespaces at `/repo`, `/pkg`, `/sdk`, `/oci`, and `/git`. Existing paths such as `/pypi`, `/npm`, `/go`, `/maven`, `/crates`, `/downloads`, `/github`, and `/v2` remain compatible.

Every page includes a shared language switcher for English, Spanish, and Chinese. Tool names stay in English while explanations, usage notes, and common UI labels follow the selected language.

Current maintainer deployment: [box.w0x7ce.eu](https://box.w0x7ce.eu/). A custom domain is optional for personal forks and is not required for any route.

Maintainer: [tianrking](https://github.com/tianrking)

Keywords: edge mirror gateway, CDN-style source acceleration, Cloudflare Workers proxy, Vercel Functions proxy, PyPI mirror accelerator, PyTorch wheel proxy, Hugging Face mirror, Docker registry proxy, GitHub raw proxy, Linux mirror proxy, npm registry proxy, Go module proxy, Maven proxy, Gradle mirror, crates.io sparse registry proxy, runtime download accelerator.

## Tool Stack

<p align="center">
  <img alt="Cloudflare Workers" src="https://img.shields.io/badge/Cloudflare-Workers-f38020?style=for-the-badge">
  <img alt="Vercel Functions" src="https://img.shields.io/badge/Vercel-Functions-000?style=for-the-badge">
  <img alt="JavaScript ESM" src="https://img.shields.io/badge/JavaScript-ESM-f7df1e?style=for-the-badge&labelColor=111827">
  <img alt="Single domain" src="https://img.shields.io/badge/single--domain-paths-2563eb?style=for-the-badge">
  <img alt="Path routing" src="https://img.shields.io/badge/path-routing-16a34a?style=for-the-badge">
  <img alt="PyPI" src="https://img.shields.io/badge/PyPI-packages-3775a9?style=for-the-badge">
  <img alt="PyTorch" src="https://img.shields.io/badge/PyTorch-wheels-ee4c2c?style=for-the-badge">
  <img alt="Hugging Face" src="https://img.shields.io/badge/Hugging%20Face-models-ffd21e?style=for-the-badge&labelColor=111827">
  <img alt="GitHub" src="https://img.shields.io/badge/GitHub-proxy-2da44e?style=for-the-badge">
  <img alt="Docker" src="https://img.shields.io/badge/Docker-registry-0db7ed?style=for-the-badge">
  <img alt="Linux mirrors" src="https://img.shields.io/badge/Linux-mirrors-8b5cf6?style=for-the-badge">
  <img alt="Universal proxy" src="https://img.shields.io/badge/Universal-file%20proxy-d946ef?style=for-the-badge">
  <img alt="npm" src="https://img.shields.io/badge/npm-registry-cb3837?style=for-the-badge">
  <img alt="Go modules" src="https://img.shields.io/badge/Go-modules-00add8?style=for-the-badge">
  <img alt="Maven" src="https://img.shields.io/badge/Maven-Gradle-c71a36?style=for-the-badge">
  <img alt="crates.io" src="https://img.shields.io/badge/crates.io-sparse-dea584?style=for-the-badge&labelColor=111827">
  <img alt="Downloads" src="https://img.shields.io/badge/runtime-downloads-0f766e?style=for-the-badge">
  <img alt="Syntax check" src="https://img.shields.io/badge/syntax-check-22c55e?style=for-the-badge">
  <img alt="Smoke test" src="https://img.shields.io/badge/smoke-tested-22c55e?style=for-the-badge">
  <img alt="npm audit" src="https://img.shields.io/badge/npm-audit-22c55e?style=for-the-badge">
  <img alt="One click deploy" src="https://img.shields.io/badge/one--click-deploy-7c3aed?style=for-the-badge">
  <img alt="Wrangler" src="https://img.shields.io/badge/Wrangler-4.x-f38020?style=for-the-badge">
</p>

## Service Matrix

`Stable` means the route is recommended for daily use. `Test` means the accelerator is implemented, wired into smoke checks, and ready for validation before it is promoted to stable.

| Status | Service | Single-domain route | What it accelerates |
| --- | --- | --- | --- |
| Stable | EdgeMirror Portal | `/` or `/edgemirror` | Visual dashboard and usage snippets for every source accelerator |
| Stable | Help | `/help` | Route map, web usage, CLI recipes, and configuration guide in English, Spanish, and Chinese |
| Stable | PyPI / PyTorch | `/pypi` | PyPI simple index, package files, and PyTorch wheel downloads |
| Stable | Hugging Face | `/hf` | Hugging Face API, model files, datasets, and LFS downloads |
| Stable | GitHub | `/github` | Git clone, raw files, release assets, and GitHub pages |
| Stable | Docker Registry | `/docker` UI, `/v2` API | Docker Hub plus `quay`, `gcr`, `k8s`, `ghcr`, `nvcr` prefixes |
| Stable | Linux Mirrors | `/mirrors` | APT, YUM, DNF, Pacman, wget, and curl mirror paths |
| Stable | Repository Gateway | `/repo/{source}` | Fixed, read-only, no-cache system repositories for APT, DNF/YUM, Pacman, APK/OPKG, XBPS, FreeBSD pkg, and Conda |
| Stable | Catalog & Setup UI | `/catalog` | Search all 35 sources, generate configuration for 48 targets, copy commands, and probe selected routes |
| Stable | Canonical Route Layer | `/pkg`, `/sdk`, `/oci`, `/git` | npm, read-only NuGet v3, Node.js, Flutter, Docker Registry v2, and GitHub canonical paths |
| Stable | Universal Proxy | `/proxy` | Any HTTP/HTTPS file URL with filename handling |
| Test | npm Registry | `/npm` | npm, pnpm, yarn metadata and tarball downloads |
| Test | Go Module Proxy | `/go` | GOPROXY module list, version metadata, `.mod`, and `.zip` files |
| Test | Maven / Gradle | `/maven` | Maven Central, Google Maven, Gradle Plugin Portal, and JitPack |
| Test | crates.io Sparse | `/crates` | Cargo sparse index and `.crate` package downloads |
| Test | Runtime Downloads | `/downloads` | Node.js, Python, Go, Rustup, Open VSX, SourceForge, GitLab, Gitea, and direct file URLs |

The `/catalog` UI covers every repository and canonical developer route while `/repo`, `/pkg`, and `/sdk` remain machine-readable APIs. See [REPOSITORIES.md](REPOSITORIES.md) for source IDs, compatibility routes, and configuration examples.

## Current Release: 2.0.0

| Dimension | Current coverage |
| --- | --- |
| System repositories | 35 fixed upstream roots |
| Developer and SDK adapters | 13 canonical targets |
| Catalog generator | 48 complete configuration targets |
| Package managers | APT, DNF/YUM, Zypper, Pacman, APK, OPKG, XBPS, FreeBSD pkg, Conda |
| Canonical namespaces | `/repo`, `/pkg`, `/sdk`, `/oci`, `/git` |
| Compatibility | Existing `/pypi`, `/npm`, `/go`, `/maven`, `/crates`, `/downloads`, `/github`, and `/v2` routes remain available |
| Cache policy | Strict `no-store` on browser, CDN, and upstream requests |
| Additional infrastructure | No Cache API, KV, R2, D1, database, or VPS |

The Worker is intentionally a transparent, read-only forwarding layer. Official metadata, checksums, signatures, range requests, ETags, and last-modified headers remain part of the upstream protocol instead of being copied into local storage.

## Complete System Repository Catalog

| Ecosystem | Source IDs |
| --- | --- |
| Debian / Ubuntu | `debian`, `debian-security`, `debian-ports`, `ubuntu`, `ubuntu-security`, `ubuntu-ports`, `ubuntu-releases` |
| Raspberry Pi | `raspbian`, `raspberrypi`, `raspberrypi-images` |
| OpenWrt / ImmortalWrt | `openwrt`, `openwrt-releases`, `openwrt-snapshots`, `openwrt-packages`, `openwrt-firmware`, `openwrt-sdk`, `immortalwrt`, `immortalwrt-releases`, `immortalwrt-snapshots` |
| Pacman / APK | `arch`, `archlinuxarm`, `alpine`, `msys2` |
| DNF / YUM / Zypper | `fedora`, `epel`, `centos-stream`, `rocky`, `almalinux`, `opensuse` |
| XBPS / pkg / Termux | `void`, `void-musl`, `freebsd-pkg`, `termux` |
| Conda | `anaconda`, `conda-forge` |

Every source uses the same machine route:

```text
https://YOUR_DOMAIN/repo/{source}/{upstream-path}
```

`GET /repo` returns the deployed source catalog as JSON, including canonical IDs, aliases, upstream roots, and complete entry URLs. Compatibility aliases such as `debian-archive`, `ubuntu-archive`, `raspi`, `archlinux`, `fedora-epel`, `centos`, `rockylinux`, `alma`, `freebsd`, and `conda-defaults` are also accepted.

## Canonical Route Map

| Canonical route | Purpose | Compatible route |
| --- | --- | --- |
| `/repo/{source}/...` | Fixed operating-system repositories | New namespace |
| `/pkg/npm/...` | npm registry | `/npm/...` |
| `/pkg/nuget/v3/index.json` | Read-only NuGet v3 service index and resource chain | New namespace |
| `/sdk/node/...` | Node.js release tree | `/downloads/node/...` |
| `/sdk/flutter/...` | Flutter SDK metadata and storage root | New namespace |
| `/oci/docker/v2/...` | Docker Registry v2 API | `/v2/...`, `/docker/...` |
| `/git/github/...` | GitHub Git, raw files, and release assets | `/github/...` |

The NuGet adapter rewrites the full v3 resource chain back through EdgeMirror and removes publish capabilities. Flutter release metadata and storage URLs are rewritten to the deployment domain. Docker token and blob redirects, npm tarball URLs, and other protocol-specific locations are also rewritten by their dedicated adapters.

## Catalog and Configuration Generator

Open `/catalog` to use the complete UI:

- Search all 35 system sources by distribution, package manager, route, or upstream.
- Filter APT, OpenWrt, RPM, Pacman/APK, and other repository families.
- Generate exact configuration for all 48 targets using the deployment domain.
- Show only the version, architecture, and component fields required by the selected target.
- Copy the generated command, open the selected route, or run a real `HEAD` route probe.
- Use the same UI in English, Spanish, or Chinese on desktop and mobile.

The UI calls the read-only JSON generator endpoint:

```text
GET /catalog/config?id=debian&origin=https://YOUR_DOMAIN&version=bookworm&components=main%20contrib
```

The endpoint validates the origin, target ID, version, architecture, and component list before generating output. It only accepts `GET`, `HEAD`, and `OPTIONS`.

OpenWrt package-manager selection follows the release boundary automatically:

```text
OpenWrt 24.10 and earlier  -> OPKG -> /etc/opkg/distfeeds.conf
OpenWrt 25.12 and later    -> APK  -> /etc/apk/repositories.d/distfeeds.list
```

## One-Click Deployment

### Deploy to Cloudflare Workers

Click the Cloudflare button at the top of this README, or open:

```text
https://deploy.workers.cloudflare.com/?url=https://github.com/tianrking/edgemirror
```

Cloudflare reads `wrangler.toml`, creates the Worker, and deploys it to the account-provided Worker name. The default configuration is intentionally portable: it enables `workers.dev`, disables preview URLs, and does not bind the maintainer's custom domain.

The currently verified maintainer deployment is `https://box.w0x7ce.eu`. Personal forks can use the returned `workers.dev` hostname or attach their own custom domain after deployment.

After the Worker is deployed, add one custom domain in the Cloudflare dashboard, or copy the route block from `wrangler.custom-domain.example.toml` into `wrangler.toml` after confirming that the domain belongs to your Cloudflare account. Every tool will still use the same path model on that domain.

To enable access-token protection (see [Access Token](#access-token-required-access-control)), store the secret in the account that owns the deployment, then redeploy:

```bash
wrangler secret put AUTH_TOKEN
wrangler deploy
```

**GitHub Actions deploys (recommended).** The [deploy workflow](../.github/workflows/deploy.yml) re-asserts `AUTH_TOKEN` on every push, so the secret survives redeploys (the Cloudflare dashboard Git integration instead wipes manually-set secrets on each push). Enable it by adding these to **GitHub → Settings → Secrets and variables → Actions**:

- `CLOUDFLARE_API_TOKEN` — an API token with `Workers Scripts: Edit` permission (and the same account as the worker), or `CLOUDFLARE_OAUTH_TOKEN` with `Edit Cloudflare Workers` scope
- `CLOUDFLARE_ACCOUNT_ID` — the numeric account ID of the worker
- `AUTH_TOKEN` — the access token used by the mirror gate
- (optional) `MIRROR_DOMAIN` repository **variable** (host without scheme) — the workflow then probes `/health` after deploy and fails if the gate is not enabled

If you are already deploying through the Cloudflare dashboard Git integration, **remove that connection** (Settings → Builds & deployments) so both systems do not race on the same worker.

### Deploy to Vercel

Click the Vercel button at the top of this README, or open:

```text
https://vercel.com/new/clone?repository-url=https://github.com/tianrking/edgemirror
```

Vercel uses `api/index.js` as a Web Handler function and `vercel.json` to route every path to that function. The Vercel deployment uses the same path model: `/edgemirror`, `/pypi`, `/hf`, `/github`, `/docker`, `/mirrors`, `/proxy`, `/npm`, `/go`, `/maven`, `/crates`, `/downloads`, and `/help`. Docker Registry API traffic is also auto-detected at `/v2`, `/token`, and `/_worker_blob_proxy`, so a single Vercel domain can serve Docker pulls without a `/docker` prefix in the image name.

To enable access-token protection on Vercel, add the `AUTH_TOKEN` environment variable in the Vercel project settings (`vercel env add AUTH_TOKEN production`) and redeploy.

## Local Development

```bash
npm install
npm run verify
npm run dev
```

Useful scripts:

| Command | Purpose |
| --- | --- |
| `npm run dev` | Start Cloudflare Worker dev server |
| `npm run dev:cloudflare` | Same as `npm run dev` |
| `npm run dev:vercel` | Start Vercel local development with `npx vercel@latest dev` |
| `npm run check` | Syntax-check every JavaScript file under `src` and `scripts` |
| `npm run smoke:repositories` | Verify all 35 repository mappings, aliases, methods, headers, and no-store behavior |
| `npm run smoke:repositories:live` | Probe representative official APT, DNF, Pacman, APK, XBPS, and Conda upstreams |
| `npm run smoke:canonical` | Verify canonical npm, NuGet, SDK, OCI, and Git route behavior with controlled upstreams |
| `npm run smoke:canonical:live` | Verify representative canonical routes against live official services |
| `npm run smoke:catalog` | Verify all 48 configuration targets, the OpenWrt boundary, validation, UI counts, and legacy navigation |
| `npm run smoke:auth` | Verify the optional token gate, accepted carriers, credential sanitization, and Docker token flow |
| `npm run smoke:vercel` | Import the Vercel function entry and verify core routes |
| `npm run verify` | Run every syntax, repository, live-upstream, canonical-route, Catalog, Vercel, and security check |
| `npm run deploy:cloudflare` | Deploy with Wrangler |
| `npm run deploy:vercel` | Deploy to Vercel production with `npx vercel@latest --prod` |

## Routing Model

EdgeMirror is designed around single-domain path routing:

| Runtime style | Example | Notes |
| --- | --- | --- |
| Path routing | `https://YOUR_DOMAIN/pypi/simple/` | Recommended production model |
| Vercel path routing | `https://your-app.vercel.app/pypi/simple/` | Same routes after one-click Vercel deploy |

For Docker on a single-domain deployment, use the deployment host directly:

```bash
docker pull your-app.vercel.app/library/nginx:latest
```

The router forwards Docker's `/v2`, `/token`, and blob redirect traffic to the Docker tool automatically.

Health checks are available at:

```text
/health
/healthz
/__health
```

They return JSON with the project version and the registered service list. When `AUTH_TOKEN` is configured, the payload also reports `auth: { "enabled": true }`.

### Use Docker Through the Proxy by Default

The mirror is a Registry v2 pull-through endpoint, so Docker can use it in two ways.

**Files you may need to update** (depends on the mode you pick):

| File | Purpose | Needed when |
| --- | --- | --- |
| `~/.docker/config.json` | Mirror-host credentials (the `auths` entry written by `docker login`) | Mode B with token protection — required |
| `/etc/docker/daemon.json` | `registry-mirrors` so `docker pull nginx` uses the mirror by default | Mode A without token protection |
| `~/.bashrc` or `~/.zshrc` | `dp()` helper so `dp nginx` rewrites to the mirror host | Optional (run `source ~/.bashrc` after editing) |

You normally do not hand-edit `~/.docker/config.json` — a single `docker login` writes it for you (Docker Desktop on macOS/Windows may store the credentials in the OS keychain instead). The contents of each file are shown in the modes below.

**Recommended: run the one-click script.** `scripts/docker-mirror-setup.sh` (run as root on the Docker host) writes the `hosts.toml` registry config to `/etc/docker/certs.d/docker.io/` — the directory dockerd actually reads with the containerd image store (`registry.CertsDir()`; the containerd path is **not** consulted) — and mirrors the same file under `/etc/containerd/certs.d/docker.io/` for `ctr`/CRI consumers. `hosts.toml` has no `username`/`password` keys (containerd silently ignores them, see [containerd #8186](https://github.com/containerd/containerd/issues/8186)), so the token is sent through the documented [`header` table](https://containerd.io/docs/main/hosts/) as a static `Authorization` header. Every `docker.io` pull then goes through the mirror with the token, and Docker is restarted afterwards. The script does **not pull images itself**; once configured it only prints manual verification steps for `docker pull nginx:latest`.

The script **only supports the containerd image store** (Docker >= 25 with `"features": { "containerd-snapshotter": true }` in daemon.json). The classic image store cannot attach credentials to a token-gated mirror — Docker does not attach registry credentials to `registry-mirrors` pulls ([moby#30880](https://github.com/moby/moby/issues/30880)) — so when the requirement is not met the script **prints the reason and exits**:

```bash
sudo scripts/docker-mirror-setup.sh                                  # default apply: prompts for domain + token, configures, prints manual verification
sudo AUTH_TOKEN=<your-token> MIRROR_HOST=<your-domain> scripts/docker-mirror-setup.sh   # optional: env vars skip the prompts
sudo scripts/docker-mirror-setup.sh update                           # re-apply after token rotation
sudo scripts/docker-mirror-setup.sh status                           # inspect
sudo scripts/docker-mirror-setup.sh rollback                         # restore the default Docker Hub setup
```

Running the script without arguments is `apply`; when `MIRROR_HOST` / `AUTH_TOKEN` are not set, the script asks for them on the terminal (the token is a hidden input, so it never ends up in shell history). The repo does not contain the real domain or token.

**Pull fails with `network is unreachable`?** The mirror hostname resolves to IPv6 (AAAA) but this host has no IPv6 route, so containerd dials the AAAA address first. Fix with one of: disable IPv6 on the host (`sysctl -w net.ipv6.conf.all.disable_ipv6=1`, persist it in `/etc/sysctl.d/99-disable-ipv6.conf`, then restart Docker), pin the mirror's IPv4 address in `/etc/hosts`, or turn IPv6 off for the domain in the CDN/DNS settings. The script detects and warns about this at the end of `apply`.

**Option A — daemon-wide default (no token protection).** That is the `registry-mirrors` model: every `docker pull nginx` on the host goes through the mirror first. Edit `/etc/docker/daemon.json`:

```json
{
  "registry-mirrors": ["https://YOUR_DOMAIN"]
}
```

Then restart the daemon:

```bash
sudo systemctl restart docker
```

> Note: Docker does **not** attach registry credentials to `registry-mirrors` pulls (credentials stay tied to the original registry host, see [moby/moby#30880](https://github.com/moby/moby/issues/30880)). When token protection is enabled, an unauthenticated mirror pull answers `401` and Docker silently falls back to Docker Hub, so the mirror is not actually used. Prefer Option B when `AUTH_TOKEN` is set.

**Option B — login to the mirror host (works with token protection).** Authenticate once, then pull with the mirror hostname in the image name:

```bash
docker login YOUR_DOMAIN -u proxy -p <AUTH_TOKEN>
# username is arbitrary; the access token is the password

docker pull YOUR_DOMAIN/library/nginx:latest
docker pull YOUR_DOMAIN/quay/coreos/etcd:latest
```

Inside the mirror flow the edge verifies the token, then resolves an anonymous pull token from the upstream registry itself, so the token never reaches Docker Hub.

For scripted environments, the `docker login` equivalent is an `auths` entry in `~/.docker/config.json`:

```bash
echo -n "proxy:<AUTH_TOKEN>" | base64
```

```json
{
  "auths": {
    "YOUR_DOMAIN": {
      "auth": "<paste base64 output>"
    }
  }
}
```

**Make plain `docker pull nginx` use the mirror (token mode).** Add a small shell function to `~/.bashrc` or `~/.zshrc` so unqualified `docker pull` calls are rewritten to the mirror host:

```bash
dp() {
  local img="${1#docker.io/}"
  case "$img" in
    ghcr.io/*)        img="YOUR_DOMAIN/ghcr/${img#ghcr.io/}" ;;
    quay.io/*)        img="YOUR_DOMAIN/quay/${img#quay.io/}" ;;
    gcr.io/*)         img="YOUR_DOMAIN/gcr/${img#gcr.io/}" ;;
    registry.k8s.io/*) img="YOUR_DOMAIN/k8s/${img#registry.k8s.io/}" ;;
    *)                img="YOUR_DOMAIN/library/${img}" ;;
  esac
  docker pull "$img"
}
```

Then `dp nginx:latest` pulls through the mirror, and `docker pull nano` (unqualified aliases) still works because Docker treats names without a slash as Docker Hub images.

## Examples

Install a Python package:

```bash
pip install numpy -i https://YOUR_DOMAIN/pypi/simple/
```

Install PyTorch wheels:

```bash
pip install torch torchvision --index-url https://YOUR_DOMAIN/pypi/pytorch/cu118
```

Download a Hugging Face model:

```bash
export HF_ENDPOINT=https://YOUR_DOMAIN/hf
huggingface-cli download gpt2
```

Clone through the GitHub proxy:

```bash
git clone https://YOUR_DOMAIN/github/vercel/next.js.git
```

Pull a Docker image:

```bash
docker login YOUR_DOMAIN -u proxy -p <AUTH_TOKEN>   # only when token protection is on
docker pull YOUR_DOMAIN/library/nginx:latest
```

Proxy a generic file:

```bash
curl -L -O "https://YOUR_DOMAIN/proxy/https://nodejs.org/dist/v22.11.0/node-v22.11.0-x64.msi"
```

Use the new test npm registry route:

```bash
npm install lodash --registry=https://YOUR_DOMAIN/npm/
pnpm install lodash --registry=https://YOUR_DOMAIN/npm/
```

Use the new test Go module route:

```bash
go env -w GOPROXY=https://YOUR_DOMAIN/go,direct
```

Use the new test Maven / Gradle routes:

```kotlin
repositories {
    maven { url = uri("https://YOUR_DOMAIN/maven/maven-central") }
    maven { url = uri("https://YOUR_DOMAIN/maven/google") }
    maven { url = uri("https://YOUR_DOMAIN/maven/gradle-plugin") }
}
```

Use the new test crates.io sparse route:

```toml
[source.crates-io]
replace-with = "edgemirror"

[source.edgemirror]
registry = "sparse+https://YOUR_DOMAIN/crates/"
```

Use the new test runtime download route:

```bash
curl -L -O "https://YOUR_DOMAIN/downloads/node/v22.11.0/node-v22.11.0-x64.msi"
curl -L -O "https://YOUR_DOMAIN/downloads/https://nodejs.org/dist/v22.11.0/node-v22.11.0-x64.msi"
```

## Access Token (Required Access Control)

Set the `AUTH_TOKEN` secret/variable and **every request to the service requires the token** — UI pages and data routes alike — so a leaked domain name does not open the proxy to mass use. Only the health probes (`/health`, `/healthz`, `/__health`) and `ads.txt` skip the gate. Without `AUTH_TOKEN` the deployment behaves exactly as before (no gate). See the deploy sections for `wrangler secret put AUTH_TOKEN` (Cloudflare) and `AUTH_TOKEN` (Vercel).

Clients may present the token in four ways:

| Carrier | Example | Typical client |
| --- | --- | --- |
| `Authorization: Bearer <token>` | `curl -H "Authorization: Bearer $TOKEN" ...` | curl, npm, general HTTP |
| `Authorization: Basic <base64>` | `curl -u "$TOKEN:x" ...` | Docker, Go, Maven, pip, browser login |
| `X-Auth-Token: <token>` | custom scripts | generic |
| `?token=<token>` | `.../pypi/simple/?token=$TOKEN` | clients that cannot set headers |

Whatever carrier is used, the credential is stripped before the request reaches any upstream, and a `?token=` parameter is removed from the forwarded URL. Prefer headers over the query parameter: query strings can show up in access logs. `OPTIONS` preflight requests are always allowed.

**Browser access — what to type in the login dialog.** Opening `https://YOUR_DOMAIN/` shows a “requires authentication” dialog:

- Username: any value (conventionally `proxy`)
- Password: the access token (the `AUTH_TOKEN` value)

The check accepts a token in either position, so the reverse (username = token, password = anything) works too, and multiple people can share one token. Alternatively type `https://proxy:YOUR_TOKEN@YOUR_DOMAIN/` in the address bar and the browser sends the credentials automatically. Tick “remember credentials” to avoid re-entering them; the browser then attaches them on every click, so the portal, help, catalog, and all tool pages work normally. To clear them, delete the site's saved password in the browser.

Verify the gate after deploying:

```bash
curl -s https://YOUR_DOMAIN/health   # payload shows "auth": { "enabled": true }
curl -i https://YOUR_DOMAIN/repo/debian/dists/stable/InRelease        # 401 without token
curl -H "Authorization: Bearer $TOKEN" https://YOUR_DOMAIN/repo/debian/dists/stable/InRelease  # 200
```

Per-client setup:

```bash
# pip – credentials in the index URL
export PIP_INDEX_URL="https://proxy:YOUR_TOKEN@YOUR_DOMAIN/pypi/simple/"

# npm – .npmrc
echo 'registry=https://YOUR_DOMAIN/npm/' >> ~/.npmrc
echo '//YOUR_DOMAIN/npm/:_authToken=YOUR_TOKEN' >> ~/.npmrc

# pnpm / yarn
pnpm config set registry https://YOUR_DOMAIN/npm/ --location global
pnpm config set //YOUR_DOMAIN/npm/:_authToken YOUR_TOKEN

# Go – credentials in the GOPROXY URL or ~/.netrc
# ~/.netrc:  machine YOUR_DOMAIN login proxy password YOUR_TOKEN
go env -w GOPROXY=https://YOUR_DOMAIN/go,direct

# Cargo – register the sparse index with the token
cargo login --registry edgemirror YOUR_TOKEN
# .cargo/config.toml:
# [registries.edgemirror]
# index = "sparse+https://YOUR_DOMAIN/crates/"

# Maven – settings.xml server credentials (username password pair of your choice)
# <server><id>edgemirror</id><username>proxy</username><password>YOUR_TOKEN</password></server>
# then use https://YOUR_DOMAIN/maven/maven-central/ with the same id

# git clone through the GitHub proxy
GIT_TERMINAL_PROMPT=0 git clone "https://proxy:YOUR_TOKEN@YOUR_DOMAIN/github/vercel/next.js.git"

# Hugging Face – public models only when the gate is on
# (the token becomes the Authorization header; private/gated repos need a direct connection)
export HF_ENDPOINT="https://YOUR_DOMAIN/hf"
export HF_TOKEN="YOUR_TOKEN"

# Universal proxy
curl -L -O -H "Authorization: Bearer $TOKEN" \
  "https://YOUR_DOMAIN/proxy/https://nodejs.org/dist/v22.11.0/node-v22.11.0-x64.msi"
```

## Project Layout

```text
api/index.js              Vercel Functions Web Handler entry
REPOSITORIES.md           Complete source IDs, canonical routes, and package-manager recipes
scripts/check-syntax.mjs  Cross-platform JavaScript syntax checker
scripts/smoke-*.mjs       Repository, canonical route, Catalog, live upstream, and Vercel tests
scripts/smoke-vercel.mjs  Vercel runtime smoke test
src/config.js             Project metadata, service registry, health paths
src/html.js               HTML rewrite fallback for non-Cloudflare runtimes
src/i18n.js               Language detection, language switch links, and localized URLs
src/index.js              Host/path router and health endpoint
src/proxy-utils.js        Shared CORS, redirect, header, and proxy helpers
src/repositories/         Fixed upstream catalog and validated configuration generator
src/tools/catalog.js      Catalog UI and read-only configuration endpoint
src/tools/repositories.js Repository gateway handler
src/tools/nuget.js        Read-only NuGet v3 resource-chain adapter
src/tools/sdks.js         Node.js and Flutter canonical SDK routes
src/tools/*.js            Individual tool implementations
vercel.json               Vercel routing and build configuration
wrangler.toml             Portable Cloudflare Workers deploy configuration
wrangler.custom-domain.example.toml  Optional custom-domain configuration example
```

## Configuration

Edit `src/config.js` when adding, renaming, or documenting a tool. Edit `wrangler.toml` when changing the Cloudflare Worker name or compatibility date.

For Cloudflare custom domains, add the domain in the Cloudflare dashboard or use `wrangler.custom-domain.example.toml` as a reference after the domain is available in the target account. For Vercel custom domains, add one primary domain in the Vercel dashboard and keep the same path routes.

## Production Notes

- Keep `npm run verify` green before deploying.
- Treat `/catalog` as the human interface and `/repo`, `/pkg`, and `/sdk` as machine interfaces.
- Respect the read-only policy: repository and configuration endpoints only accept `GET`, `HEAD`, and `OPTIONS`.
- When token protection is enabled, only health probes (and `ads.txt`) skip the gate; every page and data route requires a valid token, and mirror credentials never reach upstreams.
- Rotate `AUTH_TOKEN` by re-running `wrangler secret put AUTH_TOKEN`; readers of the old value are rejected immediately after the deploy.
- Keep browser, CDN, and upstream cache directives at `no-store`; public caching is deliberately not enabled.
- Preserve upstream Range, ETag, Last-Modified, Content-Range, checksum, and signature behavior.
- Keep `wrangler` updated; it is the local Cloudflare dev/deploy toolchain.
- Cloudflare custom domains are account-specific, so the portable default `wrangler.toml` does not hard-code one.
- Use one primary domain for the public product experience; legacy per-tool hosts are not the recommended interaction model.
- Some upstream services may have rate limits, authentication requirements, or terms of service that still apply through a proxy.

## Roadmap

- Promote test accelerators to stable after more upstream compatibility checks.
- Add configurable service domains through environment variables.
- Add structured access logs and optional request tracing.
- Expand live probes to more architectures without making deployment depend on every upstream being online.
- Add deployment preview screenshots for the portal and tool pages.
