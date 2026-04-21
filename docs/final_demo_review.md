# Final Demo Review

This pass focused on the publisher-facing path from title screen through the loop hub and first battle, with priority placed on clarity, trust, and cohesion over adding new visual effects.

## Validation Notes

- Source audit completed across title flow, loop hub, prompt/tutorial flow, party/items/stages menu, merchants, workshop/quarry, battle forecast/resolution, results, and level-up presentation.
- Godot 4.6.2 console boot completed without new parse/runtime script errors in the latest `godot.log`.
- A full hands-on interactive smoke pass still needs final human QA for feel-based items such as pacing, prompt timing, and controller comfort.

## Findings

### P0

- `Fixed now` Party menu still contained dead `Status / Equipment / Skills` and `Items / Equipment` subview scaffolding underneath the simplified demo UI.
  - Result: removed the hidden subview code and scene nodes from [main_menu.gd](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/main_menu.gd) and [main_menu.tscn](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/main_menu.tscn), leaving Party as a single overview + equipment-management surface and Items as the only live inventory subview.

- `Fixed now` Party and level-up portraits were not backed by stable character portrait data.
  - Result: added `portrait` assignments to [savannah_data.tres](/C:/Users/kang/Desktop/BloomBlight/bloomblight/data/units/Savannah/savannah_data.tres), [tera_data.tres](/C:/Users/kang/Desktop/BloomBlight/bloomblight/data/units/Tera/tera_data.tres), and [silas_data.tres](/C:/Users/kang/Desktop/BloomBlight/bloomblight/data/units/Silas/silas_data.tres), and kept a scene-frame fallback in [main_menu.gd](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/main_menu.gd) for resilience.

### P1

- `Fixed now` Meal-review tutorial copy still referenced the removed `Status` tab and loop battle copy was slightly stale.
  - Result: updated the relevant tutorial card and prompt copy in [demo_director.gd](/C:/Users/kang/Desktop/BloomBlight/bloomblight/globals/demo_director.gd) so the guidance matches the current Party menu and loop cadence.

- `Fixed now` The battle pause menu still looked like a loose button stack rather than part of the same UI family.
  - Result: wrapped it in a consistent panel/backdrop treatment in [PauseMenu.tscn](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/menus/PauseMenu.tscn) and adjusted [PauseMenu.gd](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/menus/PauseMenu.gd) to the new structure.

- `Fixed now` Party portrait rendering and level-up portrait rendering used smoothing/filtering that made the pixel presentation less crisp than the rest of the demo.
  - Result: switched the active portrait surfaces to nearest-style rendering in [main_menu.tscn](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/main_menu.tscn) and [GameBoard.gd](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/battle/game_board/GameBoard.gd).

### P2

- `Fixed now` Menu defaults and labels still carried a few older values (`Inventory`, default section state) that no longer matched the streamlined demo flow.
  - Result: aligned the active defaults toward `Party / Items / Stages` in [main_menu.gd](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/main_menu.gd) and [main_menu.tscn](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/main_menu.tscn).

- `Fixed now` Repo clutter still included tracked runtime logs and a duplicate, unused logo asset.
  - Result: removed `clean_quit.log`, `godot_run.log`, and the unreferenced `graphics/buildings/blight_&_bloom_logo.png` copy.

### Nice-to-have / Deferred

- `Deferred` Full end-to-end controller feel QA is still best judged interactively after this pass, especially for merchant/workshop scrolling and battle pause usage.
- `Deferred` Larger UI unification across every modal surface could go further with shared theme resources, but that would be a broader refactor than this low-risk final demo pass.
- `Deferred` Android/touch support remains a separate compatibility project and was intentionally left out of this final publisher-demo stabilization pass.

## Growth, Leveling, and Combat Trust Review

### Ally growth roles

- Savannah (`Deserter`) reads coherently as a balanced frontline skirmisher.
  - Strongest growths: HP `55`, SPD `45`, STR `45`, DEX `40`.
  - Conclusion: healthy for a dependable starter frontliner without forcing a pure tank identity.

- Tera (`Purifier`) reads coherently as a support caster.
  - Strongest growths: INT `60`, MDEF `50`, HP `50`, SPD `40`.
  - Conclusion: the current growths support Bloom utility and magical identity without blurring into a frontline role.

- Silas (`Archer`) reads coherently as a high-accuracy follow-up unit.
  - Strongest growths: DEX `70`, SPD `55`, HP `50`, STR `40`.
  - Conclusion: his crit/hit fantasy is reinforced by growths rather than coming only from his Hunt buff.

### Active enemy roles

- The current loop enemy lineup also reads consistently from source:
  - `Bandit Archer` cleanly inherits the Archer role.
  - `Bandit Marauder` intentionally softens pure Tank durability in exchange for more STR/SPD pressure.
  - `Bandit Robber` pushes Warrior stats toward a more aggressive bruiser profile.
- No clear outlier or role contradiction was found in the active enemy resources used by the demo path, so this pass did **not** rebalance growth tables.

### Forecast / live resolution trust

- Forecast and live combat are still aligned in the active path.
  - Forecast is built in [combat_calculator.gd](/C:/Users/kang/Desktop/BloomBlight/bloomblight/data/combat/combat_calculator.gd).
  - Resolution is also built from the same calculator path.
  - Follow-ups continue to use the same `FOLLOW_UP_SPEED_DIFF` comparison in both forecast and strike resolution.
  - Crit chance is still computed per strike, which explains why doubles can feel “crit-heavy” even when the displayed number itself is correct.

### Level-up overlay trust

- With portraits now sourced from actual `CharacterData`, the level-up overlay is in a better state for a final demo build.
- The overlay continues to use the prebuilt battle resolution payload, so displayed gains and applied gains remain aligned.

## Tutorial and Prompt Review

- Loop prompts are in the right conceptual place now: teach-once, relevant, and not permanently nagging.
- Story and loop tutorial copy now better matches the real menu vocabulary.
- The biggest remaining tutorial risk is not wording, but sequencing/feel, which needs a final human fresh-run pass to confirm pacing.

## Menu / UI Language Review

- Current design language is strongest where the UI uses:
  - dark charcoal panels
  - warm gold borders
  - large clear headings
  - readable stacked sections
- The biggest cohesion gain in this pass came from removing hidden obsolete structures rather than adding more ornament.
- The Party menu now reads more honestly as a single “review your team and gear” surface.

## Recommended Final Manual QA Before Shipping

1. Fresh run: confirm prompts/tutorials appear once and in the intended order.
2. Party menu: mouse and controller pass for selection, scrolling, and equipment changes.
3. First battle: confirm forecast, doubles, tutorials, results, and level-up overlay.
4. Night save/load: confirm music, prompts, and structure states remain in sync.
5. Workshop/quarry flow: confirm prompts and interaction coverage feel intuitive in a completely fresh save.
