# MatchBox Version Manager (MVM)

MVM installs and runs MatchBox releases side by side. It stores versions under `~/.mvm` by default (`MVM_HOME` overrides this).

## Install

Linux and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/ortus-boxlang/mvm/main/install/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/ortus-boxlang/mvm/main/install/install.ps1 | iex
```

The installer adds MVM to your user PATH. Restart your shell afterward.

## Use

```sh
mvm install latest
mvm list
mvm use latest
mvm exec --version
mvm tui
```

Set a project version in `.mvmrc` and activate it with `mvm use`:

```sh
mvm local latest
mvm use
```

Other commands include `list-remote`, `current`, and `remove <version>`. `mvm help` shows the full CLI.

## Build and test

Build with an installed MatchBox compiler, or set `MATCHBOX_BIN` to its path:

```sh
./build.sh
./tests/integration/run.sh
```

The integration suite needs MatchBox, CommandBox (to install TestBox on first run), and network access for real GitHub releases.

## Releases

Pushes to `main` and `development` both run the TestBox integration suite before building native executables for Linux, macOS, and Windows. `main` publishes a stable release using the version in `box.json` (bump it for each release); `development` replaces the `snapshot` prerelease. Quick installers download the latest stable release.
