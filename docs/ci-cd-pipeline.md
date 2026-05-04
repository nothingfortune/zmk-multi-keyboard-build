# CI/CD Pipeline

Use this guide when you want to understand the GitHub Actions workflow, debug a failed run, or extend the pipeline for a new board.

If you just want to make a normal keymap change, you do not need this file first. Use [getting-started.md](../getting-started.md).

This repo has CI, but only a light form of CD.

What it does today:

- runs sync, validation, and firmware builds on GitHub Actions
- publishes built firmware as downloadable artifacts
- supports `push` to `main`, all pull requests, and manual `workflow_dispatch`

What it does not do today:

- it does not deploy firmware anywhere automatically
- it does not publish releases or flash devices
- it does not push generated synced files back into the repo

So the pipeline is best understood as:

- CI = sync + validate + build
- CD = artifact delivery only

---

## Workflow file

The pipeline lives in:

- `.github/workflows/build.yml`

It is triggered by:

- pushes to `main`
- any pull request
- manual runs from GitHub Actions via `workflow_dispatch`

---

## High-level job graph

The workflow runs in four stages:

1. `sync-keymaps`
2. `validate`
3. `build-go60`, `build-glove80`, and `build-slicemk` in parallel
4. artifact upload from each build job

In dependency form:

```text
push / pull_request / workflow_dispatch
            |
            v
      sync-keymaps
            |
            v
         validate
        /    |    \
       v     v     v
 build-go60 build-glove80 build-slicemk
```

The key design choice is that the build jobs never compile the raw checked-out repo directly. They compile the synced workspace produced by `sync-keymaps`.

That guarantees CI tests the same synchronized state contributors are expected to commit.

---

## Stage 1: `sync-keymaps`

Purpose:

- run `bash scripts/keymapsync.sh`
- turn Go60 into the canonical shared source before validation or build
- publish the resulting synced workspace as an internal artifact for downstream jobs

What the job does:

1. checkout the repo
2. run `bash scripts/keymapsync.sh`
3. upload the entire workspace as the `synced-workspace` artifact

Important behavior:

- Go60 shared layer changes are propagated into Glove80 and SliceMK using the translation maps
- board-only target positions are preserved because unmapped keys are untouched by sync
- SliceMK gets its `&magic` rewrite during sync, not during validation or build

Artifact produced:

- `synced-workspace`

Retention:

- 1 day

This artifact is not the final firmware deliverable. It is the internal handoff between jobs.

---

## Stage 2: `validate`

Purpose:

- fail fast before any firmware build starts
- validate the synchronized workspace rather than the pre-sync checkout

What the job does:

1. download `synced-workspace`
2. run `bash scripts/validation.sh`

What validation is gating:

- required file presence
- layer file presence and include counts
- binding counts per board
- include ordering and wrapper placement
- shared include presence
- layer constant and reference sanity
- board-specific exclusions like SliceMK's magic constraints

If validation fails, none of the build jobs run.

This is the main protection against building firmware from a structurally invalid repo state.

---

## Stage 3: Board build jobs

All build jobs depend on `validate`, so they only run after the synced workspace is known-good.

### `build-go60`

Purpose:

- build Go60 firmware through Nix against `moergo-sc/zmk`

What the job does:

1. download `synced-workspace`
2. checkout `moergo-sc/zmk` into `src/`
3. install Nix
4. configure the `moergo-glove80-zmk-dev` Cachix cache
5. run:

```sh
nix-build build/go60.nix --arg firmware 'import ./src {}' -o result-go60
```

Artifact produced:

- `go60-firmware`

Uploaded file:

- `result-go60/go60.uf2`

Retention:

- 90 days

### `build-glove80`

Purpose:

- build Glove80 firmware through Nix against the same MoErgo fork

What the job does:

1. download `synced-workspace`
2. checkout `moergo-sc/zmk` into `src/`
3. install Nix
4. configure the same Cachix cache
5. run:

```sh
nix-build build/glove80.nix --arg firmware 'import ./src {}' -o result-glove80
```

Artifact produced:

- `glove80-firmware`

Uploaded file:

- `result-glove80/glove80.uf2`

Retention:

- 90 days

### `build-slicemk`

Purpose:

- build SliceMK firmware via west against its own fork/toolchain path

What the job does:

