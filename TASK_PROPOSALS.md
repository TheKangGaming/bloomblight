# Task Proposals from Codebase Review

## 1) Typo Fix Task
**Issue found:** In `scenes/level/game.gd`, a comment reads `"Tweak this number ... until it hits the exact tile  want"`, which is missing the word `you`.

**Proposed task:**
- Update the comment to `"...until it hits the exact tile you want"`.
- Do a quick pass for nearby comments in the same file to fix minor readability typos in developer-facing text.

**Why this matters:**
- Reduces ambiguity and improves maintainability for future contributors reading gameplay/tool-use logic.

## 2) Bug Fix Task
**Issue found:** In `_on_seed_chosen_from_menu`, inventory is decremented immediately after `_on_player_seed_use(...)`, even if planting fails (for example, if the target tile is occupied and `_on_player_seed_use` returns early).

**Proposed task:**
- Refactor `_on_player_seed_use` to return a success boolean (`true` when planting occurs, `false` when blocked).
- Only decrement `Global.inventory[seed_type]` and emit `inventory_updated` when planting succeeds.
- Add a guard to prevent inventory from going below zero.

**Why this matters:**
- Prevents accidental seed loss and ensures player inventory stays consistent with world state.

## 3) Comment/Documentation Discrepancy Task
**Issue found:** In `GameBoard/Grid.gd`, the comment in `calculate_map_position` references `"correct 32x32 Inspector values"`, while the exported `cell_size` default in the same resource is `Vector2(80, 80)`.

**Proposed task:**
- Rewrite the comment to be value-agnostic (e.g., "uses the current inspector-configured cell size dynamically").
- Ensure all nearby comments describe behavior rather than hard-coded tile-size assumptions.

**Why this matters:**
- Avoids misleading documentation and prevents confusion when tuning grid settings.

## 4) Test Improvement Task
**Issue found:** There are currently no automated tests validating seed-planting/inventory behavior.

**Proposed task:**
- Add unit or integration tests for planting flow that verify:
  - Inventory decrements only on successful plant placement.
  - Inventory does not decrement when planting fails due to occupied tile.
  - Inventory never becomes negative.
- Add a regression test for the above bug to prevent reintroduction.

**Why this matters:**
- Protects core gameplay state transitions and reduces risk of inventory regressions in future refactors.
