# Azure Boards Work Items 自動作成スクリプト
# AZ-400 Lab 6 - Exercise 1.1

param(
    [Parameter(Mandatory=$false)]
    [string]$Organization,
    
    [Parameter(Mandatory=$false)]
    [string]$Project = "az400-handson3-final"
)

# エラーハンドリングを有効化
$ErrorActionPreference = "Stop"

# Azure DevOps CLI の確認
Write-Host "🔍 Checking Azure DevOps CLI..." -ForegroundColor Cyan
$azdExtension = az extension list --query "[?name=='azure-devops'].version" -o tsv 2>$null
if (-not $azdExtension) {
    Write-Host "Installing Azure DevOps extension..." -ForegroundColor Yellow
    az extension add --name azure-devops
    Write-Host "  ✅ Extension installed" -ForegroundColor Green
} else {
    Write-Host "  ✅ Azure DevOps CLI version: $azdExtension" -ForegroundColor Green
}

# Azure ログイン状態を確認
Write-Host "`n🔐 Checking Azure login status..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "  ⚠️  Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "  ✅ Logged in as: $($account.user.name)" -ForegroundColor Green

# Organization の確認または取得
if (-not $Organization) {
    Write-Host "`n🏢 Detecting Azure DevOps organizations..." -ForegroundColor Cyan
    $orgs = az devops project list --query "value[].name" -o tsv 2>$null
    if (-not $orgs) {
        Write-Host "  ❌ No organizations found or not authenticated to Azure DevOps" -ForegroundColor Red
        Write-Host "`n💡 Please provide the organization name:" -ForegroundColor Yellow
        Write-Host "   Example: .\scripts\create-work-items.ps1 -Organization 'myorg' -Project 'az400-handson3-final'" -ForegroundColor White
        exit 1
    }
    
    # デフォルト設定から Organization を取得
    $defaultOrg = az devops configure --list --query "[?name=='organization'].value" -o tsv 2>$null
    if ($defaultOrg) {
        $Organization = $defaultOrg -replace 'https://dev.azure.com/', ''
        Write-Host "  ✅ Using configured organization: $Organization" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Organization not specified" -ForegroundColor Red
        Write-Host "`n💡 Usage:" -ForegroundColor Yellow
        Write-Host "   .\scripts\create-work-items.ps1 -Organization 'YOUR_ACTUAL_ORG_NAME'" -ForegroundColor White
        exit 1
    }
}

# Azure DevOps に接続
Write-Host "`n🔗 Configuring Azure DevOps..." -ForegroundColor Cyan
Write-Host "  Organization: $Organization" -ForegroundColor White
Write-Host "  Project: $Project" -ForegroundColor White

az devops configure --defaults organization=https://dev.azure.com/$Organization project=$Project

# プロジェクトの存在確認
Write-Host "`n🔍 Verifying project exists..." -ForegroundColor Cyan
$projectExists = az devops project show --project $Project 2>$null | ConvertFrom-Json
if (-not $projectExists) {
    Write-Host "  ❌ Project '$Project' not found in organization '$Organization'" -ForegroundColor Red
    Write-Host "`n💡 Please create the project first:" -ForegroundColor Yellow
    Write-Host "   1. Go to https://dev.azure.com/$Organization" -ForegroundColor White
    Write-Host "   2. Click 'New project'" -ForegroundColor White
    Write-Host "   3. Name: $Project" -ForegroundColor White
    Write-Host "   4. Process: Agile" -ForegroundColor White
    Write-Host "`n   Or use a different project name:" -ForegroundColor Yellow
    Write-Host "   .\scripts\create-work-items.ps1 -Organization '$Organization' -Project 'YOUR_PROJECT_NAME'" -ForegroundColor White
    
    # 利用可能なプロジェクトを表示
    Write-Host "`n📋 Available projects in '$Organization':" -ForegroundColor Cyan
    $projects = az devops project list --query "value[].name" -o tsv 2>$null
    if ($projects) {
        $projects | ForEach-Object { Write-Host "   - $_" -ForegroundColor White }
    } else {
        Write-Host "   (No projects found)" -ForegroundColor Gray
    }
    exit 1
}
Write-Host "  ✅ Project verified: $($projectExists.name)" -ForegroundColor Green

