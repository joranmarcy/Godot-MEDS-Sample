<#
.SYNOPSIS
Updates addon versions and packages GitHub-ready ZIP archives.

.DESCRIPTION
Updates the version field in both addon plugin.cfg files, then creates one ZIP per addon.
Each archive preserves the `addons/<addon_name>/...` folder structure so it can be extracted
directly into the root of another Godot project.

.EXAMPLE
pwsh -File .\tools\release-addons.ps1 -Version 0.1.0-alpha.4

.EXAMPLE
pwsh -File .\tools\release-addons.ps1 -Version 0.1.0-alpha.4 -OutputDir .\Builds
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Version,

	[string]$OutputDir = "Builds"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-WorkspacePath {
	param([Parameter(Mandatory)][string]$Path)

	if ([System.IO.Path]::IsPathRooted($Path)) {
		return $Path
	}

	return (Join-Path -Path (Get-Location) -ChildPath $Path)
}

function Set-AddonVersion {
	param(
		[Parameter(Mandatory)][string]$PluginConfigPath,
		[Parameter(Mandatory)][string]$Version
	)

	$content = Get-Content -LiteralPath $PluginConfigPath -Raw
	if ($content -notmatch '(?m)^version="[^"]*"\r?$') {
		throw "Could not find a version line in: $PluginConfigPath"
	}

	$updatedContent = $content -replace '(?m)^version="[^"]*"\r?$', ("version=`"{0}`"" -f $Version)

	Set-Content -LiteralPath $PluginConfigPath -Value $updatedContent -Encoding UTF8
}

function New-AddonArchive {
	param(
		[Parameter(Mandatory)][string]$WorkspaceRoot,
		[Parameter(Mandatory)][string]$AddonName,
		[Parameter(Mandatory)][string]$Version,
		[Parameter(Mandatory)][string]$OutputDirectory
	)

	$addonSource = Join-Path -Path $WorkspaceRoot -ChildPath (Join-Path -Path 'addons' -ChildPath $AddonName)
	if (-not (Test-Path -LiteralPath $addonSource)) {
		throw "Addon directory not found: $addonSource"
	}

	$archivePath = Join-Path -Path $OutputDirectory -ChildPath ("{0}-{1}.zip" -f $AddonName, $Version)
	if (Test-Path -LiteralPath $archivePath) {
		Remove-Item -LiteralPath $archivePath -Force
	}

	$tempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
	$stagingAddonsDir = Join-Path -Path $tempRoot -ChildPath 'addons'
	$stagingAddonDir = Join-Path -Path $stagingAddonsDir -ChildPath $AddonName

	New-Item -ItemType Directory -Path $stagingAddonDir -Force | Out-Null
	Copy-Item -Path (Join-Path -Path $addonSource -ChildPath '*') -Destination $stagingAddonDir -Recurse -Force

	try {
		Compress-Archive -Path $stagingAddonsDir -DestinationPath $archivePath -CompressionLevel Optimal
	}
	finally {
		if (Test-Path -LiteralPath $tempRoot) {
			Remove-Item -LiteralPath $tempRoot -Recurse -Force
		}
	}

	return $archivePath
}

$workspaceRoot = Get-Location
$outputFullPath = Resolve-WorkspacePath $OutputDir

if (-not (Test-Path -LiteralPath $outputFullPath)) {
	New-Item -ItemType Directory -Path $outputFullPath -Force | Out-Null
}

$addons = @(
	@{
		Name = 'godot_meds_core'
		PluginConfig = Join-Path -Path $workspaceRoot -ChildPath 'addons/godot_meds_core/plugin.cfg'
	},
	@{
		Name = 'godot_meds_editor'
		PluginConfig = Join-Path -Path $workspaceRoot -ChildPath 'addons/godot_meds_editor/plugin.cfg'
	}
)

foreach ($addon in $addons) {
	Set-AddonVersion -PluginConfigPath $addon.PluginConfig -Version $Version
}

$archives = foreach ($addon in $addons) {
	New-AddonArchive -WorkspaceRoot $workspaceRoot -AddonName $addon.Name -Version $Version -OutputDirectory $outputFullPath
}

Write-Host "Updated addon version to $Version"
Write-Host "Created archives:"
foreach ($archive in $archives) {
	Write-Host " - $archive"
}