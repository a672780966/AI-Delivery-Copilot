param(
    [Parameter(Mandatory = $true)]
    [string]$TaskPath,

    [string]$BranchName = "",

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-TaskField {
    param([string]$Content, [string]$Name)
    $match = [Regex]::Match($Content, "(?m)^$([Regex]::Escape($Name)):\s*(.+?)\s*$")
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return ""
}

function Get-SectionItems {
    param([string]$Content, [string]$Heading)
    $pattern = "(?ms)^##\s+$([Regex]::Escape($Heading))\s*$\n(?<body>.*?)(?=^##\s+|\z)"
    $match = [Regex]::Match($Content, $pattern)
    if (-not $match.Success) { return @() }
    return @($match.Groups["body"].Value -split "`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_.StartsWith("- ") } |
        ForEach-Object {
            $item = $_.Substring(2).Trim()
            $item = $item.Trim([char]0x60)
            $item.Trim()
        })
}

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-GitList {
    param([string[]]$GitArgs)
    $output = & git @GitArgs 2>$null
    if ($LASTEXITCODE -ne 0) { return @() }
    return @($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

$resolvedTask = Resolve-Path $TaskPath
$taskContent = Get-Content -Raw -Encoding UTF8 $resolvedTask
$taskId = Get-TaskField -Content $taskContent -Name "task_id"
$nodeId = Get-TaskField -Content $taskContent -Name "node_id"
if ([string]::IsNullOrWhiteSpace($BranchName)) {
    $BranchName = Get-TaskField -Content $taskContent -Name "branch"
}

$allowedScope = Get-SectionItems -Content $taskContent -Heading "Allowed Scope"
$forbiddenScope = Get-SectionItems -Content $taskContent -Heading "Forbidden Scope"
$trackedChanged = Invoke-GitList -GitArgs @("diff", "--name-only")
$untracked = Invoke-GitList -GitArgs @("ls-files", "--others", "--exclude-standard")
$changedFiles = @($trackedChanged + $untracked | Sort-Object -Unique)

$scopeViolations = @()
foreach ($file in $changedFiles) {
    $normalized = $file -replace "\\", "/"
    $allowed = $false
    foreach ($scope in $allowedScope) {
        $scopeNorm = $scope -replace "\\", "/"
        if ($normalized -eq $scopeNorm -or $normalized.StartsWith($scopeNorm.TrimEnd("/") + "/")) {
            $allowed = $true
            break
        }
    }
    if (-not $allowed) { $scopeViolations += $file }
}

$forbiddenHits = @()
foreach ($file in $changedFiles) {
    $normalized = $file -replace "\\", "/"
    foreach ($scope in $forbiddenScope) {
        $scopeNorm = $scope -replace "\\", "/"
        if ($normalized -eq $scopeNorm -or $normalized.StartsWith($scopeNorm.TrimEnd("/") + "/")) {
            $forbiddenHits += $file
            break
        }
    }
}

$commandsRun = @("git status --short", "git diff --name-only", "git diff --stat")
$passed = @()
$failed = @()
$reasons = @()

& git status --short | Out-Null
if ($LASTEXITCODE -eq 0) { $passed += "git status --short" } else { $failed += "git status --short" }
& git diff --name-only | Out-Null
if ($LASTEXITCODE -eq 0) { $passed += "git diff --name-only" } else { $failed += "git diff --name-only" }
& git diff --stat | Out-Null
if ($LASTEXITCODE -eq 0) { $passed += "git diff --stat" } else { $failed += "git diff --stat" }

$needsDocker = $taskContent -match "docker compose"
$needsPython = $taskContent -match "python -m json.tool|pytest"

if ($needsDocker -and -not (Test-CommandExists "docker")) {
    $failed += "docker compose"
    $reasons += "docker unavailable"
}
if ($needsPython -and -not (Test-CommandExists "python")) {
    $failed += "python"
    $reasons += "python unavailable"
}

$scopeCheck = if ($scopeViolations.Count -eq 0) { "pass" } else { "fail" }
$forbiddenCheck = if ($forbiddenHits.Count -eq 0) { "pass" } else { "fail" }
$verifyStatus = "pass"
if ($scopeCheck -eq "fail" -or $forbiddenCheck -eq "fail") {
    $verifyStatus = "fail"
    if ($scopeViolations.Count -gt 0) { $reasons += "scope violation: $($scopeViolations -join ', ')" }
    if ($forbiddenHits.Count -gt 0) { $reasons += "forbidden scope changed: $($forbiddenHits -join ', ')" }
} elseif (($needsDocker -and -not (Test-CommandExists "docker")) -or ($needsPython -and -not (Test-CommandExists "python"))) {
    $verifyStatus = "environment_dependency_missing"
} elseif ($failed.Count -gt 0) {
    $verifyStatus = "fail"
}

$result = [ordered]@{
    task_id = $taskId
    node_id = $nodeId
    branch_name = $BranchName
    changed_files = $changedFiles
    scope_check = $scopeCheck
    forbidden_scope_check = $forbiddenCheck
    commands_run = $commandsRun
    passed_commands = $passed
    failed_commands = $failed
    verify_status = $verifyStatus
    reason = if ($reasons.Count -gt 0) { $reasons -join "; " } else { "ok" }
    logs_ref = ".ai/verify/$taskId.md"
}

$result | ConvertTo-Json -Depth 6
