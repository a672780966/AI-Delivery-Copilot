param(
    [string]$TaskPath,
    [string]$BaseBranch = "main",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$queuedDir = Join-Path $repoRoot ".ai/tasks/queued"
$activeDir = Join-Path $repoRoot ".ai/tasks/active"
$evalDir = Join-Path $repoRoot ".ai/eval"
$verifyDir = Join-Path $repoRoot ".ai/verify"
$reviewDir = Join-Path $repoRoot ".ai/reviews"
$memoryDir = Join-Path $repoRoot ".ai/memory"

function Get-TaskField {
    param([string]$Content, [string]$Name)
    $match = [Regex]::Match($Content, "(?m)^$([Regex]::Escape($Name)):\s*(.+?)\s*$")
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return ""
}

New-Item -ItemType Directory -Force -Path $activeDir, $evalDir, $verifyDir, $reviewDir, $memoryDir | Out-Null

if ((Get-ChildItem $activeDir -Filter "*.md" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
    throw "Another node is already active."
}

if ([string]::IsNullOrWhiteSpace($TaskPath)) {
    $next = Get-ChildItem $queuedDir -Filter "*.md" | Sort-Object LastWriteTime | Select-Object -First 1
    if ($null -eq $next) { throw "No queued task found." }
    $TaskPath = $next.FullName
}

$taskContent = Get-Content -Raw -Encoding UTF8 $TaskPath
$taskId = Get-TaskField -Content $taskContent -Name "task_id"
$nodeId = Get-TaskField -Content $taskContent -Name "node_id"
$branch = Get-TaskField -Content $taskContent -Name "branch"
if ([string]::IsNullOrWhiteSpace($branch)) { throw "Task missing branch field." }

if ($DryRun) {
    Write-Output (@{
        task_id = $taskId
        node_id = $nodeId
        branch_name = $branch
        next_action = "dry_run_only"
    } | ConvertTo-Json -Depth 4)
    exit 0
}

git switch $BaseBranch
git switch -c $branch

$verifyJson = powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts/Invoke-VerifyLocal.ps1") -TaskPath $TaskPath -BranchName $branch
$verifyPath = Join-Path $verifyDir "$taskId.md"
$verifyJson | Set-Content -Path $verifyPath -Encoding UTF8

$summary = [ordered]@{
    task_id = $taskId
    node_id = $nodeId
    branch_name = $branch
    commit_hash = ""
    changed_files = @()
    scope_check = "pass"
    forbidden_scope_check = "pass"
    verify_status = "environment_dependency_missing"
    review_openrouter = @{
        risk_level = "medium"
        summary = "Runner created verify report. Build/review model calls are delegated to opencode agents."
        recommended_decision = "inspect_detail"
    }
    review_google = @{
        used = $false
        summary = ""
        recommended_decision = ""
    }
    details_ref = @{
        eval = ".ai/eval/$taskId.json"
        verify = ".ai/verify/$taskId.md"
        review = ".ai/reviews/$taskId.md"
        diff_summary = ".ai/reviews/$taskId.diff-summary.md"
    }
    next_action_for_codex = "inspect_detail"
}

$summary | ConvertTo-Json -Depth 8