# Epic を作成
Write-Host "`n📦 Creating Epic..." -ForegroundColor Green
try {
    $epicId = az boards work-item create `
      --title "Microservices Application Development" `
      --type Epic `
      --description "フロントエンドとバックエンドのマイクロサービス開発" `
      --fields "System.Tags=AZ-400;Microservices" `
      --query "id" -o tsv
    
    if (-not $epicId) {
        throw "Failed to create Epic"
    }
    Write-Host "  ✅ Epic created: ID = $epicId" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed to create Epic: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Feature を作成
Write-Host "`n📋 Creating Features..." -ForegroundColor Green

try {
    $backendFeatureId = az boards work-item create `
      --title "Backend API Development" `
      --type Feature `
      --description "バックエンドAPIの開発とテスト" `
      --fields "System.Tags=Backend;API" `
      --query "id" -o tsv
    
    if ($backendFeatureId) {
        az boards work-item relation add --id $backendFeatureId --relation-type parent --target-id $epicId 2>$null | Out-Null
        Write-Host "  ✅ Backend Feature created: ID = $backendFeatureId" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Backend Feature creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $frontendFeatureId = az boards work-item create `
      --title "Frontend UI Development" `
      --type Feature `
      --description "フロントエンドUIの開発" `
      --fields "System.Tags=Frontend;React" `
      --query "id" -o tsv
    
    if ($frontendFeatureId) {
        az boards work-item relation add --id $frontendFeatureId --relation-type parent --target-id $epicId 2>$null | Out-Null
        Write-Host "  ✅ Frontend Feature created: ID = $frontendFeatureId" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Frontend Feature creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $pipelineFeatureId = az boards work-item create `
      --title "CI/CD Pipeline Setup" `
      --type Feature `
      --description "CI/CDパイプラインのセットアップ" `
      --fields "System.Tags=Pipeline;DevOps" `
      --query "id" -o tsv
    
    if ($pipelineFeatureId) {
        az boards work-item relation add --id $pipelineFeatureId --relation-type parent --target-id $epicId 2>$null | Out-Null
        Write-Host "  ✅ Pipeline Feature created: ID = $pipelineFeatureId" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Pipeline Feature creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $monitoringFeatureId = az boards work-item create `
      --title "Monitoring and Alerts" `
      --type Feature `
      --description "監視とアラートの設定" `
      --fields "System.Tags=Monitoring;Observability" `
      --query "id" -o tsv
    
    if ($monitoringFeatureId) {
        az boards work-item relation add --id $monitoringFeatureId --relation-type parent --target-id $epicId 2>$null | Out-Null
        Write-Host "  ✅ Monitoring Feature created: ID = $monitoringFeatureId" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Monitoring Feature creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# User Stories を作成
Write-Host "`n📝 Creating User Stories..." -ForegroundColor Green

try {
    $story101Id = az boards work-item create `
      --title "Create User API endpoint" `
      --type "User Story" `
      --description "User APIエンドポイントの作成 - モデル、DbContext、コントローラーを実装" `
      --fields "System.Tags=Backend;API;AB#612" `
      --query "id" -o tsv
    
    if ($story101Id -and $backendFeatureId) {
        az boards work-item relation add --id $story101Id --relation-type parent --target-id $backendFeatureId 2>$null | Out-Null
        Write-Host "  ✅ User Story AB#612 created: ID = $story101Id" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  User Story AB#612 creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $story102Id = az boards work-item create `
      --title "Implement authentication" `
      --type "User Story" `
      --description "認証機能の実装" `
      --fields "System.Tags=Backend;Security;AB#613" `
      --query "id" -o tsv
    
    if ($story102Id -and $backendFeatureId) {
        az boards work-item relation add --id $story102Id --relation-type parent --target-id $backendFeatureId 2>$null | Out-Null
        Write-Host "  ✅ User Story AB#613 created: ID = $story102Id" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  User Story AB#613 creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $story103Id = az boards work-item create `
      --title "Create login page" `
      --type "User Story" `
      --description "ログインページの作成" `
      --fields "System.Tags=Frontend;UI;AB#614" `
      --query "id" -o tsv
    
    if ($story103Id -and $frontendFeatureId) {
        az boards work-item relation add --id $story103Id --relation-type parent --target-id $frontendFeatureId 2>$null | Out-Null
        Write-Host "  ✅ User Story AB#614 created: ID = $story103Id" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  User Story AB#614 creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $story104Id = az boards work-item create `
      --title "Setup build pipeline" `
      --type "User Story" `
      --description "ビルドパイプラインのセットアップ" `
      --fields "System.Tags=Pipeline;CI;AB#615" `
      --query "id" -o tsv
    
    if ($story104Id -and $pipelineFeatureId) {
        az boards work-item relation add --id $story104Id --relation-type parent --target-id $pipelineFeatureId 2>$null | Out-Null
        Write-Host "  ✅ User Story AB#615 created: ID = $story104Id" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  User Story AB#615 creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $story105Id = az boards work-item create `
      --title "Configure Application Insights" `
      --type "User Story" `
      --description "Application Insightsの設定とテレメトリ送信" `
      --fields "System.Tags=Monitoring;AppInsights;AB#616" `
      --query "id" -o tsv
    
    if ($story105Id -and $monitoringFeatureId) {
        az boards work-item relation add --id $story105Id --relation-type parent --target-id $monitoringFeatureId 2>$null | Out-Null
        Write-Host "  ✅ User Story AB#616 created: ID = $story105Id" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  User Story AB#616 creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# サマリー
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Work Items Created Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nEpic:" -ForegroundColor Yellow
Write-Host "  ID $epicId - Microservices Application Development"

if ($backendFeatureId -or $frontendFeatureId -or $pipelineFeatureId -or $monitoringFeatureId) {
    Write-Host "`nFeatures:" -ForegroundColor Yellow
    if ($backendFeatureId) { Write-Host "  ID $backendFeatureId - Backend API Development" }
    if ($frontendFeatureId) { Write-Host "  ID $frontendFeatureId - Frontend UI Development" }
    if ($pipelineFeatureId) { Write-Host "  ID $pipelineFeatureId - CI/CD Pipeline Setup" }
    if ($monitoringFeatureId) { Write-Host "  ID $monitoringFeatureId - Monitoring and Alerts" }
}

if ($story101Id -or $story102Id -or $story103Id -or $story104Id -or $story105Id) {
    Write-Host "`nUser Stories:" -ForegroundColor Yellow
    if ($story101Id) { Write-Host "  ID $story101Id - AB#612: Create User API endpoint" }
    if ($story102Id) { Write-Host "  ID $story102Id - AB#613: Implement authentication" }
    if ($story103Id) { Write-Host "  ID $story103Id - AB#614: Create login page" }
    if ($story104Id) { Write-Host "  ID $story104Id - AB#615: Setup build pipeline" }
    if ($story105Id) { Write-Host "  ID $story105Id - AB#616: Configure Application Insights" }
}

Write-Host "`n📌 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Visit https://dev.azure.com/$Organization/$Project/_workitems" -ForegroundColor White
Write-Host "  2. Verify all work items were created correctly" -ForegroundColor White
Write-Host "  3. Use AB#612～AB#616 in GitHub commits and PRs" -ForegroundColor White
Write-Host "  4. Work items will automatically link to your commits/PRs" -ForegroundColor White
Write-Host ""
