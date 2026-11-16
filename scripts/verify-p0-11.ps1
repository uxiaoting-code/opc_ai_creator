[CmdletBinding()]
param(
    [string]$BaseUrl = 'http://localhost:8080',
    [string]$User = 'demo',
    [string]$Password = 'demo123',
    [string]$AdminUser = 'admin',
    [string]$AdminPassword = 'admin123',
    [string]$RefImageUrl = ''
)

$ErrorActionPreference = 'Stop'

function Assert-ApiSuccess {
    param(
        [Parameter(Mandatory = $true)] $Response,
        [Parameter(Mandatory = $true)] [string] $Step
    )

    if ($null -eq $Response -or $Response.code -ne 200) {
        $message = if ($null -ne $Response) { $Response.message } else { 'empty response' }
        throw "$Step failed: code=$($Response.code), message=$message"
    }
}

function Invoke-Api {
    param(
        [Parameter(Mandatory = $true)] [string] $Method,
        [Parameter(Mandatory = $true)] [string] $Path,
        [hashtable] $Headers = @{},
        [object] $Body = $null
    )

    $params = @{
        Uri = "$BaseUrl$Path"
        Method = $Method
        Headers = $Headers
        TimeoutSec = 15
    }
    if ($null -ne $Body) {
        $params.ContentType = 'application/json'
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
    }
    return Invoke-RestMethod @params
}

function Login-User {
    param(
        [string] $LoginPath,
        [string] $Username,
        [string] $UserPassword,
        [string] $Label
    )

    $response = Invoke-Api -Method Post -Path $LoginPath -Body @{
        username = $Username
        password = $UserPassword
    }
    Assert-ApiSuccess -Response $response -Step "$Label login"
    return $response.data.token
}

function Resolve-RefImageUrl {
    if (-not [string]::IsNullOrWhiteSpace($RefImageUrl)) {
        return $RefImageUrl
    }

    $uploadDir = Join-Path $PSScriptRoot '..\server\data\uploads'
    $image = Get-ChildItem -LiteralPath $uploadDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @('.png', '.jpg', '.jpeg', '.webp') } |
        Select-Object -First 1

    if ($null -eq $image) {
        throw 'VIDEO order requires refImageUrl, but no image was found in uploads.'
    }
    return "/upload/$($image.Name)"
}

Write-Host '=== OPC P0-11 backend verification ===' -ForegroundColor Cyan

$health = Invoke-Api -Method Get -Path '/api/health'
Assert-ApiSuccess -Response $health -Step 'health check'
Write-Host '1. Health check: PASS' -ForegroundColor Green

$userToken = Login-User -LoginPath '/api/auth/login' -Username $User -UserPassword $Password -Label 'user'
$userHeaders = @{ Authorization = "Bearer $userToken" }
Write-Host '2. User login: PASS' -ForegroundColor Green

$adminToken = Login-User -LoginPath '/api/admin/auth/login' -Username $AdminUser -UserPassword $AdminPassword -Label 'admin'
$adminHeaders = @{ Authorization = "Bearer $adminToken" }
Write-Host '3. Admin login: PASS' -ForegroundColor Green

$current = Invoke-Api -Method Get -Path '/api/orders/my/current' -Headers $userHeaders
Assert-ApiSuccess -Response $current -Step 'current context'
$work = $current.data

if ($work.hasActiveWork -and $work.action -eq 'VIEW_REVIEW') {
    throw "Current user already has a submitted work waiting for review. submissionId=$($work.latestSubmission.id)"
}

if (-not $work.hasActiveWork) {
    $available = Invoke-Api -Method Get -Path '/api/orders/available?page=1&pageSize=50' -Headers $userHeaders
    Assert-ApiSuccess -Response $available -Step 'available orders'

    $candidates = @($available.data.list)
    $order = $candidates | Where-Object { $_.mediaType -eq 'IMAGE' } | Select-Object -First 1
    if ($null -eq $order) {
        $order = $candidates | Select-Object -First 1
    }
    if ($null -eq $order) {
        throw 'No available order. Restart the backend and let MarketOrderSeeder refresh expired demo orders.'
    }

    $accepted = Invoke-Api -Method Post -Path "/api/orders/$($order.id)/accept" -Headers $userHeaders
    Assert-ApiSuccess -Response $accepted -Step 'accept order'
    $orderId = $order.id
    $mediaType = $order.mediaType
    Write-Host "4. Accepted order: $orderId ($mediaType)" -ForegroundColor Green
} else {
    $orderId = $work.order.id
    $mediaType = $work.order.mediaType
    Write-Host "4. Reuse active order: $orderId ($mediaType)" -ForegroundColor Green
}

$current = Invoke-Api -Method Get -Path '/api/orders/my/current' -Headers $userHeaders
Assert-ApiSuccess -Response $current -Step 'current context after accept'
if (-not $current.data.canGenerate) {
    throw "Current order cannot generate: action=$($current.data.action), reason=$($current.data.reason)"
}

