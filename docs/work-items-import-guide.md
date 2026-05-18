# Azure Boards Work Items インポート手順

## 📁 ファイル
- `work-items-import.csv` - Work Items定義ファイル

## 📝 インポート手順

### 方法1: CSV インポート（推奨 - シンプル）

1. **Azure DevOps にアクセス**
   - https://dev.azure.com にアクセス
   - プロジェクト `az400-handson3-final` を開く

2. **CSV ファイルを準備**
   - `work-items-import.csv` ファイルを開く
   - Area Path と Iteration Path を実際のプロジェクト名に合わせて編集（必要に応じて）

3. **Work Items をインポート**
   - Azure DevOps → **Boards** → **Work items**
   - 右上の **...** (More actions) → **Import Work Items**
   - `work-items-import.csv` を選択
   - **Import** をクリック

4. **階層構造を設定（手動）**
   
   インポート後、以下の親子関係を設定します：
   
   **Epic: Microservices Application Development** の子として：
   - Feature: Backend API Development
   - Feature: Frontend UI Development
   - Feature: CI/CD Pipeline Setup
   - Feature: Monitoring and Alerts

   **Feature: Backend API Development** の子として：
   - User Story: Create User API endpoint (AB#612)
   - User Story: Implement authentication (AB#613)

   **Feature: Frontend UI Development** の子として:
   - User Story: Create login page (AB#614)

   **Feature: CI/CD Pipeline Setup** の子として:
   - User Story: Setup build pipeline (AB#615)

   **Feature: Monitoring and Alerts** の子として:
   - User Story: Configure Application Insights (AB#616)

   **リンクの追加方法**:
   - 子 Work Item を開く
   - **Add link** → **Existing item**
   - Link type: **Parent** を選択
   - 親 Work Item の ID を入力
   - **OK** をクリック

### 方法2: Azure DevOps CLI（自動化）

```powershell
# Azure DevOps CLI 拡張機能をインストール
az extension add --name azure-devops

# Azure DevOps にログイン
az login
az devops configure --defaults organization=https://dev.azure.com/YOUR_ORG project=az400-handson3-final

# Epic を作成
$epicId = az boards work-item create `
  --title "Microservices Application Development" `
  --type Epic `
  --description "フロントエンドとバックエンドのマイクロサービス開発" `
  --query "id" -o tsv

# Feature を作成（Epic の子として）
$backendFeatureId = az boards work-item create `
  --title "Backend API Development" `
  --type Feature `
  --description "バックエンドAPIの開発とテスト" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $backendFeatureId `
  --relation-type parent `
  --target-id $epicId

$frontendFeatureId = az boards work-item create `
  --title "Frontend UI Development" `
  --type Feature `
  --description "フロントエンドUIの開発" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $frontendFeatureId `
  --relation-type parent `
  --target-id $epicId

$pipelineFeatureId = az boards work-item create `
  --title "CI/CD Pipeline Setup" `
  --type Feature `
  --description "CI/CDパイプラインのセットアップ" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $pipelineFeatureId `
  --relation-type parent `
  --target-id $epicId

$monitoringFeatureId = az boards work-item create `
  --title "Monitoring and Alerts" `
  --type Feature `
  --description "監視とアラートの設定" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $monitoringFeatureId `
  --relation-type parent `
  --target-id $epicId

# User Stories を作成（各 Feature の子として）
$story101Id = az boards work-item create `
  --title "Create User API endpoint" `
  --type "User Story" `
  --description "User APIエンドポイントの作成 - モデル、DbContext、コントローラーを実装" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $story101Id `
  --relation-type parent `
  --target-id $backendFeatureId

$story102Id = az boards work-item create `
  --title "Implement authentication" `
  --type "User Story" `
  --description "認証機能の実装" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $story102Id `
  --relation-type parent `
  --target-id $backendFeatureId

$story103Id = az boards work-item create `
  --title "Create login page" `
  --type "User Story" `
  --description "ログインページの作成" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $story103Id `
  --relation-type parent `
  --target-id $frontendFeatureId

$story104Id = az boards work-item create `
  --title "Setup build pipeline" `
  --type "User Story" `
  --description "ビルドパイプラインのセットアップ" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $story104Id `
  --relation-type parent `
  --target-id $pipelineFeatureId

$story105Id = az boards work-item create `
  --title "Configure Application Insights" `
  --type "User Story" `
  --description "Application Insightsの設定とテレメトリ送信" `
  --query "id" -o tsv

az boards work-item relation add `
  --id $story105Id `
  --relation-type parent `
  --target-id $monitoringFeatureId

Write-Host "✅ Work Items created successfully!"
Write-Host "Epic ID: $epicId"
Write-Host "Story IDs: 101=$story101Id, 102=$story102Id, 103=$story103Id, 104=$story104Id, 105=$story105Id"
```

### 方法3: 手動作成（学習用）

演習 1.1 の手順に従って、Azure Boards UI から手動で作成します。

## ✅ 確認事項

インポート後、以下を確認してください：

- [ ] Epic が 1件作成されている
- [ ] Feature が 4件作成されている
- [ ] User Story が 5件作成されている
- [ ] 階層構造が正しく設定されている（Epic > Feature > User Story）
- [ ] User Story に AB#612～AB#616 のタグが付いている
- [ ] すべての Work Item が State: New になっている

## 📌 重要なポイント

**AB# 番号について**:
- AB#612～AB#616 は GitHub のコミットメッセージや PR タイトルで使用します
- Azure Boards の Work Item ID とは異なります
- 実際の Work Item ID はインポート時に自動採番されます

**Work Item ID の対応**:
```
AB#612 → 実際のID（#612） → タイトル: "Create User API endpoint"
AB#613 → 実際のID（#613） → タイトル: "Implement authentication"
...
```

GitHub で `AB#612` を使用すると、タイトルに "Create User API endpoint" を含む Work Item に自動的にリンクされます。

## 🔗 関連ドキュメント

- [Azure DevOps Work Items インポート](https://learn.microsoft.com/azure/devops/boards/queries/import-work-items-from-csv)
- [Azure DevOps CLI リファレンス](https://learn.microsoft.com/cli/azure/boards/work-item)