1. download `synced-workspace`
2. run inside the `zmkfirmware/zmk-build-arm:stable` container
3. create `.ci-build/slicemk`
4. restore or populate cached west directories
5. run `west init -l config`
6. run `west update --fetch-opt=--filter=tree:0`
7. run `west zephyr-export`
8. run `west build` with the board and shield from the repo config

Build output path:

- `.ci-build/slicemk/zephyr/zmk.uf2`

Artifact produced:

- `slicemk-firmware`

Retention:

- 90 days

---

## Caching and performance

The pipeline uses different acceleration paths for the two build families.

### Nix jobs

Go60 and Glove80 use:

- `cachix/install-nix-action`
- `cachix/cachix-action`
- cache name `moergo-glove80-zmk-dev`

This avoids rebuilding the entire dependency stack from scratch on every run.

### west job

SliceMK uses `actions/cache` for these directories:

- `modules/`
- `tools/`
- `zephyr/`
- `bootloader/`
- `zmk/`

The cache key is based on `config/west.yml`, so dependency changes invalidate the cache naturally.

---

## Artifacts and what users download

There are two artifact classes in the workflow.

### Internal handoff artifact

- `synced-workspace`

Used only inside the workflow so downstream jobs all operate on the same synced tree.

### User-facing firmware artifacts

- `go60-firmware` → `go60.uf2`
- `glove80-firmware` → `glove80.uf2`
- `slicemk-firmware` → `zmk.uf2`

These are what users should download from the Actions run page.

---

## Why the pipeline syncs before validate/build

This is the most important architectural point in the workflow.

The repo treats Go60 as the source of truth for shared layer content. That means the pipeline should not validate or build a stale tree where Go60 changed but the target boards were not yet synchronized.

So CI deliberately does this order:

1. sync derived board layer files from Go60
2. validate the synchronized tree
3. build firmware from that synchronized tree

Without that order, CI would either:

- validate inconsistent board trees
- build stale derived layers
- or require every contributor to manually keep target layers perfect before every push

The current design removes that drift from the build path.

---

## What happens on pull requests vs `main`

The same workflow runs for both pull requests and pushes to `main`.

Practical difference:

- PR runs are for review and verification
- `main` runs are the ones most users treat as the canonical downloadable firmware outputs

The workflow can also be run manually via `workflow_dispatch` if you want a rebuild without creating a new commit.

---

## Failure modes and where to look

### Sync fails

Look at:

- `sync-keymaps` job
- `scripts/keymapsync.sh`
- `boards/translations/`

Typical causes:

- malformed translation map
- missing target layer file
- target-specific rewrite logic needed for a fork incompatibility

### Validation fails

Look at:

- `validate` job
- `scripts/validation.sh`

Typical causes:

- binding counts no longer match `positions.dtsi`
- layer includes or wrapper blocks are wrong
- board-specific exclusions were violated

### Build fails only for one board

Look at the board-specific build job:

- `build-go60`
- `build-glove80`
- `build-slicemk`

Typical causes:

- fork-specific header differences
- unsupported feature on one board
- incorrect board or shield wiring
- stale build config after adding a new board or layer

---

## How to extend the pipeline for a new board

When adding a new board, CI changes are part of the integration work, not an afterthought.

At minimum you need to update:

1. `scripts/keymapsync.sh` so the new board participates in the sync stage
2. `scripts/validation.sh` so the new board is covered by the validation gate
3. the build workflow so the new board has a build job or is included in the right build path
4. repo docs so artifact names and build expectations stay accurate

### If the new board follows the Nix path

Usually add:

- `build/<board>.nix`
- a new build job in `.github/workflows/build.yml`
- a corresponding artifact upload step

### If the new board follows the west path

Usually add:

- board/shield/config wiring under `config/` and possibly `build.yaml`
- a west build step or a new west build job in `.github/workflows/build.yml`
- cache coverage if it uses the same west workspace layout

### Pipeline design rule for new boards

The new board must build from the synced workspace, not from the raw checkout.

If a new job bypasses `synced-workspace`, it is no longer testing the same derived state as the rest of the repo.

---

## Local build vs CI build

Local builds are useful for iteration, but CI is the authoritative integrated path because it always runs:

- sync
- validation
- board builds in the expected workflow order

If local and CI behavior differ, trust CI first and then explain the difference.

---

## References

- `.github/workflows/build.yml`
- `scripts/keymapsync.sh`
- `scripts/validation.sh`
- `build/go60.nix`
- `build/glove80.nix`
- `build.yaml`
- `config/west.yml`