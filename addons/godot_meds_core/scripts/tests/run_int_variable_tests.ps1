$projectPath = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
$runnerPath = "res://addons/godot_meds_core/scripts/tests/int_variable_test_runner.gd"

$godotCommand = Get-Command godot -ErrorAction SilentlyContinue
$godotPath = $null

if ($godotCommand) {
	$godotPath = $godotCommand.Source
	$candidateConsolePath = Join-Path (Split-Path $godotPath) "godot_console.exe"
	if (Test-Path $candidateConsolePath) {
		$godotPath = $candidateConsolePath
	}
}

if (-not $godotPath) {
	$consoleCommand = Get-Command godot_console -ErrorAction SilentlyContinue
	if ($consoleCommand) {
		$godotPath = $consoleCommand.Source
	}
}

if (-not $godotPath) {
	throw "Could not find Godot on PATH. Install Godot or add godot_console.exe to PATH."
}

Write-Host "Running IntVariable tests with $godotPath"
& $godotPath --headless --path $projectPath -s $runnerPath
exit $LASTEXITCODE