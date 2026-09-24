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

The installer adds MVM to your user PATH and registers Bash completions for commands and installed versions. On macOS it also connects `.bash_profile` to `.bashrc` when needed for login Bash. Restart your shell afterward. Run `mvm doctor --fix` from Bash on Linux/macOS to install or refresh completions and repair profile registration.

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

`mvm update` updates MVM itself. In interactive terminals, MVM checks daily for a newer stable release and asks before updating. To update MatchBox, run `mvm install latest` and `mvm use latest`. `mvm clean` clears temporary downloads without removing installed versions. `mvm doctor` checks PATH and the active installation, and reports Bash completion status when run from Bash. `mvm doctor --fix` repairs Bash completion setup. Other commands include `list-remote`, `current`, and `remove <version>`. `mvm help` shows the full CLI.

## Build and test

Build with an installed MatchBox compiler, or set `MATCHBOX_BIN` to its path:

```sh
./build.sh
./tests/integration/run.sh
```

The integration suite needs MatchBox, CommandBox (to install TestBox on first run), and network access for real GitHub releases.

## Releases

Pushes to `main` and `development` both run the TestBox integration suite before building native executables for Linux, macOS, and Windows. `main` publishes a stable release using the version in `box.json` (bump it for each release); `development` replaces the `snapshot` prerelease. Quick installers download the latest stable release.
