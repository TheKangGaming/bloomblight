# Legacy Cleanup Ledger

This pass intentionally removes only provably unused files/assets and trims no-risk dead code. The items below were reviewed and **kept on purpose** because the current loop build still depends on them directly or indirectly.

## Kept for now

- `globals/demo_director.gd`
  - Still owns shared tutorial-card state and input-label helpers used by the current title screen, loop tutorials, pause menu, cooking menu, and battle tutorials.

- `globals/global.gd`
  - Still contains compatibility state for the narrative/day-transition flow:
    - `saved_farm_scene`
    - `pending_day_transition`
    - `pending_combat_scene_path`
    - `intro_sequence_complete`
    - `demo_cabin_built`
    - `demo_merchant_intro_seen`
  - These remain because the old warning/day-two battle handoff is still reachable.

- `scenes/level/day_two_battle.tscn`
  - Still preloaded by `Global` and used by the legacy calendar encounter pipeline.
  - Also remains part of the current inherited battle setup used by `forest_battle.tscn`.

- `scenes/level/map_director.gd`
  - Still attached to `day_two_battle.tscn`, which current battle content still inherits from.

- `scenes/ui/warning_ui.tscn` and `scenes/ui/warning_ui.gd`
  - Still used by the legacy `request_end_day -> warning_ui -> combat` flow in `game.gd`.

- `scenes/level/world.tscn`, `scenes/level/world.gd`
  - Still embedded by `game.tscn` and `day_two_battle.tscn`.

- `scenes/level/forest.tscn`, `scenes/level/forest.gd`, `scenes/level/forest_world.tscn`
  - Still referenced by the old intro/materials forest visit flow.

- `scenes/level/story_actor.tscn`, `scenes/level/story_actor.gd`
  - Still used by `game.tscn`, `forest.tscn`, and current loop purification/arrival cutscene beats.

- `scenes/ui/story_dialogue_box.tscn`, `scenes/ui/story_dialogue_box.gd`
  - Still used by `game.tscn`, `forest.tscn`, and `GameBoard.gd`.

## Safe removals made in this pass

- `scenes/level/combat_board.tscn`
  - Unreferenced and pointed at a missing script (`res://combat_board.gd`).

- `scenes/level/farmmap.tmx`
  - Unreferenced old map asset.

- `scenes/ui/1.png` through `scenes/ui/10.png`
  - Unreferenced stray UI images; only their own import metadata referenced them.

- Hidden Party/Items subview scaffolding inside the live menu scene
  - Removed the unused `PartySubtabs`, `SkillsView`, `InventorySubtabs`, `EquipmentCatalogView`, and related dead script paths from:
    - [main_menu.tscn](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/main_menu.tscn)
    - [main_menu.gd](/C:/Users/kang/Desktop/BloomBlight/bloomblight/scenes/ui/main_menu.gd)

- Repo-root runtime leftovers
  - Removed `clean_quit.log` and `godot_run.log` from the tracked project root.

- Duplicate logo asset
  - Removed unreferenced `graphics/buildings/blight_&_bloom_logo.png` and its import metadata after the live title screen moved to `res://blight_&_bloom_logo.png`.

## Future decoupling work before larger deletion

1. Extract shared input-label helpers from `DemoDirector` into a loop-safe UI/input helper.
2. Replace the old `warning_ui` calendar handoff with the current direct loop battle launch path everywhere.
3. Remove `forest_battle.tscn` inheritance from `day_two_battle.tscn`.
4. Detach `game.tscn` from `world.tscn` / story dialogue composition where no longer needed.
5. Retire `saved_farm_scene` return flow once all combat entry paths use the same loop-safe transition.
