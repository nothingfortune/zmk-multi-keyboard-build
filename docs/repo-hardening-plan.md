# Repository Hardening Plan

This file tracks planned work to improve correctness, reproducibility, maintainability, and contributor safety in `zmk-multi-keyboard-build`.

The existing architecture remains the baseline:

1. Go60 is the canonical source for shared layer bindings.
2. `keymapsync.sh` translates shared positions into Glove80 and SliceMK layouts.
3. Board-specific positions and hardware configuration remain local to each board.
4. CI synchronizes, validates, and then builds all firmware targets.

The goal of this plan is to strengthen those guarantees without redesigning the core model.

---

## Status Key

- [ ] Not started
- [~] In progress
- [x] Complete
- [!] Blocked or requires a design decision

---

## Progress (2026-06-19)

Completed this session (locally verified):

- **Live drift fix** — `8586bb5` changed Go60 layers without re-syncing; Glove80/SliceMK
  base/cursor/keypad/mouse were stale and have been regenerated.
- **P0.4** documentation drift, **P0.1** CI drift gate, **P0.3** translation-map
  validation, **P0.2** keymapsync fixture tests (found + fixed an empty-block abort
  bug), **P3.1** `scripts/check.sh`, **P3.3** optional pre-commit hook, **P3.4**
  CODEOWNERS + review guidance.

Not started (need decisions or upstream facts):

- **P1.1 / P1.2** pin upstream ZMK revisions + build infra — need chosen commit
  SHAs / container digest (the natural decision wall).
- **P1.3** build manifest, **P2.1** board registry, **P2.2 / P2.3** validation
  refactor + language decision, **P3.2** mark synchronized files, **P4.x** delivery.

---

## Priority 0 — Correctness and Drift Prevention

### P0.1 — Fail CI when committed synchronized files are stale

- [x] Run `bash scripts/keymapsync.sh` in CI. (Already run in the `sync-keymaps` job.)
- [x] Immediately run `git diff --exit-code` after synchronization. (Added the "Fail if committed derived files are stale" step in `sync-keymaps`, using `git diff --quiet`.)
- [x] Print a clear failure message explaining that derived board files must be synchronized and committed. (Step emits a `::error::` annotation plus the `git diff --stat`/diff and the fix command.)
- [x] Document the same check in `getting-started.md`. (Added a "Commit the synced files" callout under step 5.)

> **Note:** This gate caught a live drift instance on `main`: commit `8586bb5`
> changed Go60 layers without re-syncing, leaving Glove80/SliceMK
> base/cursor/keypad/mouse stale. The corrected synced files are included in this
> branch.

**Why:** The current workflow builds from a corrected synchronized workspace, but a contributor can still leave stale derived files committed to the repository.

**Acceptance criteria:**

- A pull request that changes a shared Go60 binding without committing the corresponding Glove80 and SliceMK changes fails CI.
- A fully synchronized pull request passes without producing a diff.

---

### P0.2 — Add regression tests for `keymapsync.sh`

Create fixture-based tests covering:

- [x] Zero-parameter bindings such as `&gresc`.
- [x] Single-parameter bindings such as `&kp A`.
- [x] Multi-parameter bindings such as HRM behaviors.
- [x] Inline comments and block comments. (Inline tested with DTS-idiomatic `/* */`; see finding on `//` below.)
- [x] Preservation of target-board-only positions.
- [x] SliceMK `&magic` to `&none` rewriting.
- [x] Preservation of surrounding DTS structure.
- [x] Preservation of readable alignment and formatting.
- [x] Idempotency: a second sync produces no additional changes.
- [x] Clear failure behavior for malformed bindings blocks. (Empty/unparseable block now skips cleanly — see bug fix below.)

Implemented as `tests/keymapsync_test.sh` (18 assertions, run against the real
script via the new `KEYMAPSYNC_REPO_ROOT` override) and wired into the CI
`validate` job before any firmware build.

**Bugs the fixtures surfaced (one fixed, one flagged):**

