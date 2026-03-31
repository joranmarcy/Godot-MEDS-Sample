# Release Notes: 0.1.0-alpha.3

Released: 2026-03-31  
Commit range: `releases/0.1.0-alpha.2` -> `09e09a20e05d5af38531723eb00329cd1d1e5990`  
Diff summary: 69 files changed, 8,050 insertions, 369 deletions.

## Highlights

- Added a shared `NumericVariable` foundation for numeric MEDS resources, with reusable clamping and range synchronization for both float and int variables.
- Added reusable variable-driven UI controls for labels, sliders, and progress bars.
- Added headless runtime test runners for `FloatVariable` and `IntVariable`, plus Windows-friendly PowerShell wrappers.
- Expanded the sample project with a more complete gameplay loop, including damage flow, audio, heartbeat behavior, game-over scene handling, and new art/audio assets.
- Added an MIT license and expanded the README with testing instructions and UI script references.

## Added

- `addons/godot_meds_core/scripts/variables/numeric-variable.gd` as the shared base for numeric resource behavior.
- `addons/godot_meds_core/scripts/ui/variable-driven-label.gd` for generic variable-to-label binding, including prefix and suffix support.
- `addons/godot_meds_core/scripts/ui/variable-driven-slider.gd` for two-way `NumericVariable` slider binding with clamp-aware range updates.
- `addons/godot_meds_core/scripts/ui/variable-driven-progress-bar.gd` for `NumericVariable` progress display with clamp-aware bounds and integer step handling.
- Float and int variable test runners under `addons/godot_meds_core/scripts/tests/`, plus PowerShell wrappers for Windows console execution.
- New sample content including `samples/game-over.tscn`, `samples/prefabs/player.tscn`, new gameplay scripts, new resources, audio files, and the imported Godot plush model.

## Changed

- `BaseVariable` now supports standardized reset behavior through `reset_on`, with `On Scene Load` and `On Application Start` options.
- Runtime value caching was added for application-start resets so external variable resources can persist within a running session without forcing device persistence.
- `FloatVariable` and `IntVariable` now share numeric behavior through `NumericVariable`, including clamping, range metadata, and range-change notifications.
- The sample project was reworked to use a more polished demo flow, with updated scene wiring, renamed resources, new prefabs, and audio-driven feedback.
- Export and project metadata were refreshed, including Windows export configuration and project naming/icon updates.
- The README now documents headless test execution on Windows and points users toward the reusable variable-driven UI scripts.

## Deprecated And Migration Notes

- `float-driven-label.gd`, `string-driven-label.gd`, and `float-driven-slider.gd` were deprecated and moved under `addons/godot_meds_core/scripts/ui/deprecated/`.
- Preferred replacements are `variable-driven-label.gd`, `variable-driven-slider.gd`, and `variable-driven-progress-bar.gd`.
- Existing sample/menu references were updated to the new variable-driven UI scripts.
- Reset option naming was standardized. If you were relying on earlier naming, re-check exported resource settings in the Inspector.

## Sample Project Updates

- Renamed and expanded several sample resources to better match the robot-centered demo (`robot-health`, `robot-name`, `robot-position`, `robot-rotation`, `robot-visibility`, `damage-amount`, `damage-color`).
- Replaced the old particle trigger event resource with `samples/events/take-damage.tres`.
- Added `audio_manager`, `player`, `game-over-manager`, `heartbeat-controller`, `robot`, and `scene-manager` sample scripts/scenes.
- Added new materials, imported model assets, and sound effects to support the revised sample presentation.

## Testing And Documentation

- Added headless test coverage for `FloatVariable` and `IntVariable` without introducing an external test framework dependency.
- Added PowerShell wrappers so Windows users can run tests with `godot_console` and still see terminal output.
- Updated README language around the live variable debugger and documented the new UI binding scripts.

## Commit Log

- `da2a4ac` feat: add LICENSE file and update README with license section
- `e165786` fix: update wording in README for clarity on live variables debugger
- `26f234b` misc: update project name and icon
- `0c42e6e` misc: update godot path
- `ff1956c` feat: clamped float variables wip
- `2e4fcab` feat(sample): better sample scene wip
- `c2afd7c` Merge branch 'features/clamped-float' into releases/0.1.0-alpha.3
- `3f6929c` Merge branch 'features/better-sample-scene' into releases/0.1.0-alpha.3
- `28535e1` feat: enhance float variable and slider integration with range change signals
- `b842b7e` feat(sample): better sample scene wip
- `b538c9c` Merge branch 'releases/0.1.0-alpha.3' into features/better-sample-scene
- `f764d20` feat(sample): better sample scene wip
- `12edebb` feat: clampable int variables
- `4f21148` feat: int-driven-progress-bar script
- `5f11051` feat(sample): better sample scene wip
- `07cc274` feat(sample): better sample scene wip
- `ebea4db` feat(sample): better sample scene wip
- `66d3f43` feat(sample): better sample scene wip
- `35a4555` feat(variable): add runtime value caching and reset options
- `e2c7aeb` feat(variable): standardize reset options naming for consistency
- `ed23c34` misc: windows export
- `e280ba1` feat(sample): better sample scene wip
- `838a375` Merge branch 'features/better-sample-scene' into releases/0.1.0-alpha.3
- `535f32e` Merge branch 'features/reset-on-application-start' into releases/0.1.0-alpha.3
- `ca1f5cb` feat: damage color instead of robot color
- `fa4682a` feat: create int variable for damage amount
- `8b743c0` feat: suffix and prefix for string driven labels
- `6eb6d30` feat: add variable-driven label script and update menu scene references
- `1a3bcf4` feat: deprecate float-driven-label.gd and string-driven-label.gd, redirecting to variable-driven-label.gd
- `35c2465` feat: add unit tests for FloatVariable and update README with test instructions
- `5ec6b18` feat: add unit tests for IntVariable and update README with test instructions
- `197c5cd` feat: remove unused use_bool_variable.gd test script
- `52c358a` misc: generated changes
- `3f8c4ac` Merge branch 'features/unit-tests' into releases/0.1.0-alpha.3
- `c3c169c` feat: numeric values base class
- `caa2512` feat: refactor numeric variable classes
- `c1d56f1` feat: migrate float-driven-slider to numeric-driven-slider and deprecate old implementation
- `26056d3` Merge branch 'features/numeric-values' into releases/0.1.0-alpha.3
- `f10b197` misc: move to deprecated scripts to dedicated folder
- `3e705d2` misc: generated changes
- `1566f45` feat: replace float-driven-slider with variable-driven-slider and update deprecation message
- `09e09a2` feat: replace int-driven-progress-bar with variable-driven-progress-bar and update menu references