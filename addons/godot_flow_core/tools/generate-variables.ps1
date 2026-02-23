<#
.SYNOPSIS
Generates typed Godot Resource "Variable" scripts from a GDScript template.

.DESCRIPTION
Reads scripts/resources/variable.gd.template and replaces these placeholders:
  __ClassName__     -> e.g. StringVariable
  __Type__          -> e.g. String, float, Color
  __DefaultValue__  -> e.g. "", 0.0, Color.WHITE

Outputs one .gd file per type into scripts/resources/ by default.

.EXAMPLE
pwsh -File .\tools\generate-variables.ps1

.EXAMPLE
pwsh -File .\tools\generate-variables.ps1 -Types String,Float,Color -Force
#>

[CmdletBinding()]
param(
	[string]$TemplatePath = "scripts/variables/variable.gd.template",
	[string]$OutputDir = "scripts/variables",
	[string[]]$Types = @("Bool", "String", "Float", "Int", "Color", "Vector2", "Vector3"),
	[switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-WorkspacePath {
	param([Parameter(Mandatory)][string]$Path)
	if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
	return (Join-Path -Path (Get-Location) -ChildPath $Path)
}

$templateFullPath = Resolve-WorkspacePath $TemplatePath
$outputFullPath = Resolve-WorkspacePath $OutputDir

if (-not (Test-Path -LiteralPath $templateFullPath)) {
	throw "Template not found: $TemplatePath (resolved to: $templateFullPath)"
}

if (-not (Test-Path -LiteralPath $outputFullPath)) {
	New-Item -ItemType Directory -Path $outputFullPath | Out-Null
}

$template = Get-Content -LiteralPath $templateFullPath -Raw
$requiredTokens = @("__ClassName__", "__Type__", "__DefaultValue__")
foreach ($token in $requiredTokens) {
	if ($template -notlike "*$token*") {
		throw "Template is missing required placeholder token: $token"
	}
}

# Built-in specs. Add more here as needed.
$specs = @{
	"String"  = @{ ClassName = "StringVariable";  GdType = "String";   DefaultValue = '""';            FileName = "string-variable.gd" }
	"Float"   = @{ ClassName = "FloatVariable";   GdType = "float";    DefaultValue = '0.0';           FileName = "float-variable.gd" }
	"Int"     = @{ ClassName = "IntVariable";     GdType = "int";      DefaultValue = '0';             FileName = "int-variable.gd" }
	"Color"   = @{ ClassName = "ColorVariable";   GdType = "Color";    DefaultValue = 'Color.WHITE';   FileName = "color-variable.gd" }
	"Vector2" = @{ ClassName = "Vector2Variable"; GdType = "Vector2";  DefaultValue = 'Vector2.ZERO';  FileName = "vector2-variable.gd" }
	"Vector3" = @{ ClassName = "Vector3Variable"; GdType = "Vector3";  DefaultValue = 'Vector3.ZERO';  FileName = "vector3-variable.gd" }
	"NodePath"= @{ ClassName = "NodePathVariable";GdType = "NodePath"; DefaultValue = 'NodePath(\"\")'; FileName = "nodepath-variable.gd" }
	"Bool"    = @{ ClassName = "BoolVariable";    GdType = "bool";     DefaultValue = 'false';         FileName = "bool-variable.gd" }
}

$generated = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]

foreach ($typeKey in $Types) {
	if (-not $specs.ContainsKey($typeKey)) {
		$known = ($specs.Keys | Sort-Object) -join ", "
		throw "Unknown type '$typeKey'. Known types: $known"
	}

	$spec = $specs[$typeKey]
	$outFile = Join-Path -Path $outputFullPath -ChildPath $spec.FileName

	if ((Test-Path -LiteralPath $outFile) -and (-not $Force)) {
		$skipped.Add($spec.FileName) | Out-Null
		continue
	}

	$content = $template
	$content = $content.Replace("__ClassName__", [string]$spec.ClassName)
	$content = $content.Replace("__Type__", [string]$spec.GdType)
	$content = $content.Replace("__DefaultValue__", [string]$spec.DefaultValue)

	Set-Content -LiteralPath $outFile -Value $content -Encoding UTF8
	$generated.Add($spec.FileName) | Out-Null
}

Write-Host "Template:" $templateFullPath
Write-Host "Output:  " $outputFullPath
if ($generated.Count -gt 0) {
	Write-Host "Generated:" ($generated -join ", ")
}
if ($skipped.Count -gt 0) {
	Write-Host "Skipped (exists; use -Force):" ($skipped -join ", ")
}