- **Fixed:** `parse_bindings` returned non-zero on an empty/malformed bindings
  block, which under `set -e` aborted the *entire* sync (later boards never
  synced) instead of skipping that one layer. Added `return 0`. Verified
  behavior-neutral on the real repo (re-sync is a no-op; validation still 319/0).
- **Flagged (not fixed):** `parse_bindings` strips `/* */` but not `//`, while
  `write_bindings` skips `//`. A `//` inline comment in a bindings block would be
  absorbed into the binding and duplicated. No real layer uses `//` (repo is
  `/* */`-idiomatic), so this is latent. Fix would be to strip `//` in
  `parse_bindings` for parser symmetry — left for review.

**Acceptance criteria:**

- [x] Tests run in CI before firmware builds.
- [x] A parser regression can be reproduced locally from a small fixture rather than a full keyboard configuration.

---

### P0.3 — Validate translation maps explicitly

Add validation for:

- [x] Duplicate source indices.
- [x] Duplicate destination indices.
- [x] Source indices outside the Go60 binding range.
- [x] Destination indices outside the target board binding range.
- [x] Missing mappings for expected shared logical positions. (Completeness check: go60 side must cover exactly indices 0..59.)
- [x] Translation-map entries that disagree with `positions.dtsi` logical names. (Resolves each index to its `POS_*` name on both boards and requires equality.)
- [x] Reverse-map consistency where reverse maps exist. (`glove80_to_go60.map` must be the exact inverse of `go60_to_glove80.map`.)

Implemented as `validation.sh` **section 25**; positive (real maps pass) and negative (broken-map fixture flags every failure mode) paths both verified.

**Acceptance criteria:**

- CI fails with the exact map file and offending entry.
- All shared logical positions are proven to map consistently across supported boards.

---

### P0.4 — Correct current documentation drift

- [x] Reconcile firmware artifact retention values between `docs/ci-cd-pipeline.md` and `.github/workflows/build.yml`. (Already 7d firmware / 1d synced-workspace in both; verified consistent.)
- [x] Recheck documented layer counts. (21 total, SliceMK 20 active — consistent across `readme.md`, `getting-started.md`.)
- [x] Recheck board key counts. (60 / 80 / 77 — consistent with `positions.dtsi` and `validation.sh`.)
- [x] Recheck artifact names and output paths. (Fixed SliceMK `firmware`/`.uf2` → `slicemk-firmware`/`zmk.uf2` in `readme.md` and `getting-started.md`.)
- [x] Recheck filenames and translation-map extensions. (Live files are `.map`; the only `.txt` references were in the historical sync-architecture note, now in `docs/completedplans/`. Reverse map `glove80_to_go60.map` clarified as not consumed by sync.)
- [x] Add a lightweight documentation verification checklist for future architecture changes. (Added `docs/doc-verification-checklist.md`.)
- [x] Update and complete top-level repo README.md. (Fixed SliceMK artifact row, removed a stray dangling `&cirque_lh_listener` DTS block, refreshed doc map + repo-layout tree, clarified reverse-map comment.)
- [x] Cleanup docs folder to match current status. Completed planning/assessment notes moved to `docs/completedplans/`; on-hold and living docs kept in `docs/`.

**Acceptance criteria:**

- All hardcoded counts and workflow facts in documentation match the implementation.
- A new contributor does not need to compare docs against CI to determine current behavior.

---

## Priority 1 — Reproducible Builds

### P1.1 — Pin upstream ZMK revisions

- [ ] Pin the MoErgo ZMK checkout to a known commit instead of `main`.
- [ ] Pin the SliceMK ZMK dependency in `config/west.yml`.
- [ ] Record both revisions in build output or a generated manifest.
- [ ] Document the upgrade procedure.

**Acceptance criteria:**

- Rebuilding the same repository commit uses the same upstream ZMK revisions.
- Updating either fork is an explicit reviewed change.

---

### P1.2 — Pin build infrastructure

