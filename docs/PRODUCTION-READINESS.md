# Production Readiness Guide

This repository ships a local CLI + workflow installer. Production readiness here means:
- deterministic installs and upgrades,
- safe rollback on failure,
- supply chain integrity for downloaded binaries,
- minimum operational docs for install/upgrade/rollback.

## Preconditions (Confirm First)
- Target OSes and architectures to support (linux/darwin/windows, amd64/arm64).
- Whether installs must work offline.
- Whether custom config.json installs use sources outside the repo.
- Compliance requirements (e.g., checksum verification or signed binaries).

## Release and Supply Chain
- Pin wrapper version via `CODEAGENT_WRAPPER_VERSION` in production.
- For security-sensitive environments, publish SHA256 checksums per release and
  install with `CODEAGENT_WRAPPER_SHA256`.
- Avoid `latest` for production rollouts.

## Install / Upgrade
- Primary path: `python3 install.py --install-dir ~/.claude`.
- Installer writes `installed_modules.json` with per-module outcomes.
- If `--force` is used, existing files are backed up before overwrite.

## Rollback
- On failure, installer performs a rollback:
  - Removes newly created files.
  - Restores backups for overwritten files.
- Backups live under `~/.claude/.install-backups/<timestamp>` (per run).

## Observability
- Installer logs to `~/.claude/install.log`.
- Wrapper logs are written to `os.TempDir()` and removed after run by default.
  Set `CODEAGENT_KEEP_LOGS=1` to retain logs for incident analysis.

## Security Baseline
- Installer prevents source/target path escapes by default.
  - Override only if needed: `INSTALL_ALLOW_EXTERNAL_SOURCES=1`
  - Override only if needed: `INSTALL_ALLOW_EXTERNAL_TARGETS=1`
- Avoid enabling `--skip-permissions` unless you understand the risk.

## Backup and Recovery
- Back up `~/.claude` before major upgrades.
- For disaster recovery, restore from your last known-good backup and re-run
  `install.py` pinned to the same version.

## Validation Checklist (Before Go-Live)
- [ ] `install.py --list-modules` works and prints expected modules.
- [ ] Pinned wrapper version installs successfully.
- [ ] All workflows start without errors on a clean machine.
- [ ] Rollback restores original files when install fails.
- [ ] Release artifacts verified via SHA256 (if required).
