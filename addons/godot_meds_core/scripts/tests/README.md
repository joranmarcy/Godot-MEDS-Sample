# MEDS Test Suite

This folder contains the headless unit and regression test suite for MEDS core runtime behavior.

## Coverage

- `FloatVariable`
- `IntVariable`
- Base typed variables (`BoolVariable`, `StringVariable`, `ColorVariable`, `Vector2Variable`, `Vector3Variable`)
- `Event` signal dispatch
- Runtime cache behavior for `reset_on`
- UI bindings (`VariableDrivenLabel`, `VariableDrivenSlider`)

## Files

- `test_harness.gd`: shared assertions and pass/fail reporting
- `float_variable_test_runner.gd`: `FloatVariable` regression runner
- `int_variable_test_runner.gd`: `IntVariable` regression runner
- `base_value_types_and_event_test_runner.gd`: base typed variable and event coverage
- `ui_bindings_test_runner.gd`: label and slider binding coverage
- `runtime_cache_test_runner.gd`: runtime cache and `reset_on` coverage
- `run_all_tests.ps1`: run the full suite with the Godot executable on `PATH`
- `run_all_tests_gdvm.ps1`: run the full suite across all GDVM-installed Godot versions

## Running Tests

On Windows, use the provided PowerShell wrappers:

```powershell
.\addons\godot_meds_core\scripts\tests\run_all_tests.ps1
.\addons\godot_meds_core\scripts\tests\run_all_tests_gdvm.ps1
```

If you want to invoke Godot directly, use:

```powershell
godot_console --headless --path . -s res://addons/godot_meds_core/scripts/tests/float_variable_test_runner.gd
godot_console --headless --path . -s res://addons/godot_meds_core/scripts/tests/int_variable_test_runner.gd
godot_console --headless --path . -s res://addons/godot_meds_core/scripts/tests/base_value_types_and_event_test_runner.gd
godot_console --headless --path . -s res://addons/godot_meds_core/scripts/tests/ui_bindings_test_runner.gd
godot_console --headless --path . -s res://addons/godot_meds_core/scripts/tests/runtime_cache_test_runner.gd
```

## Upgrade Checks

To validate a single installed Godot version, use:

```powershell
.\addons\godot_meds_core\scripts\tests\run_all_tests.ps1
```

If you use GDVM and want to sweep every installed version automatically, use:

```powershell
.\addons\godot_meds_core\scripts\tests\run_all_tests_gdvm.ps1
```

You can also limit the sweep to specific installs:

```powershell
.\addons\godot_meds_core\scripts\tests\run_all_tests_gdvm.ps1 -Versions 4.5.2-stable,4.6.2-stable
```