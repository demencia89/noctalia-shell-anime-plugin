# Registry Update Script

This directory contains automation scripts for maintaining the plugin registry.

## update-registry.js

Automatically scans plugin directories and updates `registry.json` with current plugin metadata.

### How It Works

1. Scans all directories in the repository root.
2. Looks for `manifest.json` in each directory.
3. Extracts registry-relevant fields.
4. Uses `git log --follow` to preserve `lastUpdated` across manifest moves or renames.
5. Generates an updated `registry.json` with all discovered plugins.
6. Sorts plugins alphabetically by ID for consistent output.

### Automatic Updates

The script runs automatically via GitHub Actions when:

- a `manifest.json` file is modified in any plugin directory
- changes are pushed to the `main` branch
- manually triggered via workflow dispatch

## Repository Convention

This repo keeps a compatibility `manifest.json` at the repository root for local Noctalia installs. The cataloged plugin still lives in its own subdirectory and is the only directory scanned into `registry.json`.
