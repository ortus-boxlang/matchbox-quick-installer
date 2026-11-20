# MatchBox Quick Installer — Agent Instructions

## Project overview

This repository builds **MVM**, the MatchBox Version Manager, and the cross-platform installers that bootstrap it. MVM is a BoxLang program (`src/mvm.bxs`) compiled to a native executable by MatchBox. It installs MatchBox releases side by side under `~/.mvm` (`MVM_HOME`), switches the active version through `~/.mvm/current`, and wires `matchbox` into the user's PATH and shell initialization. MatchBox's own runtime home defaults to `~/.matchbox` (`MATCHBOX_HOME`).

The installers bootstrap MVM from GitHub release artifacts:

- `install/install.sh` — Linux/macOS curl-to-bash installer (Bash, Zsh, Fish, PowerShell shell init).
- `install/install.ps1` — Windows PowerShell installer.
- `src/mvm.bxs` — all MVM CLI behavior: install/use/list/remove, remote listing, snapshot refresh, `.mvmrc` pinning, self-update, doctor, TUI, shell init/completions, checksum verification, update checks.
- `build.sh` — injects build metadata and compiles `src/mvm.bxs` to `build/mvm` (or `build/mvm.exe`).
- `tests/` — shell, PowerShell, TestBox, Python release-install, and Docker distro smoke suites.
- `.github/workflows/release.yml` — test matrix, native builds, snapshot/stable releases.

## Commands

```bash
./build.sh                              # Build build/mvm (needs matchbox or MATCHBOX_BIN)
MATCHBOX_BIN=/path/to/matchbox ./build.sh
./tests/integration/run.sh              # Full integration suite (MatchBox, CommandBox/TestBox, Python, network)
pwsh -File tests/powershell/run.ps1     # PowerShell installer tests (Windows or PowerShell 7+)
./tests/run-all.sh [debian|ubuntu|fedora|arch]  # Docker smoke suite; no arg runs all four
sh tests/run.sh                         # Inner container runner: builds MVM and runs the shell spec
boxlang check --source ./src            # Syntax-check BoxLang after every edit to mvm.bxs
boxlang format --check --source ./src   # Verify formatting
```

`tests/integration/run.sh` builds the binary first, exercises real GitHub releases via `tests/integration/test_release_install.py`, then runs the TestBox spec in `tests/specs/MvmCliSpec.bx`. Set `GITHUB_TOKEN`/`GH_TOKEN` to avoid unauthenticated API rate limits. The Linux distro matrix requires Docker in Linux-container mode; MVM's native binary is glibc-linked, so Alpine is intentionally excluded.

## Build and version conventions

- `box.json` holds the authoritative version (currently `2.0.1-snapshot`) and the `build`/`test` scripts.
- `build.sh` replaces the `MVM_VERSION`, `MVM_COMMIT`, and `MVM_BUILT_ON` constants in `src/mvm.bxs` in a generated `build/mvm.bxs`, then compiles with `matchbox --target native`. Never edit generated files under `build/`.
- Branch determines the published version: `main` strips `-snapshot`, `development` ensures it. Override with `MVM_VERSION`, `MVM_COMMIT`, `MVM_BUILT_ON`, or `MVM_OUTPUT` when testing.
- Keep installers and MVM in sync: a change to paths, environment variables (`MVM_HOME`, `MATCHBOX_HOME`, `MVM_VERSION`, `GITHUB_TOKEN`/`GH_TOKEN`), shell init, or CLI flags usually needs matching changes in the install scripts, tests, and README.
- Downloads must have published `version.json` metadata plus a matching SHA-256 checksum. Never bypass verification or let a failed check replace an installed version.
- Preserve cross-platform behavior: Unix uses `sha256sum` (Linux) and `shasum` (macOS); Windows uses `Get-FileHash`. Quote paths, tolerate spaces, and test both path styles.
- Prefer small, direct changes with no compatibility shims for old behavior. Update the tests alongside behavior changes.

## Skills — read before you work

Domain instructions live in `.agents/skills/<name>/SKILL.md`, pinned by `skills-lock.json`. The skill directories are gitignored; restore them with `npx skills experimental_install`. When a task matches a skill below, **load that SKILL.md first** and follow it; prefer the most specific skill.

### MVM and MatchBox (highest priority here)

- **`matchbox-mvm`** — MVM install/use flows, `.mvmrc` pinning, `mvm doctor`, self-update, verified downloads, and CI usage.
- **`boxlang-runtime-matchbox`** — MatchBox runtime, targets, CLI, runtime differences from BoxLang on the JVM.
- **`boxlang-runtime-compiled-native-binaries`** — `--target native` compilation, packaging native builds, release artifacts.
- **`matchbox-native-fusion`** — Rust BIFs/classes exposed to BoxLang through Native Fusion.
- **`boxlang-runtime-cli-scripting`** — BoxLang CLI scripts, arguments, REPL, runtime-context detection.
- **`boxlang-syntax-check`** — `boxlang check` workflow for every `.bx`/`.bxs` edit; pairs with formatting checks.

