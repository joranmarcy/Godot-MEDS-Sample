# Requires GDVM to be installed with one or more Godot versions under ~/.gdvm/installs.
param(
	[string[]]$Versions,
	[switch]$StopOnFirstFailure
)

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

$scriptRoot = $PSScriptRoot
$suiteRunnerPath = Join-Path $scriptRoot "run_all_tests.ps1"
$gdvmInstallsPath = Join-Path $env:USERPROFILE ".gdvm\installs"
$pwshPath = [System.Diagnostics.Process]::GetCurrentProcess().Path

if (-not (Test-Path $suiteRunnerPath)) {
	throw "Could not find run_all_tests.ps1 next to this script."
}

if (-not (Test-Path $gdvmInstallsPath)) {
	throw "Could not find GDVM installs directory at $gdvmInstallsPath."
}

$installedVersions = Get-ChildItem $gdvmInstallsPath -Directory | Sort-Object Name

if ($Versions -and $Versions.Count -gt 0) {
	$requested = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
	foreach ($version in $Versions) {
		[void]$requested.Add($version)
	}
	$installedVersions = @($installedVersions | Where-Object { $requested.Contains($_.Name) })

	$installedVersionNames = @($installedVersions | ForEach-Object { $_.Name })
	$missingVersions = @($Versions | Where-Object {
		$requestedVersion = $_
		-not ($installedVersionNames | Where-Object { $_ -ieq $requestedVersion })
	})
	if ($missingVersions.Count -gt 0) {
		throw "Requested GDVM version(s) not found: $($missingVersions -join ', ')"
	}
}

if ($installedVersions.Count -eq 0) {
	throw "No GDVM-installed Godot versions were found."
}

$failedVersions = @()

foreach ($version in $installedVersions) {
	$godotPath = Get-ChildItem $version.FullName -Filter "*_console.exe" | Select-Object -First 1 -ExpandProperty FullName
	if (-not $godotPath) {
		$godotPath = Get-ChildItem $version.FullName -Filter "*.exe" | Select-Object -First 1 -ExpandProperty FullName
	}

	if (-not $godotPath) {
		Write-Error "Skipping $($version.Name): no Godot executable found."
		$failedVersions += [pscustomobject]@{
			Version = $version.Name
			Reason = "No Godot executable found"
		}
		if ($StopOnFirstFailure) {
			exit 1
		}
		continue
	}

	Write-Host "=== GDVM version $($version.Name) ==="
	& $pwshPath -NoProfile -File $suiteRunnerPath -GodotPath $godotPath
	if ($LASTEXITCODE -eq 0) {
		Write-Host "RESULT $($version.Name): PASS"
		continue
	}

	Write-Host "RESULT $($version.Name): FAIL"
	$failedVersions += [pscustomobject]@{
		Version = $version.Name
		Reason = "Regression suite failed"
	}
	if ($StopOnFirstFailure) {
		exit 1
	}
}

if ($failedVersions.Count -gt 0) {
	Write-Error "GDVM multi-version regression sweep failed."
	$failedVersions | ForEach-Object {
		Write-Host ("FAILED VERSION {0}: {1}" -f $_.Version, $_.Reason)
	}
	exit 1
}

Write-Host "All GDVM-managed Godot versions passed the MEDS regression suite."