- [ ] Pin the SliceMK build container by digest rather than `:stable`.
- [ ] Review whether GitHub Actions should be pinned to full commit SHAs.
- [ ] Record Nix channel or dependency revisions explicitly.
- [ ] Add dependency-update automation or a recurring manual review process.

**Acceptance criteria:**

- Build behavior does not change solely because a moving tag or branch changed upstream.
- Dependency updates remain deliberate and maintainable.

---

### P1.3 — Generate a firmware build manifest

For each firmware artifact, include:

- [ ] Repository commit SHA.
- [ ] Board and shield.
- [ ] ZMK fork and revision.
- [ ] Build method and toolchain reference.
- [ ] Configuration checksum.
- [ ] Build timestamp.

**Acceptance criteria:**

- Every downloaded firmware artifact can be traced to the exact source and upstream dependencies used to build it.

---

## Priority 2 — Maintainability

### P2.1 — Add a machine-readable board registry

Create one source of truth for board metadata, including:

- [ ] Board identifier and display name.
- [ ] Key count.
- [ ] Active layer count.
- [ ] Build method: Nix or west.
- [ ] ZMK fork and revision source.
- [ ] Board and shield names.
- [ ] Supported and excluded features.
- [ ] Artifact name and firmware path.
- [ ] Translation-map relationship to the canonical board.

Use this registry to reduce duplicated constants across scripts, workflow configuration, and documentation where practical.

**Acceptance criteria:**

- Adding a board requires changing fewer hardcoded lists and counts.
- Validation and documentation derive stable metadata from the same source.

---

### P2.2 — Split validation by concern

Refactor `scripts/validation.sh` into smaller modules or clearly isolated sections for:

- [ ] Repository structure.
- [ ] Layer and binding counts.
- [ ] DTS include and wrapper rules.
- [ ] Label and behavior resolution.
- [ ] Translation-map validation.
- [ ] Cross-board consistency.
- [ ] Board-specific exclusions.

**Acceptance criteria:**

- Each validation concern can be run and tested independently.
- Failure output identifies the subsystem being validated.
- Adding a new board does not require editing one monolithic script in many unrelated places.

---

### P2.3 — Decide the long-term implementation language

- [ ] Document whether Bash and Perl remain the intended long-term implementation.
- [ ] Define a threshold for migration, such as parser complexity, fixture volume, or contributor friction.
- [ ] If migrating, evaluate Python or TypeScript for structured parsing and automated tests.
- [ ] Avoid migration solely for stylistic reasons; require a measurable maintenance benefit.

**Acceptance criteria:**

- The repository has an explicit decision rather than allowing the parser and validator to grow indefinitely by accident.

---

## Priority 3 — Contributor Safety and Workflow

### P3.1 — Add one local verification command

Create a command such as:

```sh
bash scripts/check.sh
```

It should:

- [x] Run keymap synchronization.
- [x] Report whether synchronization changed tracked files. (Drift check over `boards/glove80/layers` + `boards/slicemk/layers`.)
- [x] Run structural validation.
- [x] Optionally run fixture tests. (Run by default; `--no-tests` to skip.)
- [x] Provide a concise pass/fail summary.

Implemented as `scripts/check.sh`; documented in `getting-started.md` and `START-HERE.md`.

**Acceptance criteria:**

- [x] Contributors have one documented command that matches the important CI checks.

---

### P3.2 — Mark synchronized files clearly

- [ ] Add a generated or synchronized-file notice where practical.
- [ ] State that mapped bindings should be edited in Go60 first.
- [ ] Clarify which target-board positions remain safe to edit directly.
- [ ] Ensure the notice does not interfere with DTS compilation.

**Acceptance criteria:**

- A contributor opening a target-board layer file can immediately tell which content is canonical, synchronized, or board-specific.

---

### P3.3 — Add optional pre-commit protection

