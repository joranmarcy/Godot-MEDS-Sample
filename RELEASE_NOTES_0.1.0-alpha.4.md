# Release Notes: 0.1.0-alpha.4

Released: 2026-04-04  
Commit range: `releases/0.1.0-alpha.3` -> `3443e4599434e628f1a5982a47f5eedd2bbb75f7`  
Diff summary: 11 files changed, 247 insertions, 44 deletions.

## Highlights

- Moved the MEDS runtime inspectors into Godot's bottom panel for a more natural debugging workflow during play mode.
- Improved the live event debugger UI, including a full-width raise action that is easier to hit while testing listeners.
- Fixed the sample particle trigger so repeated event-driven activations reliably restart the effect.
- Added a PowerShell release helper that updates addon versions and creates ZIP archives ready for distribution.
- Expanded the README with clearer feature coverage, refreshed media, and asset credits.

## Added

- `tools/release-addons.ps1` to update both addon `plugin.cfg` versions and package `godot_meds_core` / `godot_meds_editor` as release ZIP archives.
- New README coverage for custom resource icons, the live variable debugger, the live event debugger, runtime reaction tracking, and asset credits.

## Changed

- `Godot MEDS Editor Tools` now registers the Variable Values and Events inspectors in the bottom panel instead of regular editor docks.
- The runtime Events panel was refined so the raise action occupies the full column width, making manual event testing more straightforward.
- README messaging was tightened around the external documentation link, feature descriptions, and sample-project capabilities.
- Debugger GIF assets were refreshed and renamed so updated previews are picked up reliably.

## Fixed

- `samples/scripts/trigger-particles.gd` now resets emission before re-enabling it, so repeated triggers restart the particle effect consistently.

## Documentation And Packaging

- The README now does a better job of surfacing what ships with MEDS: editor icons, runtime debugging tools, reference tracking, reusable UI bindings, and sample-project structure.
- Asset attribution for the Godot plush sample model was added to the repository documentation.
- Release packaging is now scripted, reducing the manual work required to bump addon versions and create distributable archives.

## Commit Log

- `3443e45` release: 0.1.0-alpha.4
- `e86e9fc` feat: add release-addons script for updating addon versions and creating ZIP archives
- `188b07d` docs: enhance README with detailed descriptions for custom resource icons and debugging features
- `194f730` docs: add asset credits section to README
- `ee3ef0f` fix: update gif names to force refresh
- `80c2735` Merge branch 'releases/0.1.0-alpha.4' into develop
- `b1b0683` docs: remove redundant documentation link from README
- `0455051` docs: enhance documentation section with important notice
- `acbc1f2` misc: update gifs
- `c5eb75a` misc: update readme.md
- `e88cc9e` feat: make event raise button take full column width
- `37dc0ff` feat: move meds inspectors to bottom panel
- `5823e92` fix: reset particle system when triggered