$prompt = if ($mediaType -eq 'VIDEO') {
    'Coffee machine rotating slowly with steam and warm lifestyle lighting, 15 second vertical video'
} elseif ($mediaType -eq 'AUDIO') {
    'Welcome to the Spring Beauty live room. Today we introduce the new spring collection.'
} else {
    'Premium perfume product image, cream background, natural soft light'
}

if ($mediaType -eq 'IMAGE') {
    $createPath = '/api/creation/text-to-image'
    $createBody = @{
        skillId = $null
        prompt = $prompt
        negativePrompt = $null
        refImageUrl = $null
        orderId = $orderId
    }
} elseif ($mediaType -eq 'VIDEO') {
    $createPath = '/api/creation/image-to-video'
    $createBody = @{
        skillId = $null
        prompt = $prompt
        negativePrompt = $null
        refImageUrl = (Resolve-RefImageUrl)
        orderId = $orderId
    }
} elseif ($mediaType -eq 'AUDIO') {
    $createPath = '/api/creation/text-to-audio'
    $createBody = @{
        skillId = $null
        prompt = $prompt
        voiceCode = 'warm_female'
        language = 'zh-CN'
        speed = 1.0
        format = 'WAV'
        orderId = $orderId
    }
} else {
    throw "Unsupported media type: $mediaType"
}

$created = Invoke-Api -Method Post -Path $createPath -Headers $userHeaders -Body $createBody
Assert-ApiSuccess -Response $created -Step 'create task'
if ($null -eq $created.data -or $null -eq $created.data.id) {
    throw 'Create task succeeded but no task id was returned.'
}
$taskId = $created.data.id
Write-Host "5. Created task: $taskId ($($created.data.type))" -ForegroundColor Green

$deadline = (Get-Date).AddMinutes(3)
do {
    Start-Sleep -Seconds 3
    $task = Invoke-Api -Method Get -Path "/api/tasks/$taskId" -Headers $userHeaders
    Assert-ApiSuccess -Response $task -Step 'poll task'
    Write-Host "   task status=$($task.data.status), progress=$($task.data.progress)%"
    if ((Get-Date) -gt $deadline) {
        throw "Task polling timeout: taskId=$taskId, status=$($task.data.status)"
    }
} while ($task.data.status -in @('QUEUED', 'RUNNING'))

if ($task.data.status -ne 'SUCCESS') {
    throw "Task did not succeed: status=$($task.data.status), error=$($task.data.errorMsg)"
}
Write-Host '6. Task succeeded: PASS' -ForegroundColor Green

$submitBody = @{
    orderId = $orderId
    taskId = $taskId
    title = "P0-11 automated work ($mediaType)"
    note = 'Automated verification: generate-submit-review-wallet'
}
$submission = Invoke-Api -Method Post -Path '/api/submissions' -Headers $userHeaders -Body $submitBody
Assert-ApiSuccess -Response $submission -Step 'submit work'
if ($null -eq $submission.data -or $null -eq $submission.data.id) {
    throw 'Submit work succeeded but no submission id was returned.'
}
$submissionId = $submission.data.id
Write-Host "7. Submitted work: $submissionId" -ForegroundColor Green

$pending = Invoke-Api -Method Get -Path '/api/admin/submissions?status=PENDING&page=1&pageSize=20' -Headers $adminHeaders
Assert-ApiSuccess -Response $pending -Step 'admin pending list'
$pendingIds = @($pending.data.list | ForEach-Object { $_.id })
if (-not ($pendingIds -contains $submissionId)) {
    throw "Submitted item is not in the pending list. submissionId=$submissionId"
}

$reviewBody = @{
    decision = 'APPROVED'
    comment = 'P0-11 automated review passed'
}
$reviewed = Invoke-Api -Method Put -Path "/api/admin/submissions/$submissionId/review" -Headers $adminHeaders -Body $reviewBody
Assert-ApiSuccess -Response $reviewed -Step 'admin review'
if ($reviewed.data.status -ne 'APPROVED') {
    throw "Review result is not APPROVED: $($reviewed.data.status)"
}
Write-Host '8. Admin review: PASS' -ForegroundColor Green

$finalSubmission = Invoke-Api -Method Get -Path "/api/submissions/$submissionId" -Headers $userHeaders
Assert-ApiSuccess -Response $finalSubmission -Step 'user submission status'
if ($finalSubmission.data.status -ne 'APPROVED') {
    throw "User submission status is not APPROVED: $($finalSubmission.data.status)"
}

$wallet = Invoke-Api -Method Get -Path '/api/wallet/summary' -Headers $userHeaders
Assert-ApiSuccess -Response $wallet -Step 'wallet summary'

$profile = Invoke-Api -Method Get -Path '/api/profile/stats' -Headers $userHeaders
Assert-ApiSuccess -Response $profile -Step 'profile stats'

Write-Host '9. User status, wallet and profile: PASS' -ForegroundColor Green
Write-Host '=== P0-11 backend verification completed ===' -ForegroundColor Cyan
$finalSubmission.data | Select-Object id, orderId, mediaType, status, reviewNote | Format-List
$wallet.data | Format-List
$profile.data | ConvertTo-Json -Depth 8