- [x] Add a pre-commit hook or documented hook installer. (`.githooks/pre-commit` + `scripts/install-hooks.sh`.)
- [x] Run synchronization and drift detection before commit. (Hook re-syncs and blocks on derived drift; fast-paths commits that don't touch sync inputs.)
- [x] Keep the hook optional; CI remains authoritative. (Opt-in via `core.hooksPath`; `--no-verify` bypasses; CI P0.1 gate is the real enforcement.)

Verified in an isolated repo: fast-path exit 0 with no relevant staged files; regenerate + block (exit 1) when a go60 edit would leave derived files stale.

**Acceptance criteria:**

- [x] Contributors can catch stale synchronized files before pushing.
- [x] Skipping local hooks cannot bypass CI enforcement.

---

### P3.4 — Add ownership and review guidance

- [x] Add `CODEOWNERS` or equivalent review guidance for high-risk files. (`.github/CODEOWNERS`.)
- [x] Require deliberate review for translation maps, sync logic, validation, and CI changes. (CODEOWNERS patterns cover `scripts/`, `boards/translations/`, `tests/`, `boards/go60/`, `shared/layers.dtsi`, `.github/`, `.githooks/`, `build/`, `config/`.)
- [x] Document expected review checks for adding a board or changing logical position mappings. (`docs/review-guidance.md`.)

**Acceptance criteria:**

- [x] High-impact architectural files are easy to identify during review.

---

## Priority 4 — Delivery and Operational Polish

### P4.1 — Improve CI summaries

Add a GitHub Actions job summary containing:

- [ ] Synchronization result.
- [ ] Validation pass, warning, and failure totals.
- [ ] Boards built successfully.
- [ ] Firmware artifact names.
- [ ] Upstream ZMK revisions.
- [ ] Configuration checksum or build manifest link.

**Acceptance criteria:**

- A contributor can understand the result without opening every job log.

---

### P4.2 — Publish stable firmware releases

- [ ] Define a tag convention for stable firmware builds.
- [ ] Publish firmware artifacts to GitHub Releases for tagged builds.
- [ ] Include the firmware build manifest and release notes.
- [ ] Keep ordinary branch builds as short-lived workflow artifacts.

**Acceptance criteria:**

- Stable firmware remains available beyond normal Actions artifact retention.
- Users can identify the exact configuration represented by a release.

---

### P4.3 — Add an end-to-end translation test

- [ ] Change one canonical Go60 binding in a test fixture.
- [ ] Run synchronization.
- [ ] Verify the expected logical position changes on Glove80.
- [ ] Verify the expected logical position changes on SliceMK.
- [ ] Verify target-only positions remain unchanged.
- [ ] Verify all resulting configurations pass validation.

**Acceptance criteria:**

- The complete canonical-layout-to-target-board pipeline is tested as one behavior.

---

## Recommended Execution Order

1. P0.4 — Correct documentation drift.
2. P0.1 — Add the CI synchronization drift gate.
3. P0.3 — Validate translation maps.
4. P0.2 — Add sync regression fixtures.
5. P1.1 and P1.2 — Pin build dependencies.
6. P3.1 — Add one local verification command.
7. P1.3 — Generate firmware manifests.
8. P2.1 — Introduce the board registry.
9. P2.2 and P2.3 — Refactor only after tests protect current behavior.
10. P4 tasks — Improve delivery after correctness and reproducibility are established.

---

## Explicit Non-Goals

- Replacing the Go60 canonical-source model without evidence that it is failing.
- Forcing all boards into one build toolchain.
- Eliminating valid board-specific behavior.
- Rewriting Bash and Perl solely because another language is more fashionable.
- Automatically flashing physical keyboards from CI.

---

## Definition of Done

This hardening plan is complete when:

- committed synchronized files cannot drift silently;
- translation maps and parser behavior have automated regression coverage;
- builds are reproducible from pinned inputs;
- documentation reflects actual workflow behavior;
- contributors have one safe local verification path;
- stable firmware artifacts are traceable to exact source and dependency revisions;
- the architecture remains understandable without relying on the original author’s memory.
