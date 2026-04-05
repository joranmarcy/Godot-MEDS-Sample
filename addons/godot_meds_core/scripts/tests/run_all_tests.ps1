param(
	[string]$GodotPath
)

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

$projectPath = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
$testRunners = @(
	"res://addons/godot_meds_core/scripts/tests/float_variable_test_runner.gd",
	"res://addons/godot_meds_core/scripts/tests/int_variable_test_runner.gd",
	"res://addons/godot_meds_core/scripts/tests/base_value_types_and_event_test_runner.gd",
	"res://addons/godot_meds_core/scripts/tests/ui_bindings_test_runner.gd",
	"res://addons/godot_meds_core/scripts/tests/runtime_cache_test_runner.gd"
)


if (-not $GodotPath) {
	$godotCommand = Get-Command godot -ErrorAction SilentlyContinue
	if ($godotCommand) {
		$GodotPath = $godotCommand.Source
		$candidateConsolePath = Join-Path (Split-Path $GodotPath) "godot_console.exe"
		if (Test-Path $candidateConsolePath) {
			$GodotPath = $candidateConsolePath
		}
	}
}


if (-not $GodotPath) {
	$consoleCommand = Get-Command godot_console -ErrorAction SilentlyContinue
	if ($consoleCommand) {
		$GodotPath = $consoleCommand.Source
	}
}

if (-not $GodotPath) {
	throw "Could not find Godot on PATH. Install Godot or add godot_console.exe to PATH."
}

$GodotPath = (Resolve-Path $GodotPath).Path

$failedRunners = @()

foreach ($runnerPath in $testRunners) {
	Write-Host "Running tests with $GodotPath"
	Write-Host "Runner: $runnerPath"
	$outputLines = & $GodotPath --headless --path $projectPath -s $runnerPath 2>&1
	$normalizedOutputLines = @($outputLines | ForEach-Object {
		if ($_ -is [System.Management.Automation.ErrorRecord]) {
			$_.ToString() -replace "[\u2066-\u2069]", ""
		} else {
			("$_") -replace "[\u2066-\u2069]", ""
		}
	})
	$normalizedOutputLines | ForEach-Object { Write-Host $_ }
	$outputText = ($normalizedOutputLines | Out-String)
	if (
		$LASTEXITCODE -ne 0 -or
		$outputText -match "tests failed" -or
		$outputText -match "failed \(" -or
		$outputText -match "SCRIPT ERROR:" -or
		$outputText -match "Parse Error:" -or
		$outputText -match "ERROR: Failed to load script"
	) {
		$failedRunners += $runnerPath
	}
}

if ($failedRunners.Count -gt 0) {
	Write-Error ("The MEDS regression suite failed:`n" + ($failedRunners -join "`n"))
	exit 1
}

Write-Host "All MEDS regression tests passed."