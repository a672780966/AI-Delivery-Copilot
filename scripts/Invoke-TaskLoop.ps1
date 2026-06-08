param(
    [string]$TaskPath,
    [string]$BaseBranch = "main",
    [switch]$DryRun,
    [switch]$SkipBuild,
    [switch]$SkipCommit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$queuedDir = Join-Path $repoRoot ".ai/tasks/queued"
$activeDir = Join-Path $repoRoot ".ai/tasks/active"
$doneDir = Join-Path $repoRoot ".ai/tasks/done"
$reviewPendingDir = Join-Path $repoRoot ".ai/tasks/review_pending"
$repairDir = Join-Path $repoRoot ".ai/tasks/repair_requested"
$stateDir = Join-Path $repoRoot ".ai/state"
$statePath = Join-Path $stateDir "current-run.json"

function Get-TaskField {
    param([string]$Content, [string]$Name)
    $match = [Regex]::Match($Content, "(?m)^$([Regex]::Escape($Name)):\s*(.+?)\s*$")
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return ""
}

function Write-RunState {
    param(
        [string]$TaskId,
        [string]$NodeId,
        [string]$BranchName,
        [string]$Phase,
        [string]$LatestCommit,
        [string[]]$BlockingIssues,
        [string]$NextAction
    )

    $state = [ordered]@{
        task_id = $TaskId
        node_id = $NodeId
        branch_name = $BranchName
        current_phase = $Phase
        latest_commit = $LatestCommit
        blocking_issues = $BlockingIssues
        next_action = $NextAction
        updated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    }
    $state | ConvertTo-Json -Depth 6 | Set-Content -Path $statePath -Encoding UTF8
}

function Invoke-GitText {
    param([string[]]$GitArgs)
    $output = & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed"
    }
    return @($output)
}

New-Item -ItemType Directory -Force -Path $queuedDir, $activeDir, $doneDir, $reviewPendingDir, $repairDir, $stateDir | Out-Null

$activeTasks = @(Get-ChildItem $activeDir -Filter "*.md" -ErrorAction SilentlyContinue)
if ($activeTasks.Count -gt 0) {
    throw "Cannot claim a queued task because an active node already exists: $($activeTasks[0].Name)"
}

if ([string]::IsNullOrWhiteSpace($TaskPath)) {
    $next = Get-ChildItem $queuedDir -Filter "*.md" | Sort-Object LastWriteTime | Select-Object -First 1
    if ($null -eq $next) { throw "No queued task found." }
    $TaskPath = $next.FullName
}

$resolvedTask = Resolve-Path $TaskPath
$taskContent = Get-Content -Raw -Encoding UTF8 $resolvedTask
$taskId = Get-TaskField -Content $taskContent -Name "task_id"
$nodeId = Get-TaskField -Content $taskContent -Name "node_id"
$branch = Get-TaskField -Content $taskContent -Name "branch"
if ([string]::IsNullOrWhiteSpace($taskId)) { throw "Task missing task_id field." }
if ([string]::IsNullOrWhiteSpace($nodeId)) { throw "Task missing node_id field." }
if ([string]::IsNullOrWhiteSpace($branch)) { throw "Task missing branch field." }

$activePath = Join-Path $activeDir (Split-Path -Leaf $resolvedTask)
$runnerArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $repoRoot "scripts/Invoke-AgentNode.ps1"),
    "-TaskPath", $activePath,
    "-BaseBranch", $BaseBranch,
    "-AllowActiveTask"
)
if ($SkipBuild) { $runnerArgs += "-SkipBuild" }
$runnerArgs += "-SkipCommit"

if ($DryRun) {
    Write-Output ([ordered]@{
        task_id = $taskId
        node_id = $nodeId
        branch_name = $branch
        claim_from = $resolvedTask.Path
        claim_to = $activePath
        runner = "scripts/Invoke-AgentNode.ps1"
        runner_args = $runnerArgs
        phases = @("queued", "claimed_active", "runner_dispatch", "codex_reviewing")
        next_action = "dry_run_only"
    } | ConvertTo-Json -Depth 8)
    exit 0
}

Move-Item -Path $resolvedTask -Destination $activePath
Write-RunState -TaskId $taskId -NodeId $nodeId -BranchName $branch -Phase "claimed_active" -LatestCommit "" -BlockingIssues @() -NextAction "run_invoke_agent_node"

$runnerOutput = & powershell @runnerArgs
$runnerExit = $LASTEXITCODE
if ($runnerExit -ne 0) {
    Write-RunState -TaskId $taskId -NodeId $nodeId -BranchName $branch -Phase "repair_requested" -LatestCommit "" -BlockingIssues @("Invoke-AgentNode failed") -NextAction "codex_request_repair"
    throw "Invoke-AgentNode failed for task $taskId"
}

$summary = $runnerOutput -join [Environment]::NewLine
$summaryObject = $summary | ConvertFrom-Json
$verifyStatus = [string]$summaryObject.verify_status
$scopeCheck = [string]$summaryObject.scope_check
$forbiddenScopeCheck = [string]$summaryObject.forbidden_scope_check
$blocking = @()
if ($scopeCheck -ne "pass") { $blocking += "scope_check=$scopeCheck" }
if ($forbiddenScopeCheck -ne "pass") { $blocking += "forbidden_scope_check=$forbiddenScopeCheck" }
if ($verifyStatus -eq "fail") { $blocking += "verify_status=fail" }

$phase = if ($blocking.Count -gt 0) { "repair_requested" } else { "codex_reviewing" }
$nextAction = if ($blocking.Count -gt 0) { "codex_request_repair" } else { "codex_final_review" }
Write-RunState -TaskId $taskId -NodeId $nodeId -BranchName $branch -Phase $phase -LatestCommit "" -BlockingIssues $blocking -NextAction $nextAction

if (-not $SkipCommit) {
    $changedFiles = @(Invoke-GitText -GitArgs @("diff", "--name-only"))
    Invoke-GitText -GitArgs @("add", "--") | Out-Null
    Invoke-GitText -GitArgs @(
        "commit",
        "-m", "task_id: $taskId",
        "-m", "node_id: $nodeId",
        "-m", "summary: run one queued task through auto task loop",
        "-m", "files_changed: $($changedFiles -join '; ')",
        "-m", "verify_status: $verifyStatus",
        "-m", "review_status: $phase",
        "-m", "repair_count: 0"
    ) | Out-Null
    $latestCommit = (Invoke-GitText -GitArgs @("rev-parse", "--short", "HEAD") | Select-Object -First 1)
} else {
    $latestCommit = ""
}

Write-Output ([ordered]@{
    task_id = $taskId
    node_id = $nodeId
    branch_name = $branch
    commit_hash = $latestCommit
    phase = $phase
    verify_status = $verifyStatus
    blocking_issues = $blocking
    next_action = $nextAction
} | ConvertTo-Json -Depth 6)