### BoxLang language and code quality

- **`boxlang-language-fundamentals`** — syntax, scopes, operators, control flow, exceptions, type system.
- **`boxlang-best-practices`** — naming, structure, scoping, error handling, performance, maintainability.
- **`ortus-coding-standards`** — official Ortus formatting and style for BoxLang/CFML/Java.
- **`boxlang-classes-and-oop`** — classes, components, interfaces, inheritance, annotations, constructors.
- **`boxlang-functional-programming`** — lambdas, closures, pipelines, destructuring, spread syntax.
- **`boxlang-code-documenter`** — DocBox-compatible Javadoc-style comments and docs.
- **`boxlang-code-reviewer`** — structured reviews for correctness, security, performance, style.
- **`boxlang-security`** — injection prevention, secrets, file uploads, secure coding patterns.

### Installer implementation support

- **`boxlang-file-handling`** — file/directory reads, writes, moves, listings, streaming.
- **`boxlang-configuration`** — runtime settings, environment overrides, modules, logging, schedulers.
- **`boxlang-deployment`** — deployment options and version-manager context.
- **`boxlang-runtime-github-actions`** — `setup-boxlang`, CI workflows, multi-engine testing.
- **`boxlang-testing`** — TestBox BDD/xUnit specs, mocking, reporters, CLI runner.

### Other available BoxLang skills

- **`boxlang-application-descriptor`** — Application.bx discovery, lifecycle, sessions, mappings.
- **`boxlang-async-programming`** — BoxFuture, executors, schedulers, threads, parallel pipelines.
- **`boxlang-caching`** — cache providers, BIFs, regions, TTL, distributed locking.
- **`boxlang-cfml-migration`** — CFML → BoxLang differences, compatibility module, migration fixes.
- **`boxlang-database-access`** — queryExecute, datasources, transactions, SQL injection prevention.
- **`boxlang-docbox`** — generating HTML/JSON/UML API documentation with DocBox.
- **`boxlang-file-watchers`** — watcher BIFs, event payloads, debounce/throttle tuning.
- **`boxlang-interceptors`** — interceptor/event system, custom announcement points.
- **`boxlang-java-integration`** — createObject, static calls, type conversion, Java libraries.
- **`boxlang-modules-and-packages`** — `box install`, module config, premium modules, introspection.
- **`boxlang-scheduled-tasks`** — Scheduler DSL, cron expressions, lifecycle callbacks.
- **`boxlang-templating`** — `.bxm` templates and template components.
- **`boxlang-web-development`** — web lifecycle, request/response, routing, REST, HTTP clients.
- **`boxlang-zip`** — creating, extracting, and filtering ZIP archives.

### Platform and runtime deployment skills

- **`boxlang-runtime-aws-lambda`** — AWS Lambda handlers, manifest, SAM local testing.
- **`boxlang-runtime-azure-functions`** — Azure Functions handlers and local development.
- **`boxlang-runtime-chromebook`** — Chromebook Linux setup for BoxLang development.
- **`boxlang-runtime-commandbox`** — CommandBox servers, `server.json`, SSL, rewrites.
- **`boxlang-runtime-desktop-electron`** — Electron + MiniServer desktop apps.
- **`boxlang-runtime-digitalocean-app`** — DigitalOcean App Platform starter architecture.
- **`boxlang-runtime-docker`** — container images, MiniServer in Docker, Compose.
- **`boxlang-runtime-esp32`** — ESP32 target, flashing, hardware BIFs.
- **`boxlang-runtime-google-cloud-functions`** — GCF Gen 2 handlers and invoker.
- **`boxlang-runtime-jsr-223`** — embedding BoxLang in Java via the scripting API.
- **`boxlang-runtime-miniserver`** — MiniServer config, health checks, env overrides.
- **`boxlang-runtime-spring-boot`** — Spring Boot integration and view resolution.
- **`boxlang-runtime-wasm-container`** — server-side WASM and minimal OCI images.
- **`boxlang-runtime-wasm-in-the-browser`** — browser/Node.js WASM and JS ES modules.

## Agent workflow

1. Load the relevant skill(s) from the catalog above before editing or reviewing code.
2. Make the change in `src/`, `install/`, `tests/`, or docs — never in `build/` or `testbox/`.
3. Run `boxlang check --source ./src` after BoxLang edits; then build and run the narrowest relevant test suite.
4. Verify cross-platform behavior and README consistency when changing installer or CLI behavior.
