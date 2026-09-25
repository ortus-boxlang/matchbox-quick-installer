# MatchBox Version Manager (MVM)

MVM installs and runs MatchBox releases side by side. It stores versions under `~/.mvm` by default (`MVM_HOME` overrides this).

## Install

Linux and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/ortus-boxlang/matchbox-quick-installer/main/install/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/ortus-boxlang/matchbox-quick-installer/main/install/install.ps1 | iex
```

The installer defaults to the latest stable release. Set `MVM_VERSION` to an exact version to install a snapshot instead, for example `curl -fsSL https://raw.githubusercontent.com/ortus-boxlang/matchbox-quick-installer/main/install/install.sh | MVM_VERSION=2.0.1-snapshot bash`.

The installer adds MVM to your user PATH and installs a shell initialization script for Bash, Zsh, Fish, or PowerShell. Bash completions are also installed for commands and installed versions. On macOS it connects `.bash_profile` to `.bashrc` when needed for login Bash. Restart your shell afterward. Run `mvm doctor --fix` to install or repair shell initialization and Bash completions.

## Use

```sh
mvm install latest
mvm list
mvm use latest
matchbox --version
mvm exec --version
mvm tui
```

Set a project version in `.mvmrc` and activate it with `mvm use`:

```sh
mvm local latest
mvm use
```

`mvm update` updates MVM itself (stable builds track stable releases; snapshot builds track snapshots). `mvm version` shows the version, source commit, and UTC build time. In interactive terminals, MVM checks daily for a newer release in its channel and asks before updating. To update MatchBox, run `mvm install latest` and `mvm use latest`. `mvm clean` clears temporary downloads without removing installed versions. `mvm doctor` checks PATH, shell initialization, and the active installation; it also reports Bash completion status on Linux/macOS. `mvm doctor --fix` repairs shell initialization and Bash completions. Other commands include `list-remote`, `current`, and `remove <version>`. `mvm help` shows the full CLI.

## Build and test

Build with an installed MatchBox compiler, or set `MATCHBOX_BIN` to its path:

```sh
./build.sh
./tests/integration/run.sh
```

The integration suite needs MatchBox, CommandBox (to install TestBox on first run), and network access for real GitHub releases.

## Releases

Pushes to `main` and `development` both run the TestBox integration suite before building native executables for Linux, macOS, and Windows. `development` uses the next version with a `-snapshot` suffix and updates that versioned prerelease on each push. `main` strips the suffix and publishes the stable version (for example, `2.0.1-snapshot` becomes `v2.0.1`). Bump the development version for the next release cycle. Builds include their commit and UTC build time; installers select latest stable by default, or an exact version via `MVM_VERSION`.
