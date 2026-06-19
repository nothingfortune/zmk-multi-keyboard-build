# Repo Assessment

This document isolates the review of repository explainability, README quality, modularity, and maintenance risk.

This is background and review material. It is not the right first doc for a new contributor.

It is intended to answer two questions:

1. Is the repo modular enough for others to leverage?
2. Are the docs trustworthy enough for someone else to onboard without reverse-engineering the implementation?

---

## Bottom line

The repo architecture is strong. It has a clear source-of-truth model, a clean shared-vs-board-specific split, explicit translation maps, and validation that enforces structure before builds run.

The main weakness is not the design. It is documentation trust. A few stale or incomplete doc surfaces make outsiders stop and verify details against the code when they should be able to keep moving.

---

## Strengths

### 1. Clear source of truth

The repo makes one board canonical for shared layer work:

- `boards/go60/layers/` is the source of truth for shared layer content.
- `scripts/keymapsync.sh` propagates those bindings into Glove80 and SliceMK layer files.

Evidence:

- `boards/go60/`
- `boards/glove80/`
- `boards/slicemk/`
- `scripts/keymapsync.sh`
- `readme.md`

Why this matters:

It prevents three divergent keymaps from becoming three separate products. That is the central modularity win in this repo.

### 2. Shared logic is factored cleanly

Cross-board logic is centralized in `shared/`:

- layer constants in `shared/layers.dtsi`
- behavior definitions in `shared/behaviors.dtsi`
- macros in `shared/macros.dtsi`
- timings in `shared/global_timings.dtsi`
- HRM support in `shared/homeRowMods/`
- combos in `shared/combos/`

Evidence:

- `shared/layers.dtsi`
- `boards/go60/go60.keymap`
- `boards/slicemk/slicemk.keymap`

Why this matters:

The repo is modular in the correct place: behavior logic is shared, while board geometry and hardware concerns remain board-local.

### 3. Board-specific concerns are isolated rather than duplicated

Each board keeps its own:

- `positions.dtsi`
- `position_groups.dtsi`
- `board_meta.dtsi`
- board keymap wrapper

That split is explainable to others because it aligns to real hardware differences instead of arbitrary repo organization.

Evidence:

- `boards/go60/positions.dtsi`
- `boards/glove80/positions.dtsi`
- `boards/slicemk/positions.dtsi`
- `boards/go60/board_meta.dtsi`
- `boards/slicemk/board_meta.dtsi`

### 4. The repo has real structural guardrails

This is not just a convention-driven repo. `scripts/validation.sh` actively checks required files, layer counts, include ordering, shared include placement, label resolution, layer continuity, and cross-board consistency before builds run.

Evidence:

- `scripts/validation.sh`
- `.github/workflows/build.yml`

Why this matters:

Modularity is easier to trust when the repo enforces its own invariants.

---

## Weaknesses

### 1. README trust was weakened by stale details

The README previously described validation with stale counts and deferred SliceMK local build details to upstream documentation. That forced readers to cross-check the code and CI workflow instead of trusting the project docs.

Evidence:

- `readme.md`
- `scripts/validation.sh`
- `.github/workflows/build.yml`

Impact:

This is an onboarding problem, not an architecture problem.

### 2. Some naming requires translation in the reader's head

The layer files use names like `hrm_left_ring.dtsi`, while the shared constants use names like `LAYER_LeftRingy` and `LAYER_LeftMiddy`.

Evidence:

- `shared/layers.dtsi`
- `boards/go60/layers/`

Impact:

Not a correctness issue, but it adds cognitive overhead for new contributors.

### 3. SliceMK remains a special case that readers must learn explicitly

SliceMK excludes shared magic support and uses a different fork and build flow. That is a valid design constraint, but it should be called out early wherever onboarding happens.

Evidence:

- `boards/slicemk/slicemk.keymap`
- `build.yaml`
- `.github/workflows/build.yml`
- `scripts/keymapsync.sh`

Impact:

Without explicit explanation, people assume all three boards behave symmetrically when they do not.

---

## Explainability Assessment

### For an experienced ZMK user

Yes. The repo is explainable and reusable.

An experienced user can infer the main model quickly:

- edit shared layers in Go60
- sync with translation maps
- keep hardware-specific details local to each board
- validate before build

### For a new contributor

Mostly yes, with one caveat.

They need a short, opinionated entry point that answers:

- where to edit first
- what is generated vs canonical
- what must be kept in sync
- what is special about SliceMK

That is why this repo benefits from a dedicated `START-HERE.md` in addition to the fuller guides.

---

## Maintenance Risk Assessment

### Low risk areas

- Shared behavior and macro reuse in `shared/`
- Board-local geometry isolation in `boards/<board>/positions.dtsi`
- CI validation before builds

### Medium risk areas

- Translation-map drift between logical positions and target boards
- Any future change that adds or removes a layer across all boards
- Any documentation that hardcodes counts or implementation facts likely to change

### Highest conceptual risk

The sync architecture depends on contributors respecting the rule that Go60 shared layers are canonical. If people start editing synchronized positions directly on Glove80 or SliceMK, the architecture remains modular in theory but becomes unreliable in practice.

That is a workflow risk, not a code-structure risk.

---

## Recommended documentation stance

Keep the docs layered:

- `START-HERE.md` for the shortest correct entry point
- `getting-started.md` for contributor workflow
- `readme.md` for repository structure and build/reference material
- this document for referenced assessment and rationale

That is a better fit for this repo than trying to make `readme.md` serve as onboarding guide, architecture memo, and maintenance review at the same time.