# Start Here

This is the shortest path into the repo.

Use this file when you want to know where to start. Do not use it as the full reference.

## Most people want one of these

- I want to change a few keys: [getting-started.md](getting-started.md)
- I want to add a whole new board: [docs/add-new-keyboard-layout.md](docs/add-new-keyboard-layout.md)
- I want to understand GitHub Actions or a failed build: [docs/ci-cd-pipeline.md](docs/ci-cd-pipeline.md)
- I want the full repo map: [readme.md](readme.md)

If you only remember one rule, remember this:

- edit Go60 first
- sync after that

This repo is one shared ZMK setup for three keyboards:

- Go60
- Glove80
- SliceMK ErgoDox Lite

## Default workflow

This is the normal path for a small or medium keymap change:

1. Read [getting-started.md](getting-started.md) for the working mental model.
2. Make shared layer changes in `boards/go60/layers/`.
3. Run `bash scripts/keymapsync.sh`.
4. Run `bash scripts/validation.sh`.
5. Push to `main` or open a PR and download artifacts from GitHub Actions.

## Fastest safe checklist

If you just want the short version, do this:

```sh
# 1. Edit the shared layer in Go60
code boards/go60/layers/base.dtsi

# 2. Run sync + drift check + validation + tests in one command
bash scripts/check.sh
```

`scripts/check.sh` mirrors the CI gates. If it passes, commit the synchronized
changes together. (You can still run the individual steps —
`bash scripts/keymapsync.sh` then `bash scripts/validation.sh` — if you prefer.)

## What each doc is for

- [getting-started.md](getting-started.md): your first real change, sync, validate, and firmware download
- [readme.md](readme.md): repo map, board matrix, build reference, and file layout
- [docs/add-new-keyboard-layout.md](docs/add-new-keyboard-layout.md): adding a completely new board and maintaining board-only keys
- [docs/ci-cd-pipeline.md](docs/ci-cd-pipeline.md): GitHub Actions job flow, artifacts, caches, and build gating
- [docs/completedplans/repo-assessment.md](docs/completedplans/repo-assessment.md): architecture and documentation review, not onboarding

## What is canonical

- Shared layer content: `boards/go60/layers/`
- Shared behaviors/macros/timings: `shared/`
- Board-specific hardware details: `boards/<board>/board_meta.dtsi`
- Cross-board position translation: `boards/translations/`
- Structural guardrails: `scripts/validation.sh`

## SliceMK note

SliceMK intentionally excludes shared magic support. Shared `&magic` bindings are rewritten to `&none` during sync for SliceMK targets.