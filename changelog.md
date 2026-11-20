# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

### Added

- MatchBox `snapshot` channel: `mvm install snapshot` and `mvm use snapshot` track the rolling development build by build ID and revision, refresh only when the published build changes, and honor `--force`. Version listings and `mvm current` show the recorded build identity.
- SHA-256 verification of release downloads using `version.json` metadata plus a matching checksum (`sha256sum`, `shasum`, or PowerShell `Get-FileHash`). Releases without metadata cannot be newly installed, and a failed check leaves the active version untouched.
- `MATCHBOX_HOME` initialization: shell initialization exports both `MVM_HOME` and `MATCHBOX_HOME`, adds both `bin` directories to `PATH`, and preserves values already set in the environment.
- PowerShell installer test suite, CI report helper, and a Docker smoke suite for Debian, Ubuntu, Fedora, and Arch.
- Branded interactive installer experience: a plan summary, confirmation prompt, and `--yes` / `MVM_NON_INTERACTIVE=1` support for scripted installs, with clearer cancellation messages on both Unix and Windows.
- Repository agent instructions (`AGENTS.md`) with a catalog of the pinned BoxLang and MatchBox skills, plus editor and Markdown configuration.

### Changed

- CI now runs the integration suite across Linux, macOS, and Windows (x64 and arm64) before building native executables.
- Interactive MatchBox downloads use range requests and display a progress bar; non-terminal downloads keep the previous behavior.

### Fixed

- Authenticate GitHub API calls in CI with `GITHUB_TOKEN` / `GH_TOKEN` to avoid rate limits.
- Tighten CI assertions and make tests portable: BSD-compatible `script` usage on macOS, skipping Windows-incompatible specs, preserving the PowerShell suite list, and setting process `PATH` in the Windows installer test.

## [2.0.1] - 2026-09-25

### Changed

- Moved shell setup out of the installers and into MVM: installation and `mvm doctor --fix` now install shell initialization for Bash, Zsh, Fish, or PowerShell, plus Bash completions.
- `mvm doctor` now checks shell initialization alongside `PATH` and the active installation, and reports completion status on Linux/macOS.
- Updated integration tests and documentation for the self-managed shell initialization flow.

## [2.0.0] - 2026-09-24

The `v2.0.0-snapshot` prerelease was published from `development` with these changes.

### Added

- Bash completions for commands and installed versions, installed by the shell installer and repaired by `mvm doctor --fix`.
- Branch-based release versioning: `development` publishes `-snapshot` prereleases and `main` publishes stable releases. Build metadata (`MVM_VERSION`, `MVM_COMMIT`, `MVM_BUILT_ON`) is injected by `build.sh` and shown by `mvm version`.

### Changed

- Install scripts select the latest stable MVM release by default, or an exact version through `MVM_VERSION`.
- macOS installs connect `.bash_profile` to `.bashrc` when needed for login Bash.

## [0.1.4] - 2026-09-24

### Fixed

- Guard the startup update-check timestamp so an invalid or missing value does not break MVM startup.

## [0.1.3] - 2026-09-24

### Added

- `mvm update` self-update flow: stable builds track stable releases and snapshot builds track snapshots, with a daily prompt in interactive terminals.

## [0.1.2] - 2026-09-24

### Added

- `mvm clean` to clear temporary downloads without removing installed versions.
- `mvm update` command surface and the doctor command extensions supporting the update flow.

## [0.1.1] - 2026-09-24

### Fixed

- Expose the active MatchBox version on `PATH` through `mvm use` and `mvm exec`.

## [0.1.0] - 2026-09-24

### Added

- Initial MVM CLI: `help`, `version`, `current`, `local` (`.mvmrc` project pinning), `use`, `list`, `list-remote`, `install`, `exec`, `remove`, and the interactive version browser (`tui`).
- Side-by-side MatchBox installation under `~/.mvm` with `MVM_HOME` overrides, a cache, and a current-version marker.
- Cross-platform quick installers for Linux/macOS (`install/install.sh`) and Windows (`install/install.ps1`).
- GitHub Actions release pipeline with native Linux, macOS, and Windows binaries, plus a TestBox integration suite.

[Unreleased]: https://github.com/ortus-boxlang/matchbox-quick-installer/compare/v2.0.1...HEAD
[2.0.1]: https://github.com/ortus-boxlang/matchbox-quick-installer/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/ortus-boxlang/matchbox-quick-installer/compare/v0.1.4...v2.0.0
[0.1.4]: https://github.com/ortus-boxlang/matchbox-quick-installer/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/ortus-boxlang/matchbox-quick-installer/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/ortus-boxlang/matchbox-quick-installer/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/ortus-boxlang/matchbox-quick-installer/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/ortus-boxlang/matchbox-quick-installer/releases/tag/v0.1.0
