# OmniRoute — MSR-MOD (Slim-Full)

A slimmed, locally maintained fork of [OmniRoute](https://github.com/cheaper-inference/OmniRoute) — the unified AI router. This repository is trimmed for **personal localhost use on Windows + Docker**: only Windows-compatible and Docker-relevant files are kept, along with everything needed to run the app locally (`npm run dev` / `npm run start`, builds, and Docker). All bulk content (docs, tests, desktop/electron tooling, image assets, contrib/deploy pipelines, and release machinery) has been removed.

Targets:

- Windows 10/11 development (PowerShell, Node 24/26)
- Docker Desktop (`docker compose`)
- Local PWA / dashboard UI via `npm run dev` or `npm run start`
- Not intended for npm publishing as-is (the `files` block was kept for reference; publish flow was slimmed)

## What changed in this fork

### Removed (bulk waste)

| Area | What was removed | Why |
|---|---|---|
| `docs/` | Full documentation tree | Out of scope for personal localhost use |
| `tests/`, `playwright.config.ts`, `vitest*.{ts,json}` | Test suite + runner configs | Local fork is not maintaining upstream's CI pipeline |
| `electron/` | Desktop app | Out of scope; Windows-only localhost use |
| `images/` | Marketing logos and screenshots | Not needed to run the app |
| `examples/` | Example provider packs | Not needed to run the app |
| `deploy/` | Kubernetes/cloud manifests | Out of scope (Keep Docker files only) |
| `contrib/`, `skills/`, `changelog.d/` | Contributors' docs and release fragments | Out of scope |
| `.git/` (originally) | Upstream git history | Fresh start for this fork; re-initialized as new repo |
| Root config | `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`, `LICENSE`, `Makefile`, `flake.{nix,lock}`, `fly.toml`, `pnpm-workspace.yaml`, `*.stryker*`, `socket.yml`, `sonar-project.properties`, `knip.json`, `llm.txt`, and many other CI/release configs | Out of scope |
| `scripts/` | 109 of 183 scripts removed | Scripts unrelated to local dev / build / Docker were pruned using transitive-closure analysis |
| `config/quality/`, `config/release/`, `config/ci/`, `config/i18n*`, `config/payloadRules.json`, `config/alibaba-free-tier-allowlist.json` | Quality gates, release pipeline, i18n schema/rules | Removed for simplicity (app falls back to embedded defaults for payload rules & allowlist) |
| `.github/`, `.husky/`, `.vscode/`, `.vale/` | CI / GitHub metadata | Out of scope |

### Slimmed `package.json`

- **Scripts** reduced from ~80 to ~40: kept `dev`, `start`, `build`, `check:*`, `lint`, `postinstall`, and Docker helpers; removed publish-only, release, homolog, SRE, perf, and docs gates.
- **Dependencies** trimmed (Playwright, Stryker, promptfoo, husky as prepare target, etc.); ~106 runtime deps, ~25 devDependencies.
- **Lockfile regenerated** — `package-lock.json` rewritten against the slimmed manifest; `npm install --legacy-peer-deps` completes successfully (1,405 packages added).
- **`bin`** and publishing-related `files` entries were kept for reference but release flow is not maintained here.

### Recreated / repaired (intentionally, after deletion)

These were missing after bulk cleanup; each was restored because the app cannot start without them:

| File / path | Why it exists |
|---|---|
| `next.config.mjs` | Next.js 16 entry point |
| `postcss.config.mjs` | Tailwind/PostCSS pipeline (Next.js requires it) |
| `.gitignore` | Windows/Docker-relevant ignore rules |
| `config/i18n.json` | Statically imported by `src/i18n/config.ts` |
| `scripts/i18n/generate-global-error-messages.mjs` | Imported by `scripts/build/build-next-isolated.mjs` during `npm run build` |
| `scripts/build/sync-env.mjs` | Shim re-exporting `../dev/sync-env.mjs`; required by `postinstall.mjs` |

> Note: Some runtime defaults (payload rules, Alibaba allowlist) no longer ship as files; the code falls back to embedded defaults, which is acceptable for this fork.

### Repository / Git

- `.git` re-initialized as a new repository (`git init -b main`)
- `origin`: `https://github.com/sreza26/OmniRoute-MSR-MOD_Slim-Full.git`
- `node_modules`, `dist/`, `.build/`, `.next/` ignored from Git
- 7,627 files staged and ready for the first commit; nothing has been committed or pushed yet
- GitHub identity comes from global config (`S.R.A.N` / `sreza26@gmail.com`)

## Running locally (Windows)

### Prerequisites

- Node.js **24.x** or **26.x** (engines: `>=24.0.0 <27`)
- npm 11.x
- Windows 10/11

### Development

```powershell
npm install --legacy-peer-deps --no-audit --no-fund
npm run dev
```

The dashboard will be available at <http://localhost:3000>.

### Production (standalone)

```powershell
npm run build
npm run start
```

### Docker

```powershell
docker compose --profile base up -d --build
```

Profiles in `docker-compose.yml` include `base`, `web`, `cli`, and other optional sidecars. See `Dockerfile` and `docker-compose.yml` comments for details.

## Useful paths

| Path | Purpose |
|---|---|
| `src/` | Application source (Next.js App Router) |
| `open-sse/` | OpenAI-compatible SSE gateway services |
| `scripts/` | Dev, build, and check scripts (transitive-closure verified) |
| `docker/` | Docker assets and helper scripts |
| `bin/` | CLI binaries (`omniroute`, `reset-password`) |
| `config/` | Remaining static configuration (only `cli-tools-manifest.json`) |
| `.env.example` | Template environment variables |

## Verification performed

- Transitive import closure across `scripts/` entry points: **0 missing imports**
- `package.json` scripts reference only files that exist on disk
- `npm install` resolves the lockfile cleanly; `node_modules` installs successfully
- `node_modules` remains excluded from Git via `.gitignore`

## Known issues / acceptable degradation

- `open-sse/services/payloadRules.ts` loads `config/payloadRules.json` at runtime; if the file is missing it falls back to built-in defaults
- `open-sse/services/alibabaFreeTierAllowlist.ts` behaves the same way
- Removed Docker CLIs (`docker/devin-bridge/*`) are still present but unmaintained; they were left intact to avoid breaking compose profiles
- This fork does not ship upstream's changelog, docs, or test suite; see upstream for full history

## Contributing / Upstream

This is a personal slimmed fork and does **not** track upstream branches. If you want to sync upstream changes, merge manually from `upstream` (`https://github.com/cheaper-inference/OmniRoute.git`) or open GitHub Desktop and use the remote directly.

## License

Original OmniRoute source is MIT-licensed by Diego Souza. This fork inherits the same upstream license headers where present.
