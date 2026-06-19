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

## Priority 0 — Correctness and Drift Prevention

### P0.1 — Fail CI when committed synchronized files are stale

- [ ] Run `bash scripts/keymapsync.sh` in CI.
- [ ] Immediately run `git diff --exit-code` after synchronization.
- [ ] Print a clear failure message explaining that derived board files must be synchronized and committed.
- [ ] Document the same check in `getting-started.md`.

**Why:** The current workflow builds from a corrected synchronized workspace, but a contributor can still leave stale derived files committed to the repository.

**Acceptance criteria:**

- A pull request that changes a shared Go60 binding without committing the corresponding Glove80 and SliceMK changes fails CI.
- A fully synchronized pull request passes without producing a diff.

---

### P0.2 — Add regression tests for `keymapsync.sh`

Create fixture-based tests covering:

- [ ] Zero-parameter bindings such as `&gresc`.
- [ ] Single-parameter bindings such as `&kp A`.
- [ ] Multi-parameter bindings such as HRM behaviors.
- [ ] Inline comments and block comments.
- [ ] Preservation of target-board-only positions.
- [ ] SliceMK `&magic` to `&none` rewriting.
- [ ] Preservation of surrounding DTS structure.
- [ ] Preservation of readable alignment and formatting.
- [ ] Idempotency: a second sync produces no additional changes.
- [ ] Clear failure behavior for malformed bindings blocks.

**Acceptance criteria:**

- Tests run in CI before firmware builds.
- A parser regression can be reproduced locally from a small fixture rather than a full keyboard configuration.

---

### P0.3 — Validate translation maps explicitly

Add validation for:

- [ ] Duplicate source indices.
- [ ] Duplicate destination indices.
- [ ] Source indices outside the Go60 binding range.
- [ ] Destination indices outside the target board binding range.
- [ ] Missing mappings for expected shared logical positions.
- [ ] Translation-map entries that disagree with `positions.dtsi` logical names.
- [ ] Reverse-map consistency where reverse maps exist.

**Acceptance criteria:**

- CI fails with the exact map file and offending entry.
- All shared logical positions are proven to map consistently across supported boards.

---

### P0.4 — Correct current documentation drift

- [ ] Reconcile firmware artifact retention values between `docs/ci-cd-pipeline.md` and `.github/workflows/build.yml`.
- [ ] Recheck documented layer counts.
- [ ] Recheck board key counts.
- [ ] Recheck artifact names and output paths.
- [ ] Recheck filenames and translation-map extensions.
- [ ] Add a lightweight documentation verification checklist for future architecture changes.

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

- [ ] Run keymap synchronization.
- [ ] Report whether synchronization changed tracked files.
- [ ] Run structural validation.
- [ ] Optionally run fixture tests.
- [ ] Provide a concise pass/fail summary.

**Acceptance criteria:**

- Contributors have one documented command that matches the important CI checks.

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

- [ ] Add a pre-commit hook or documented hook installer.
- [ ] Run synchronization and drift detection before commit.
- [ ] Keep the hook optional; CI remains authoritative.

**Acceptance criteria:**

- Contributors can catch stale synchronized files before pushing.
- Skipping local hooks cannot bypass CI enforcement.

---

### P3.4 — Add ownership and review guidance

- [ ] Add `CODEOWNERS` or equivalent review guidance for high-risk files.
- [ ] Require deliberate review for translation maps, sync logic, validation, and CI changes.
- [ ] Document expected review checks for adding a board or changing logical position mappings.

**Acceptance criteria:**

- High-impact architectural files are easy to identify during review.

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
