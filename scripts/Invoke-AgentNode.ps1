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

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-GitText {
    param([string[]]$GitArgs)
    $output = & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed"
    }
    return @($output)
}

function Invoke-OpencodeAgent {
    param(
        [string]$Agent,
        [string]$Prompt,
        [string[]]$Files,
        [string]$OutputPath
    )

    if (-not (Test-CommandExists "npx.cmd")) {
        throw "npx.cmd unavailable; cannot invoke Opencode agent '$Agent'."
    }

    $args = @("-y", "opencode-ai", "run", "--agent", $Agent, "--dir", $repoRoot, "--format", "json")
    foreach ($file in $Files) {
        if (-not [string]::IsNullOrWhiteSpace($file)) {
            $args += @("--file", $file)
        }
    }
    $args += $Prompt

    $output = & npx.cmd @args
    $exitCode = $LASTEXITCODE
    $output | Set-Content -Path $OutputPath -Encoding UTF8
    if ($exitCode -ne 0) {
        throw "Opencode agent '$Agent' failed. See $OutputPath"
    }
}

function ConvertFrom-JsonObject {
    param([string]$Json)
    try {
        return $Json | ConvertFrom-Json
    } catch {
        return $null
    }
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

$resolvedTask = Resolve-Path $TaskPath
$taskContent = Get-Content -Raw -Encoding UTF8 $resolvedTask
$taskId = Get-TaskField -Content $taskContent -Name "task_id"
$nodeId = Get-TaskField -Content $taskContent -Name "node_id"
$branch = Get-TaskField -Content $taskContent -Name "branch"
if ([string]::IsNullOrWhiteSpace($taskId)) { throw "Task missing task_id field." }
if ([string]::IsNullOrWhiteSpace($nodeId)) { throw "Task missing node_id field." }
if ([string]::IsNullOrWhiteSpace($branch)) { throw "Task missing branch field." }

$evalPath = Join-Path $evalDir "$taskId.json"
$verifyPath = Join-Path $verifyDir "$taskId.md"
$reviewPath = Join-Path $reviewDir "$taskId.md"
$diffSummaryPath = Join-Path $reviewDir "$taskId.diff-summary.md"
$memoryPath = Join-Path $memoryDir "$taskId.json"
$activePath = Join-Path $activeDir (Split-Path -Leaf $resolvedTask)

$plannedStages = @("opencode.build-local", "verify-local", "opencode.review-openrouter", "opencode.review-google:conditional", "final-summary", "commit:conditional")

if ($DryRun) {
    Write-Output ([ordered]@{
        task_id = $taskId
        node_id = $nodeId
        branch_name = $branch
        stages = $plannedStages
        next_action = "dry_run_only"
    } | ConvertTo-Json -Depth 5)
    exit 0
}

Copy-Item -Path $resolvedTask -Destination $activePath -Force

$currentBranch = (Invoke-GitText -GitArgs @("branch", "--show-current") | Select-Object -First 1)
if ($currentBranch -ne $branch) {
    Invoke-GitText -GitArgs @("switch", $BaseBranch) | Out-Null
    $branchExists = (& git rev-parse --verify $branch 2>$null)
    if ($LASTEXITCODE -eq 0) {
        Invoke-GitText -GitArgs @("switch", $branch) | Out-Null
    } else {
        Invoke-GitText -GitArgs @("switch", "-c", $branch) | Out-Null
    }
}

if (-not $SkipBuild) {
    $buildPrompt = @(
        "You are opencode build-local."
        "Implement exactly one atomic node from the attached task contract."
        "Only modify files in Allowed Scope."
        "Do not modify Forbidden Scope."
        "Do not commit, merge, push, start another node, or run review as final authority."
        "Stop after the minimal implementation and summarize changed files."
    ) -join [Environment]::NewLine
    Invoke-OpencodeAgent -Agent "build-local" -Prompt $buildPrompt -Files @($resolvedTask) -OutputPath $evalPath
}

$verifyJson = powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts/Invoke-VerifyLocal.ps1") -TaskPath $resolvedTask -BranchName $branch
$verifyJson | Set-Content -Path $verifyPath -Encoding UTF8
$verify = ConvertFrom-JsonObject -Json $verifyJson

$changedFiles = @(Invoke-GitText -GitArgs @("diff", "--name-only"))
$diffStat = @(Invoke-GitText -GitArgs @("diff", "--stat"))
$diffSummary = @(
    "# Diff Summary"
    ""
    "Task: $taskId"
    "Node: $nodeId"
    "Branch: $branch"
    ""
    "## Changed Files"
    $($changedFiles | ForEach-Object { "- $_" })
    ""
    "## Diff Stat"
    '```text'
    $diffStat
    '```'
)
$diffSummary | Set-Content -Path $diffSummaryPath -Encoding UTF8

$reviewPrompt = @(
    "You are review-openrouter."
    "Read only the attached diff summary and verify-local report."
    "Return the required review-openrouter JSON fields."
    "Do not edit files, run commands, or replace verify-local."
    "Keep the output under 80 lines."
) -join [Environment]::NewLine
Invoke-OpencodeAgent -Agent "review-openrouter" -Prompt $reviewPrompt -Files @($diffSummaryPath, $verifyPath) -OutputPath $reviewPath

$verifyStatus = if ($null -ne $verify -and $verify.verify_status) { [string]$verify.verify_status } else { "fail" }
$scopeCheck = if ($null -ne $verify -and $verify.scope_check) { [string]$verify.scope_check } else { "fail" }
$forbiddenScopeCheck = if ($null -ne $verify -and $verify.forbidden_scope_check) { [string]$verify.forbidden_scope_check } else { "fail" }
$needsGoogle = (
    $verifyStatus -eq "fail" -or
    $scopeCheck -eq "fail" -or
    $forbiddenScopeCheck -eq "fail" -or
    $changedFiles.Count -gt 3
)

$googleReviewPath = Join-Path $reviewDir "$taskId.google.md"
if ($needsGoogle) {
    $googlePrompt = @(
        "You are review-google."
        "Read only the attached diff summary, verify-local report, and review-openrouter output."
        "Provide a second opinion for high-risk or failed verification."
        "Do not edit files or run commands."
    ) -join [Environment]::NewLine
    Invoke-OpencodeAgent -Agent "review-google" -Prompt $googlePrompt -Files @($diffSummaryPath, $verifyPath, $reviewPath) -OutputPath $googleReviewPath
}

$commitHash = ""
if (-not $SkipCommit) {
    if ($scopeCheck -eq "fail" -or $forbiddenScopeCheck -eq "fail") {
        throw "Refusing to commit because scope checks failed."
    }
    Invoke-GitText -GitArgs @("add", "--") | Out-Null
    Invoke-GitText -GitArgs @(
        "commit",
        "-m", "task_id: $taskId",
        "-m", "node_id: $nodeId",
        "-m", "summary: complete atomic node through Opencode runner",
        "-m", "files_changed: $($changedFiles -join '; ')",
        "-m", "verify_status: $verifyStatus",
        "-m", "review_status: inspect_detail",
        "-m", "repair_count: 0"
    ) | Out-Null
    $commitHash = (Invoke-GitText -GitArgs @("rev-parse", "--short", "HEAD") | Select-Object -First 1)
}

$summary = [ordered]@{
    task_id = $taskId
    node_id = $nodeId
    branch_name = $branch
    commit_hash = $commitHash
    changed_files = $changedFiles
    scope_check = $scopeCheck
    forbidden_scope_check = $forbiddenScopeCheck
    verify_status = $verifyStatus
    review_openrouter = @{
        risk_level = "unknown"
        summary = "See $reviewPath"
        recommended_decision = "inspect_detail"
    }
    review_google = @{
        used = $needsGoogle
        summary = if ($needsGoogle) { "See $googleReviewPath" } else { "" }
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

$summary | ConvertTo-Json -Depth 8 | Tee-Object -FilePath $memoryPath
